import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../attendance/models/attendance_record.dart';
import 'models/mark_record.dart';
import 'services/marks_service.dart';
import 'widgets/mark_badge_field.dart';
import 'widgets/marks_summary_sheet.dart';

/// Teacher "Marks" tab, shown inside the teacher dashboard (it uses the
/// dashboard's own top bar and bottom navigation).
///
/// Pick a class and subject, type each student's mark out of 100, then save.
/// Marks are stored per class + subject + term; the term follows today's date,
/// the same way attendance does.
class MarksScreen extends StatefulWidget {
  const MarksScreen({super.key});

  @override
  State<MarksScreen> createState() => _MarksScreenState();
}

class _MarksScreenState extends State<MarksScreen> {
  static const _blue = Color(0xFF2563EB);
  static const _ink = Color(0xFF17212F);
  static const _grey = Color(0xFF6B7280);

  final _service = MarksService();
  final _term = AttendanceRecord.termForDate(DateTime.now());

  bool _loading = true;
  bool _loadingRoster = false;
  bool _saving = false;
  String? _error;

  Map<String, dynamic> _profile = {};
  List<Map<String, dynamic>> _classes = [];
  List<String> _subjects = [];
  int _classIndex = 0;
  String _subject = '';

  List<Map<String, dynamic>> _students = [];
  Map<String, MarkRecord> _saved = {};
  final _controllers = <String, TextEditingController>{};
  final _focusNodes = <String, FocusNode>{};

  // Ignores a slow roster response when the teacher has already moved on.
  int _loadToken = 0;

