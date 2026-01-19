import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/student_result_model.dart';
import '../../../data/models/grading_config_model.dart';

class StudentBulletinView extends StatefulWidget {
  final List<StudentResult> students;
  final ClassResult classResult;
  final GradingConfiguration? gradingConfig;

  const StudentBulletinView({
    super.key,
    required this.students,
    required this.classResult,
    this.gradingConfig,
  });

  @override
  State<StudentBulletinView> createState() => _StudentBulletinViewState();
}

class _StudentBulletinViewState extends State<StudentBulletinView> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.students.isEmpty) {
      return const Center(child: Text('Aucun élève à afficher'));
    }

    final selectedStudent = widget.students[_selectedIndex];

    return Row(
      children: [
        // Student List
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              right: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Column(
            children: [
              // List Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Élèves (${widget.students.length})',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  itemCount: widget.students.length,
                  itemBuilder: (context, index) {
                    final student = widget.students[index];
                    final isSelected = index == _selectedIndex;

                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: colorScheme.primaryContainer
                          .withOpacity(0.3),
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundImage: student.photoUrl != null
                            ? NetworkImage(student.photoUrl!)
                            : null,
                        backgroundColor: colorScheme.primaryContainer,
                        child: student.photoUrl == null
                            ? Text(
                                student.studentName.isNotEmpty
                                    ? student.studentName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        student.studentName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'Moy: ${student.annualAverage?.toStringAsFixed(2) ?? '--'} • Rang: ${student.rank}${student.rankSuffix}',
                        style: theme.textTheme.bodySmall,
                      ),
                      onTap: () {
                        setState(() => _selectedIndex = index);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Bulletin Preview
        Expanded(
          child: Column(
            children: [
              // Toolbar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  border: Border(
                    bottom: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Bulletin de ${selectedStudent.studentName}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),

                    // Navigation buttons
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _selectedIndex > 0
                          ? () => setState(() => _selectedIndex--)
                          : null,
                      tooltip: 'Élève précédent',
                    ),
                    Text('${_selectedIndex + 1} / ${widget.students.length}'),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _selectedIndex < widget.students.length - 1
                          ? () => setState(() => _selectedIndex++)
                          : null,
                      tooltip: 'Élève suivant',
                    ),

                    const SizedBox(width: 16),

                    // Print button
                    FilledButton.tonalIcon(
                      onPressed: () => _printBulletin(selectedStudent),
                      icon: const Icon(Icons.print),
                      label: const Text('Imprimer'),
                    ),

                    const SizedBox(width: 8),

                    // PDF button
                    FilledButton.icon(
                      onPressed: () => _exportPDF(selectedStudent),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Exporter PDF'),
                    ),
                  ],
                ),
              ),

              // Bulletin Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildBulletinPreview(context, selectedStudent),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBulletinPreview(BuildContext context, StudentResult student) {
    final theme = Theme.of(context);
    // ignore: unused_local_variable
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // School Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'République Tunisienne',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Ministère de l\'Éducation',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Établissement Scolaire',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              // Title
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black54, width: 2),
                    ),
                    child: Text(
                      'BULLETIN DE NOTES',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Année Scolaire 2024-2025',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              // Student Photo
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 80,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black54),
                      image: student.photoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(student.photoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: student.photoUrl == null
                        ? Center(
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Student Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(child: _infoRow('Nom & Prénom:', student.studentName)),
                Expanded(child: _infoRow('Code:', student.studentCode)),
                Expanded(child: _infoRow('Classe:', student.className)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Grades Table for each semester
          for (final semester in student.semesters) ...[
            // Semester Title
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.grey.shade800,
              child: Center(
                child: Text(
                  semester.semesterName.toUpperCase(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),

            // Grades Table
            Table(
              border: TableBorder.all(color: Colors.grey.shade400),
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1),
                5: FlexColumnWidth(1.5),
              },
              children: [
                // Header
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade200),
                  children: const [
                    _BulletinHeaderCell('Matière'),
                    _BulletinHeaderCell('Coef'),
                    _BulletinHeaderCell('Oral'),
                    _BulletinHeaderCell('DC'),
                    _BulletinHeaderCell('DS'),
                    _BulletinHeaderCell('Moyenne'),
                  ],
                ),

                // Subject rows
                for (final subject in semester.subjects)
                  TableRow(
                    children: [
                      _BulletinCell(subject.subjectName),
                      _BulletinCell(
                        subject.coefficient.toString(),
                        center: true,
                      ),
                      _BulletinCell(
                        subject
                                .getGrade(GradeComponentType.oral)
                                ?.value
                                ?.toStringAsFixed(1) ??
                            '--',
                        center: true,
                      ),
                      _BulletinCell(
                        subject
                                .getGrade(GradeComponentType.dc)
                                ?.value
                                ?.toStringAsFixed(1) ??
                            '--',
                        center: true,
                      ),
                      _BulletinCell(
                        subject
                                .getGrade(GradeComponentType.ds)
                                ?.value
                                ?.toStringAsFixed(1) ??
                            '--',
                        center: true,
                      ),
                      _BulletinCell(
                        subject.average?.toStringAsFixed(2) ?? '--',
                        center: true,
                        bold: true,
                        color: _getGradeColor(subject.average),
                      ),
                    ],
                  ),

                // Total row
                TableRow(
                  decoration: BoxDecoration(color: Colors.blue.shade50),
                  children: [
                    const _BulletinCell('MOYENNE GÉNÉRALE', bold: true),
                    _BulletinCell(
                      semester.totalCoefficients.toString(),
                      center: true,
                      bold: true,
                    ),
                    const _BulletinCell(''),
                    const _BulletinCell(''),
                    const _BulletinCell(''),
                    _BulletinCell(
                      semester.average?.toStringAsFixed(2) ?? '--',
                      center: true,
                      bold: true,
                      color: _getGradeColor(semester.average),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],

          // Annual Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue.shade200, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryItem(
                  'Moyenne Annuelle',
                  student.annualAverage?.toStringAsFixed(2) ?? '--',
                  student.annualAverage != null && student.annualAverage! >= 10
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
                Container(width: 1, height: 40, color: Colors.blue.shade300),
                _summaryItem(
                  'Rang',
                  '${student.rank}${student.rankSuffix} / ${student.totalStudents}',
                  Colors.black87,
                ),
                Container(width: 1, height: 40, color: Colors.blue.shade300),
                _summaryItem(
                  'Mention',
                  student.performanceStatus,
                  _getStatusColor(student.performanceStatus),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Signatures
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Signature du Parent',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(width: 150, height: 1, color: Colors.black54),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Le Chef d\'Établissement',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(width: 150, height: 1, color: Colors.black54),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(color: Colors.black, fontSize: 12)),
      ],
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getGradeColor(double? grade) {
    if (grade == null) return Colors.grey;
    if (grade >= 16) return Colors.green.shade700;
    if (grade >= 14) return Colors.blue.shade700;
    if (grade >= 12) return Colors.orange.shade700;
    if (grade >= 10) return Colors.amber.shade800;
    return Colors.red.shade700;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Excellent':
        return Colors.green.shade700;
      case 'Très Bien':
        return Colors.blue.shade700;
      case 'Bien':
        return Colors.orange.shade700;
      case 'Passable':
        return Colors.amber.shade800;
      case 'Insuffisant':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  Future<void> _printBulletin(StudentResult student) async {
    final doc = await _generatePDF(student);
    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'Bulletin_${student.studentName.replaceAll(' ', '_')}.pdf',
    );
  }

  Future<void> _exportPDF(StudentResult student) async {
    final doc = await _generatePDF(student);
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'Bulletin_${student.studentName.replaceAll(' ', '_')}.pdf',
    );
  }

  Future<pw.Document> _generatePDF(StudentResult student) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'République Tunisienne',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Ministère de l\'Éducation',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Établissement Scolaire',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 2),
                    ),
                    child: pw.Text(
                      'BULLETIN DE NOTES',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              // Student Info
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  border: pw.Border.all(color: PdfColors.grey400),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(child: pw.Text('Nom: ${student.studentName}')),
                    pw.Expanded(child: pw.Text('Code: ${student.studentCode}')),
                    pw.Expanded(child: pw.Text('Classe: ${student.className}')),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Grades for each semester
              for (final semester in student.semesters) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  color: PdfColors.grey800,
                  child: pw.Center(
                    child: pw.Text(
                      semester.semesterName.toUpperCase(),
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      children: [
                        _pdfCell('Matière', header: true),
                        _pdfCell('Coef', header: true, center: true),
                        _pdfCell('Oral', header: true, center: true),
                        _pdfCell('DC', header: true, center: true),
                        _pdfCell('DS', header: true, center: true),
                        _pdfCell('Moyenne', header: true, center: true),
                      ],
                    ),
                    // Subject rows
                    for (final subject in semester.subjects)
                      pw.TableRow(
                        children: [
                          _pdfCell(subject.subjectName),
                          _pdfCell(
                            subject.coefficient.toString(),
                            center: true,
                          ),
                          _pdfCell(
                            subject
                                    .getGrade(GradeComponentType.oral)
                                    ?.value
                                    ?.toStringAsFixed(1) ??
                                '--',
                            center: true,
                          ),
                          _pdfCell(
                            subject
                                    .getGrade(GradeComponentType.dc)
                                    ?.value
                                    ?.toStringAsFixed(1) ??
                                '--',
                            center: true,
                          ),
                          _pdfCell(
                            subject
                                    .getGrade(GradeComponentType.ds)
                                    ?.value
                                    ?.toStringAsFixed(1) ??
                                '--',
                            center: true,
                          ),
                          _pdfCell(
                            subject.average?.toStringAsFixed(2) ?? '--',
                            center: true,
                            bold: true,
                          ),
                        ],
                      ),
                    // Total row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blue50,
                      ),
                      children: [
                        _pdfCell('MOYENNE GÉNÉRALE', bold: true),
                        _pdfCell(
                          semester.totalCoefficients.toString(),
                          center: true,
                          bold: true,
                        ),
                        _pdfCell(''),
                        _pdfCell(''),
                        _pdfCell(''),
                        _pdfCell(
                          semester.average?.toStringAsFixed(2) ?? '--',
                          center: true,
                          bold: true,
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 16),
              ],

              // Annual Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  border: pw.Border.all(color: PdfColors.blue200, width: 2),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text(
                          'Moyenne Annuelle',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          student.annualAverage?.toStringAsFixed(2) ?? '--',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text(
                          'Rang',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          '${student.rank}${student.rankSuffix} / ${student.totalStudents}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text(
                          'Mention',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          student.performanceStatus,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Signature du Parent',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      pw.SizedBox(height: 30),
                      pw.Container(
                        width: 120,
                        height: 1,
                        color: PdfColors.black,
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Le Chef d\'Établissement',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      pw.SizedBox(height: 30),
                      pw.Container(
                        width: 120,
                        height: 1,
                        color: PdfColors.black,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _pdfCell(
    String text, {
    bool header = false,
    bool center = false,
    bool bold = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: header || bold ? 10 : 9,
          fontWeight: header || bold ? pw.FontWeight.bold : null,
        ),
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }
}

class _BulletinHeaderCell extends StatelessWidget {
  final String text;

  const _BulletinHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _BulletinCell extends StatelessWidget {
  final String text;
  final bool center;
  final bool bold;
  final Color? color;

  const _BulletinCell(
    this.text, {
    this.center = false,
    this.bold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : null,
          fontSize: 11,
          color: color ?? Colors.black87,
        ),
        textAlign: center ? TextAlign.center : TextAlign.left,
      ),
    );
  }
}
