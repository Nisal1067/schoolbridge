import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:schoolbridge/features/homework_announcements/models/attachment.dart';
import 'package:schoolbridge/features/homework_announcements/models/homework.dart';
import 'package:schoolbridge/features/homework_announcements/models/submission.dart';

void main() {
  group('Attachment', () {
    test('round-trips through a map', () {
      const file = Attachment(
        name: 'worksheet.pdf',
        url: 'https://example.com/w.pdf',
        path: 'homework_attachments/s1/t1/h1/1_worksheet.pdf',
        contentType: kPdfType,
        size: 2048,
      );
      final copy = Attachment.fromMap(file.toMap());
      expect(copy.name, file.name);
      expect(copy.url, file.url);
      expect(copy.path, file.path);
      expect(copy.size, 2048);
      expect(copy.isPdf, isTrue);
      expect(copy.isImage, isFalse);
    });

    test('new files carry no link, because the bucket is private', () {
      const file = Attachment(
        name: 'a.png',
        path: 'homework_submissions/s/h/u/1_a.png',
        contentType: kPngType,
        size: 1,
      );
      expect(file.url, isEmpty);
      expect(file.toMap().containsKey('url'), isFalse);
      expect(Attachment.fromMap(file.toMap()).url, isEmpty);
    });

    test('listFrom copes with missing or bad data', () {
      expect(Attachment.listFrom(null), isEmpty);
      expect(Attachment.listFrom('nope'), isEmpty);
      final list = Attachment.listFrom([
        {'name': 'a.png', 'contentType': kPngType, 'size': 10},
        'junk',
      ]);
      expect(list, hasLength(1));
      expect(list.first.isImage, isTrue);
    });

    test('models without attachments default to an empty list', () {
      final homework = Homework(
        schoolId: 's',
        classId: 'c',
        className: 'Grade 10A',
        teacherId: 't',
        subject: 'Maths',
        title: 'T',
        description: '',
        dueDate: DateTime(2026, 10, 10),
        totalStudents: 1,
        submittedCount: 0,
        createdAt: DateTime(2026, 10, 1),
      );
      const submission = Submission(
        studentId: 'st',
        studentName: 'Kasun',
        status: 'submitted',
        note: '',
        feedback: '',
      );
      expect(homework.attachments, isEmpty);
      expect(submission.attachments, isEmpty);
    });
  });

  group('sniffContentType', () {
    test('recognises PDF, JPEG and PNG by their first bytes', () {
      expect(
        sniffContentType(Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D])),
        kPdfType,
      );
      expect(
        sniffContentType(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0])),
        kJpegType,
      );
      expect(
        sniffContentType(
          Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
        ),
        kPngType,
      );
    });

    test('rejects anything else', () {
      expect(sniffContentType(Uint8List.fromList([1, 2, 3, 4, 5])), isNull);
      expect(sniffContentType(Uint8List(0)), isNull);
    });
  });

  group('names and sizes', () {
    test('nameWithExtension adds only what is missing', () {
      expect(nameWithExtension('scan', kJpegType), 'scan.jpg');
      expect(nameWithExtension('scan.JPEG', kJpegType), 'scan.JPEG');
      expect(nameWithExtension('notes', kPdfType), 'notes.pdf');
      expect(nameWithExtension('photo.jpg', kPngType), 'photo.jpg.png');
    });

    test('safeStorageName removes unsafe characters', () {
      expect(safeStorageName('my homework (1).pdf'), 'my_homework__1_.pdf');
      expect(safeStorageName('a' * 200).length, 80);
    });

    test('formatFileSize', () {
      expect(formatFileSize(500), '500 B');
      expect(formatFileSize(2048), '2 KB');
      expect(formatFileSize(5 * 1024 * 1024), '5.0 MB');
    });
  });
}