  Map<String, dynamic>? get _classroom =>
      _classes.isEmpty ? null : _classes[_classIndex];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _disposeFields();
    super.dispose();
  }

  void _disposeFields() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    _controllers.clear();
    _focusNodes.clear();
  }

  String _message(Object error) {
    if (error is StateError) return error.message;
    if (error is FirebaseException && error.code == 'permission-denied') {
      return 'You do not have permission to do that.';
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _service.profile();
      if (profile['role'] != 'teacher') {
        throw StateError('Teacher access required.');
      }
      final classes = await _service.classes();
      if (!mounted) return;
      final subjects = MarksService.subjectsFor(profile);
      setState(() {
        _profile = profile;
        _classes = classes;
        _subjects = subjects;
        _classIndex = 0;
        _subject = subjects.first;
      });
      if (classes.isNotEmpty) await _loadRoster();
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _message(e);
        _loading = false;
      });
    }
  }

  Future<void> _loadRoster() async {
    final classroom = _classroom;
    if (classroom == null) return;
    final token = ++_loadToken;
    setState(() => _loadingRoster = true);
    try {
      final results = await Future.wait<Object>([
        _service.students(classroom),
        _service.loadMarks(
          classroom: classroom,
          subject: _subject,
          term: _term,
        ),
      ]);
      if (!mounted || token != _loadToken) return;
      final students = results[0] as List<Map<String, dynamic>>;
      final saved = results[1] as Map<String, MarkRecord>;
      _disposeFields();
      for (final student in students) {
        final id = student['id'] as String;
        _controllers[id] = TextEditingController(
          text: saved[id] == null ? '' : '${saved[id]!.mark}',
        );
        _focusNodes[id] = FocusNode();
      }
      setState(() {
        _students = students;
        _saved = saved;
        _loadingRoster = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || token != _loadToken) return;
      setState(() {
        _loadingRoster = false;
        _error = _message(e);
      });
    }
  }

  int? _entered(String studentId) =>
      int.tryParse(_controllers[studentId]?.text.trim() ?? '');

  bool get _isDirty {
    for (final student in _students) {
      final id = student['id'] as String;
      if (_entered(id) != _saved[id]?.mark) return true;
    }
    return false;
  }

  int get _enteredCount => _students.where((student) {
    return _entered(student['id'] as String) != null;
  }).length;

  double get _completion =>
      _students.isEmpty ? 0 : _enteredCount / _students.length;

  double get _average {
    final values = [
      for (final student in _students) ?_entered(student['id'] as String),
    ];
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard unsaved marks?'),
        content: const Text('Marks you typed but did not save will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard == true;
  }

  Future<void> _changeClass(int? index) async {
    if (index == null || index == _classIndex || _saving) return;
    if (!await _confirmDiscard() || !mounted) return;
    setState(() => _classIndex = index);
    await _loadRoster();
  }

  Future<void> _changeSubject(String? subject) async {
    if (subject == null || subject == _subject || _saving) return;
    if (!await _confirmDiscard() || !mounted) return;
    setState(() => _subject = subject);
    await _loadRoster();
  }

  Future<void> _save() async {
    final classroom = _classroom;
    if (classroom == null || _saving) return;
    FocusScope.of(context).unfocus();

    final teacherId = _profile['uid'] as String;
    final upserts = <MarkRecord>[];
    final deletes = <MarkRecord>[];
    for (final student in _students) {
      final id = student['id'] as String;
      final entered = _entered(id);
      final before = _saved[id];
      if (entered == before?.mark) continue;
      if (entered == null) {
        if (before != null) deletes.add(before);
        continue;
      }
      upserts.add(
        MarkRecord(
          studentId: id,
          studentName: student['name'] as String,
          classId: classroom['id'] as String,
          schoolId: classroom['schoolId'] as String,
          teacherId: teacherId,
          subject: _subject,
          term: _term,
          mark: entered,
        ),
      );
    }
    if (upserts.isEmpty && deletes.isEmpty) return;

    setState(() => _saving = true);
    try {
      await _service.saveMarks(upserts: upserts, deletes: deletes);
      if (!mounted) return;
      final saved = Map<String, MarkRecord>.of(_saved);
      for (final r in upserts) {
        saved[r.studentId] = r;
      }
      for (final r in deletes) {
        saved.remove(r.studentId);
      }
      setState(() {
        _saved = saved;
        _saving = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Marks saved.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_message(e))));
    }
  }

  void _showSummary() {
    FocusScope.of(context).unfocus();
    final marks = <int>[
      for (final student in _students) ?_entered(student['id'] as String),
    ];
    showMarksSummarySheet(
      context,
      className: '${_classroom?['name'] ?? ''}',
      subject: _subject,
      summary: MarkSummary.of(marks, totalStudents: _students.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null && _classes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _bootstrap, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      // Extra bottom space keeps the floating chat button off the actions.
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHero(),
          const SizedBox(height: 16),
          if (_classes.isEmpty)
            const _Notice('No classes are assigned to you yet.')
          else ...[
            _buildDropdowns(),
            const SizedBox(height: 14),
            if (_error != null) ...[
              _Notice(_error!),
              const SizedBox(height: 12),
            ],
            _buildProgressCard(),
            const SizedBox(height: 14),
            _buildTable(),
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x241E40AF),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Marks workspace',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Record and review student performance',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Term $_term',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.auto_graph_rounded,
            color: Color(0x66FFFFFF),
            size: 58,
          ),
        ],
      ),
    );
  }

  // Class and subject pickers: 41 high, 10 apart.
  Widget _buildDropdowns() {
    final busy = _saving || _loadingRoster;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _LabeledDropdown(
              label: 'CLASS',
              child: _DropdownBox<int>(
                value: _classIndex,
                enabled: !busy,
                items: [
                  for (var i = 0; i < _classes.length; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(
                        '${_classes[i]['name'] ?? 'Class'}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: _changeClass,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _LabeledDropdown(
              label: 'SUBJECT',
              child: _DropdownBox<String>(
                value: _subject,
                enabled: !busy,
                items: [
                  for (final subject in _subjects)
                    DropdownMenuItem(
                      value: subject,
                      child: Text(subject, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: _changeSubject,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: _blue, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Entry progress',
                  style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '$_enteredCount / ${_students.length}',
                style: const TextStyle(
                  color: _blue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: _loadingRoster ? null : _completion,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(_blue),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isDirty ? 'Unsaved changes' : 'All changes saved',
                style: TextStyle(
                  color: _isDirty
                      ? const Color(0xFFB45309)
                      : const Color(0xFF047857),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _enteredCount == 0
                    ? 'Average —'
                    : 'Average ${_average.toStringAsFixed(1)}',
                style: const TextStyle(
                  color: _grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Student roster table with compact, touch-friendly rows.
  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 42,
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Row(
              children: [
                SizedBox(width: 30, child: _HeaderText('#')),
                Expanded(child: _HeaderText('Student')),
                SizedBox(
                  width: 80,
                  child: _HeaderText('Mark /100', alignEnd: true),
                ),
              ],
            ),
          ),
          if (_loadingRoster)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_students.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No students in this class.',
                  style: TextStyle(color: _grey),
                ),
              ),
            )
          else
            for (var i = 0; i < _students.length; i++) _buildRow(i),
        ],
      ),
    );
  }

  Widget _buildRow(int index) {
    final student = _students[index];
    final id = student['id'] as String;
    return InkWell(
      onTap: _saving ? null : () => _focusNodes[id]?.requestFocus(),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: _grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Text(
                '${student['name']}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            MarkBadgeField(
              controller: _controllers[id]!,
              focusNode: _focusNodes[id]!,
              enabled: !_saving,
              isLast: index == _students.length - 1,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  // Save action + summary shortcut.
  Widget _buildActions() {
    final canSave =
        !_saving && !_loadingRoster && _students.isNotEmpty && _isDirty;
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child: FilledButton(
              onPressed: canSave ? _save : null,
              style: FilledButton.styleFrom(
                backgroundColor: _blue,
                disabledBackgroundColor: _blue.withValues(alpha: 0.4),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Marks',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 48,
          height: 48,
          child: OutlinedButton(
            onPressed: _loadingRoster || _students.isEmpty
                ? null
                : _showSummary,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: Colors.white,
              foregroundColor: _blue,
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Icon(Icons.bar_chart_rounded, size: 22),
          ),
        ),
      ],
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String text;
  final bool alignEnd;

  const _HeaderText(this.text, {this.alignEnd = false});

  @override
  Widget build(BuildContext context) => Align(
    alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF6B7280),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _LabeledDropdown extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledDropdown({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _DropdownBox<T> extends StatelessWidget {
  final T value;
  final bool enabled;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownBox({
    required this.value,
    required this.enabled,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: 41,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        items: items,
        onChanged: enabled ? onChanged : null,
        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
        style: const TextStyle(
          color: Color(0xFF17212F),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}

class _Notice extends StatelessWidget {
  final String text;

  const _Notice(this.text);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Color(0xFF6B7280)),
    ),
  );
}
