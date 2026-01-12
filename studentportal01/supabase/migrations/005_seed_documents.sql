-- ============================================
-- SEED DOCUMENTS
-- ============================================
-- Run this after 003_seed_data.sql

INSERT INTO documents (school_id, class_id, title, description, category, file_url, file_name, file_size, mime_type) VALUES
-- Administrative documents (school-wide)
('11111111-1111-1111-1111-111111111111', NULL, 
 'Règlement Intérieur', 
 'Règlement intérieur de l''établissement pour l''année académique 2025-2026',
 'administrative',
 'https://example.com/docs/reglement.pdf',
 'reglement_interieur_2025_2026.pdf',
 245000,
 'application/pdf'),

('11111111-1111-1111-1111-111111111111', NULL, 
 'Calendrier Académique', 
 'Calendrier des activités pédagogiques et des vacances',
 'administrative',
 'https://example.com/docs/calendrier.pdf',
 'calendrier_academique_2025_2026.pdf',
 156000,
 'application/pdf'),

('11111111-1111-1111-1111-111111111111', NULL, 
 'Formulaire de Demande d''Attestation', 
 'Formulaire à remplir pour demander une attestation de scolarité',
 'administrative',
 'https://example.com/docs/attestation.pdf',
 'formulaire_attestation.pdf',
 89000,
 'application/pdf'),

-- Exams documents (school-wide)
('11111111-1111-1111-1111-111111111111', NULL, 
 'Planning des Examens S1', 
 'Planning des examens du premier semestre 2025-2026',
 'exams',
 'https://example.com/docs/planning_s1.pdf',
 'planning_examens_s1.pdf',
 120000,
 'application/pdf'),

('11111111-1111-1111-1111-111111111111', NULL, 
 'Consignes pour les Examens', 
 'Instructions et règles à respecter pendant les examens',
 'exams',
 'https://example.com/docs/consignes.pdf',
 'consignes_examens.pdf',
 78000,
 'application/pdf'),

-- Class-specific documents (1ère Année)
('11111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444441', 
 'Programme des Études L1', 
 'Programme détaillé des modules de première année Licence',
 'other',
 'https://example.com/docs/programme_l1.pdf',
 'programme_l1_info_gestion.pdf',
 340000,
 'application/pdf'),

('11111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444441', 
 'Emploi du Temps S1 - Année 1', 
 'Emploi du temps officiel du premier semestre pour la 1ère année',
 'other',
 'https://example.com/docs/edt_l1_s1.pdf',
 'emploi_temps_l1_s1.pdf',
 95000,
 'application/pdf');
