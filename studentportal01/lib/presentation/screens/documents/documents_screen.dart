import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../data/models/document_model.dart';

// Demo documents provider
final documentsProvider = FutureProvider<List<DocumentModel>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 500));
  
  return [
    DocumentModel(
      id: '1',
      schoolId: 'school1',
      title: 'Attestation de scolarité',
      description: 'Attestation de scolarité pour l\'année 2024-2025',
      category: 'administrative',
      fileUrl: 'https://example.com/attestation.pdf',
      fileName: 'attestation_scolarite_2024.pdf',
      fileSize: 256000,
      mimeType: 'application/pdf',
      createdAt: DateTime(2025, 9, 15),
    ),
    DocumentModel(
      id: '2',
      schoolId: 'school1',
      title: 'Relevé de notes - S1',
      description: 'Relevé de notes du premier semestre',
      category: 'administrative',
      fileUrl: 'https://example.com/releve.pdf',
      fileName: 'releve_notes_s1_2024.pdf',
      fileSize: 180000,
      mimeType: 'application/pdf',
      createdAt: DateTime(2025, 1, 20),
    ),
    DocumentModel(
      id: '3',
      schoolId: 'school1',
      title: 'Carte étudiant',
      description: 'Carte d\'étudiant numérique',
      category: 'administrative',
      fileUrl: 'https://example.com/carte.pdf',
      fileName: 'carte_etudiant_2024.pdf',
      fileSize: 95000,
      mimeType: 'application/pdf',
      createdAt: DateTime(2025, 10, 1),
    ),
    DocumentModel(
      id: '4',
      schoolId: 'school1',
      title: 'Certificat d\'inscription',
      description: 'Certificat d\'inscription pour l\'année 2024-2025',
      category: 'administrative',
      fileUrl: 'https://example.com/certificat.pdf',
      fileName: 'certificat_inscription_2024.pdf',
      fileSize: 145000,
      mimeType: 'application/pdf',
      createdAt: DateTime(2025, 9, 5),
    ),
  ];
});

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final documentsAsync = ref.watch(documentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.documents),
        backgroundColor: AppColors.tileDocuments,
        foregroundColor: Colors.white,
      ),
      body: documentsAsync.when(
        data: (documents) {
          if (documents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 64,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(height: AppSizes.paddingM),
                  Text(
                    l10n.noData,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            );
          }

          // Group documents by category
          final groupedDocs = <String, List<DocumentModel>>{};
          for (final doc in documents) {
            groupedDocs.putIfAbsent(doc.category, () => []).add(doc);
          }

          return ListView(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            children: [
              // Info card
              Card(
                color: AppColors.primary.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingM),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary),
                      const SizedBox(width: AppSizes.paddingM),
                      Expanded(
                        child: Text(
                          l10n.documentsDescription,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingL),
              // Document categories
              ...groupedDocs.entries.map((entry) {
                return _DocumentCategorySection(
                  category: entry.key,
                  documents: entry.value,
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSizes.paddingM),
              Text(l10n.error),
              TextButton(
                onPressed: () => ref.refresh(documentsProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentCategorySection extends StatelessWidget {
  final String category;
  final List<DocumentModel> documents;

  const _DocumentCategorySection({
    required this.category,
    required this.documents,
  });

  String _getCategoryLabel(String category, AppLocalizations l10n) {
    switch (category) {
      case 'administrative':
        return l10n.documentAdministrative;
      case 'courses':
        return 'Cours';
      case 'exams':
        return l10n.documentExams;
      default:
        return l10n.documentOther;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'administrative':
        return Icons.description;
      case 'courses':
        return Icons.menu_book;
      case 'exams':
        return Icons.assignment;
      default:
        return Icons.folder;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'administrative':
        return AppColors.primary;
      case 'courses':
        return Colors.green;
      case 'exams':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categoryColor = _getCategoryColor(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Icon(
                _getCategoryIcon(category),
                color: categoryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSizes.paddingS),
            Text(
              _getCategoryLabel(category, l10n),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: AppSizes.paddingS),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusL),
              ),
              child: Text(
                '${documents.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: categoryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.paddingS),
        ...documents.map((doc) => _DocumentCard(
              document: doc,
              categoryColor: categoryColor,
            )),
        const SizedBox(height: AppSizes.paddingL),
      ],
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final DocumentModel document;
  final Color categoryColor;

  const _DocumentCard({
    required this.document,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingS),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSizes.paddingM),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: categoryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
          ),
          child: Icon(
            document.isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file,
            color: categoryColor,
          ),
        ),
        title: Text(
          document.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (document.description != null) ...[
              const SizedBox(height: 4),
              Text(
                document.description!,
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(document.createdAt),
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                  ),
                ),
                if (document.fileSize != null) ...[
                  const SizedBox(width: AppSizes.paddingM),
                  Icon(Icons.storage, size: 12, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Text(
                    document.displayFileSize,
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.download, color: categoryColor),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${l10n.download}: ${document.fileName}'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        onTap: () {
          // Show document details
          _showDocumentDetails(context, document);
        },
      ),
    );
  }

  void _showDocumentDetails(BuildContext context, DocumentModel document) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('dd MMMM yyyy', 'fr_FR');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.paddingL),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  ),
                  child: Icon(
                    document.isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file,
                    color: categoryColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppSizes.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        document.displayCategory,
                        style: TextStyle(
                          color: categoryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (document.description != null) ...[
              const SizedBox(height: AppSizes.paddingL),
              Text(
                document.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: AppSizes.paddingL),
            const Divider(),
            const SizedBox(height: AppSizes.paddingM),
            _DetailRow(
              icon: Icons.insert_drive_file,
              label: 'Nom du fichier',
              value: document.fileName,
            ),
            if (document.fileSize != null) ...[
              const SizedBox(height: AppSizes.paddingS),
              _DetailRow(
                icon: Icons.storage,
                label: 'Taille',
                value: document.displayFileSize,
              ),
            ],
            const SizedBox(height: AppSizes.paddingS),
            _DetailRow(
              icon: Icons.calendar_today,
              label: 'Date',
              value: dateFormat.format(document.createdAt),
            ),
            const SizedBox(height: AppSizes.paddingL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l10n.download}: ${document.fileName}'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.download),
                label: Text(l10n.download),
                style: ElevatedButton.styleFrom(
                  backgroundColor: categoryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingM),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.paddingM),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textLight),
        const SizedBox(width: AppSizes.paddingS),
        Text(
          '$label: ',
          style: TextStyle(color: AppColors.textLight),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
