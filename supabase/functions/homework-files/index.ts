// SchoolBridge: secure gateway for homework files (PDF / JPG / PNG).
//
// The Flutter app never talks to Supabase Storage directly. The bucket is
// private and has NO storage policies, so the only way to upload, view or
// delete a file is through this function, which:
//
//   1. verifies the caller's Firebase ID token (signature, issuer, audience,
//      expiry) against Google's public keys,
//   2. asks Cloud Firestore about the caller, using the caller's OWN token, so
//      firestore.rules decide what they may see (no Firebase secret needed),
//   3. only then uses the Supabase service-role key (which lives only here, as
//      an automatic server-side secret) to hand back a short-lived signed URL.
//
// Actions (JSON body, POST):
//   upload  {folder, fileName, contentType, size}  -> {path, signedUrl, headers}
//   sign    {paths: [...]}                         -> {urls: {path: url}, expiresIn}
//   delete  {paths: [...]}                         -> {deleted: [...], denied: [...]}
//
// Deploy with --no-verify-jwt: callers present a Firebase token, not a
// Supabase one, and this function verifies that token itself.

import { createClient } from "npm:@supabase/supabase-js@2";
import { createRemoteJWKSet, jwtVerify } from "npm:jose@5";

// ----------------------------------------------------------------- settings

const PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID") ?? "";
const BUCKET = Deno.env.get("STORAGE_BUCKET") ?? "homework-files";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
// The project's PUBLIC key (never the service-role key). Only used to let the
// signed upload request through Supabase's gateway. Supabase provides
// SUPABASE_ANON_KEY automatically; PUBLIC_API_KEY is an optional fallback.
const PUBLIC_KEY = Deno.env.get("SUPABASE_ANON_KEY") ??
    Deno.env.get("PUBLIC_API_KEY") ?? "";

const MAX_BYTES = 10 * 1024 * 1024; // keep in sync with the app and the bucket
const ALLOWED_TYPES = ["application/pdf", "image/jpeg", "image/png"];
const SIGNED_URL_SECONDS = 900; // 15 minutes
const MAX_FILES_PER_FOLDER = 20; // 5 saved + room for leftovers
const MAX_PATHS_PER_CALL = 20;

const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
});

// Google's public keys for Firebase ID tokens (cached by jose).
const FIREBASE_KEYS = createRemoteJWKSet(
    new URL(
        "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
    ),
);

// --------------------------------------------------------------- http helpers

const CORS = {
    "Access-Control-Allow-Origin": "*", // auth is a bearer token, not cookies
    "Access-Control-Allow-Headers":
        "authorization, content-type, x-client-info, apikey",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function reply(status: number, body: unknown): Response {
    return new Response(JSON.stringify(body), {
        status,
        headers: { ...CORS, "Content-Type": "application/json" },
    });
}

class HttpError extends Error {
    status: number;
    constructor(status: number, message: string) {
        super(message);
        this.status = status;
    }
}

// ------------------------------------------------------- 1. who is calling?

async function authenticate(
    req: Request,
): Promise<{ uid: string; token: string }> {
    const header = req.headers.get("authorization") ?? "";
    const token = header.startsWith("Bearer ") ? header.slice(7).trim() : "";
    if (!token) throw new HttpError(401, "Please sign in again.");
    try {
        const { payload } = await jwtVerify(token, FIREBASE_KEYS, {
            issuer: `https://securetoken.google.com/${PROJECT_ID}`,
            audience: PROJECT_ID,
            algorithms: ["RS256"],
        });
        const uid = payload.sub;
        if (typeof uid !== "string" || uid.length === 0 || uid.length > 128) {
            throw new Error("token has no subject");
        }
        return { uid, token };
    } catch (_) {
        throw new HttpError(401, "Your session has expired. Please sign in again.");
    }
}

// -------------------------------------- 2. what does Firestore say about them?
//
// Documents are read with the CALLER'S token, so firestore.rules apply exactly
// as they do in the app. 403 = the rules refuse, 404 = the document is missing.

// deno-lint-ignore no-explicit-any
type Doc = { fields?: Record<string, any> };
type Fetched =
    | { status: "ok"; doc: Doc }
    | { status: "missing" }
    | { status: "denied" };

class Firestore {
    private token: string;
    private cache = new Map<string, Promise<Fetched>>();

    constructor(token: string) {
        this.token = token;
    }

    get(path: string): Promise<Fetched> {
        let hit = this.cache.get(path);
        if (!hit) {
            hit = this.fetchDoc(path);
            this.cache.set(path, hit);
        }
        return hit;
    }

    private async fetchDoc(path: string): Promise<Fetched> {
        const encoded = path.split("/").map(encodeURIComponent).join("/");
        const url =
            `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${encoded}`;
        const res = await fetch(url, {
            headers: { Authorization: `Bearer ${this.token}` },
        });
        if (res.status === 200) return { status: "ok", doc: await res.json() };
        await res.body?.cancel();
        if (res.status === 404) return { status: "missing" };
        if (res.status === 401 || res.status === 403) return { status: "denied" };
        throw new HttpError(502, "The school database is not reachable right now.");
    }
}

const text = (d: Doc, key: string): string | undefined =>
    d.fields?.[key]?.stringValue;

const flag = (d: Doc, key: string): boolean | undefined =>
    d.fields?.[key]?.booleanValue;

/** The `path` of every entry in a document's `attachments` list. */
function attachmentPaths(d: Doc): string[] {
    const entries = d.fields?.attachments?.arrayValue?.values ?? [];
    // deno-lint-ignore no-explicit-any
    return entries.map((e: any) => e?.mapValue?.fields?.path?.stringValue)
        .filter((p: unknown): p is string => typeof p === "string");
}

interface Profile {
    role: string;
    schoolId: string;
}

interface Ctx {
    uid: string;
    fs: Firestore;
    profile: () => Promise<Profile>;
}

function makeContext(uid: string, token: string): Ctx {
    const fs = new Firestore(token);
    let cached: Promise<Profile> | null = null;
    const load = async (): Promise<Profile> => {
        const res = await fs.get(`users/${uid}`);
        if (res.status !== "ok") {
            throw new HttpError(403, "Your account could not be verified.");
        }
        if (flag(res.doc, "active") !== true) {
            throw new HttpError(403, "Your account is not active.");
        }
        return {
            role: text(res.doc, "role") ?? "",
            schoolId: text(res.doc, "schoolId") ?? "",
        };
    };
    return { uid, fs, profile: () => (cached ??= load()) };
}

// ------------------------------------------------- 3. what may they do here?

// One path segment: letters, digits, _ . - (but never "." or "..").
const ID = "(?!\\.{1,2}(?:/|$))[A-Za-z0-9_.-]{1,128}";
const FILE = "[A-Za-z0-9][A-Za-z0-9._-]{0,199}";
const HOMEWORK_FOLDER = new RegExp(
    `^homework_attachments/(${ID})/(${ID})/(${ID})$`,
);
const SUBMISSION_FOLDER = new RegExp(
    `^homework_submissions/(${ID})/(${ID})/(${ID})$`,
);
const FILE_NAME = new RegExp(`^${FILE}$`);

type Target =
    | {
        kind: "homework";
        schoolId: string;
        teacherId: string;
        homeworkId: string;
        folder: string;
    }
    | {
        kind: "submission";
        schoolId: string;
        homeworkId: string;
        studentId: string;
        folder: string;
    };

/** homework_attachments/{school}/{teacher}/{homework}
 *  homework_submissions/{school}/{homework}/{student} */
function parseFolder(folder: unknown): Target {
    if (typeof folder === "string") {
        let m = HOMEWORK_FOLDER.exec(folder);
        if (m) {
            return {
                kind: "homework",
                schoolId: m[1],
                teacherId: m[2],
                homeworkId: m[3],
                folder,
            };
        }
        m = SUBMISSION_FOLDER.exec(folder);
        if (m) {
            return {
                kind: "submission",
                schoolId: m[1],
                homeworkId: m[2],
                studentId: m[3],
                folder,
            };
        }
    }
    throw new HttpError(400, "That file location is not valid.");
}

function parsePath(path: unknown): Target {
    if (typeof path !== "string" || path.length > 600) {
        throw new HttpError(400, "That file location is not valid.");
    }
    const cut = path.lastIndexOf("/");
    if (cut <= 0 || !FILE_NAME.test(path.slice(cut + 1))) {
        throw new HttpError(400, "That file location is not valid.");
    }
    return parseFolder(path.slice(0, cut));
}

async function submissionLocked(
    ctx: Ctx,
    homeworkId: string,
    studentId: string,
): Promise<boolean> {
    const sub = await ctx.fs.get(
        `homework/${homeworkId}/submissions/${studentId}`,
    );
    return sub.status === "ok" && text(sub.doc, "status") === "reviewed";
}

/** Teachers: only into their own folder. Students: only into their own
 *  folder of a homework they can see, and not once it has been reviewed.
 *  (A homework that does not exist yet cannot be told apart from one the
 *  teacher may not read, and does not need to be: the teacher's own uid is
 *  part of the path, so nobody else's files can be touched.) */
async function mayUpload(ctx: Ctx, t: Target): Promise<boolean> {
    const me = await ctx.profile();
    if (me.schoolId !== t.schoolId) return false;
    if (t.kind === "homework") {
        return me.role === "teacher" && t.teacherId === ctx.uid;
    }
    if (me.role !== "student" || t.studentId !== ctx.uid) return false;
    // firestore.rules only let a student read homework of their own class.
    const homework = await ctx.fs.get(`homework/${t.homeworkId}`);
    if (homework.status !== "ok") return false;
    if (text(homework.doc, "schoolId") !== t.schoolId) return false;
    return !(await submissionLocked(ctx, t.homeworkId, ctx.uid));
}

/** A file may be viewed when it is listed in the Firestore document that
 *  belongs to ITS OWN folder, and the caller may read that document. The
 *  document is chosen from the path, never from what a document claims, so a
 *  student cannot list somebody else's file in their own submission. */
async function mayView(ctx: Ctx, t: Target, path: string): Promise<boolean> {
    const me = await ctx.profile();
    if (me.schoolId !== t.schoolId) return false;
    if (t.kind === "homework") {
        const hw = await ctx.fs.get(`homework/${t.homeworkId}`);
        return hw.status === "ok" &&
            text(hw.doc, "teacherId") === t.teacherId &&
            text(hw.doc, "schoolId") === t.schoolId &&
            attachmentPaths(hw.doc).includes(path);
    }
    const sub = await ctx.fs.get(
        `homework/${t.homeworkId}/submissions/${t.studentId}`,
    );
    return sub.status === "ok" && attachmentPaths(sub.doc).includes(path);
}

/** Teachers: their own homework files, and the student files of a homework
 *  they own (so deleting a homework clears everything). Students: their own
 *  files, until the submission has been reviewed. */
async function mayDelete(ctx: Ctx, t: Target): Promise<boolean> {
    const me = await ctx.profile();
    if (me.schoolId !== t.schoolId) return false;
    if (t.kind === "homework") {
        return me.role === "teacher" && t.teacherId === ctx.uid;
    }
    if (me.role === "student") {
        return t.studentId === ctx.uid &&
            !(await submissionLocked(ctx, t.homeworkId, t.studentId));
    }
    if (me.role === "teacher") {
        const hw = await ctx.fs.get(`homework/${t.homeworkId}`);
        return hw.status === "ok" &&
            text(hw.doc, "teacherId") === ctx.uid &&
            text(hw.doc, "schoolId") === t.schoolId;
    }
    return false;
}

// ------------------------------------------------------------------ actions

function cleanName(raw: unknown): string {
    const name = typeof raw === "string" ? raw : "file";
    const safe = name.replace(/[^A-Za-z0-9._-]/g, "_").replace(/^[^A-Za-z0-9]+/, "");
    return (safe.length > 80 ? safe.slice(-80) : safe) || "file";
}

function pathList(raw: unknown): string[] {
    if (!Array.isArray(raw) || raw.length === 0 || raw.length > MAX_PATHS_PER_CALL) {
        throw new HttpError(400, "Send between 1 and 20 file paths.");
    }
    return raw.map((p) => {
        parsePath(p); // throws if malformed
        return p as string;
    });
}

// deno-lint-ignore no-explicit-any
async function upload(ctx: Ctx, body: Record<string, any>): Promise<Response> {
    const target = parseFolder(body.folder);
    const type = body.contentType;
    const size = body.size;
    if (typeof type !== "string" || !ALLOWED_TYPES.includes(type)) {
        throw new HttpError(400, "Only PDF, JPG and PNG files can be uploaded.");
    }
    if (typeof size !== "number" || !Number.isInteger(size) || size < 1) {
        throw new HttpError(400, "That file is empty.");
    }
    if (size > MAX_BYTES) throw new HttpError(413, "Files can be at most 10 MB.");

    if (!(await mayUpload(ctx, target))) {
        throw new HttpError(403, "You are not allowed to upload files here.");
    }

    const existing = await admin.storage.from(BUCKET).list(target.folder, {
        limit: MAX_FILES_PER_FOLDER + 1,
    });
    if (existing.error) throw new Error(existing.error.message);
    if (existing.data.length > MAX_FILES_PER_FOLDER) {
        throw new HttpError(429, "There are too many files here already.");
    }

    const path = `${target.folder}/${Date.now()}_${crypto.randomUUID().slice(0, 8)
        }_${cleanName(body.fileName)}`;
    const signed = await admin.storage.from(BUCKET).createSignedUploadUrl(path);
    if (signed.error || !signed.data) {
        throw new Error(signed.error?.message ?? "no upload url");
    }

    // The public key is harmless: this bucket has no storage policies, so it
    // grants nothing. It only lets the request through Supabase's gateway.
    // Legacy "anon" keys are JWTs (start with "eyJ") and are also sent as bearer.
    const headers: Record<string, string> = {};
    if (PUBLIC_KEY) {
        headers.apikey = PUBLIC_KEY;
        if (PUBLIC_KEY.startsWith("eyJ")) {
            headers.Authorization = `Bearer ${PUBLIC_KEY}`;
        }
    }
    return reply(200, { path, signedUrl: signed.data.signedUrl, headers });
}

// deno-lint-ignore no-explicit-any
async function sign(ctx: Ctx, body: Record<string, any>): Promise<Response> {
    const paths = pathList(body.paths);
    const checks = await Promise.all(
        paths.map(async (p) => (await mayView(ctx, parsePath(p), p)) ? p : null),
    );
    const allowed = checks.filter((p): p is string => p !== null);
    const urls: Record<string, string> = {};
    if (allowed.length > 0) {
        const signed = await admin.storage.from(BUCKET).createSignedUrls(
            allowed,
            SIGNED_URL_SECONDS,
        );
        if (signed.error) throw new Error(signed.error.message);
        for (const item of signed.data) {
            if (item.path && item.signedUrl && !item.error) {
                urls[item.path] = item.signedUrl;
            }
        }
    }
    return reply(200, { urls, expiresIn: SIGNED_URL_SECONDS });
}

// deno-lint-ignore no-explicit-any
async function remove(ctx: Ctx, body: Record<string, any>): Promise<Response> {
    const paths = pathList(body.paths);
    const checks = await Promise.all(
        paths.map(async (p) => (await mayDelete(ctx, parsePath(p))) ? p : null),
    );
    const allowed = checks.filter((p): p is string => p !== null);
    const denied = paths.filter((p) => !allowed.includes(p));
    if (allowed.length > 0) {
        const result = await admin.storage.from(BUCKET).remove(allowed);
        if (result.error) throw new Error(result.error.message);
    }
    return reply(200, { deleted: allowed, denied });
}

// ------------------------------------------------------------------- server

Deno.serve(async (req: Request) => {
    if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
    if (req.method !== "POST") return reply(405, { error: "Use POST." });

    try {
        if (!PROJECT_ID || !SUPABASE_URL || !SERVICE_ROLE_KEY) {
            throw new HttpError(500, "File storage is not configured on the server.");
        }
        const { uid, token } = await authenticate(req);
        const body = await req.json().catch(() => null);
        if (!body || typeof body !== "object") {
            throw new HttpError(400, "The request was not understood.");
        }
        const ctx = makeContext(uid, token);
        switch (body.action) {
            case "upload":
                return await upload(ctx, body);
            case "sign":
                return await sign(ctx, body);
            case "delete":
                return await remove(ctx, body);
            default:
                throw new HttpError(400, "Unknown action.");
        }
    } catch (error) {
        if (error instanceof HttpError) {
            return reply(error.status, { error: error.message });
        }
        console.error(error);
        return reply(500, { error: "Something went wrong. Please try again." });
    }
});