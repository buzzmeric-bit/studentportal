/// Default Tunisian Coefficient Tables
/// Based on 2023-2024 official curriculum

import 'grading_config_model.dart';

class TunisianCoefficientTables {
  /// College coefficients (7ème - 8ème - 9ème)
  static const collegeSubjects = [
    SubjectCoefficient(subjectName: 'Arabe', subjectCode: 'AR', coefficient: 4),
    SubjectCoefficient(subjectName: 'Français', subjectCode: 'FR', coefficient: 4),
    SubjectCoefficient(subjectName: 'Anglais', subjectCode: 'ANG', coefficient: 1.5),
    SubjectCoefficient(subjectName: 'Mathématiques', subjectCode: 'MATH', coefficient: 2),
    SubjectCoefficient(subjectName: 'Physique', subjectCode: 'PHYS', coefficient: 1, hasPractical: true),
    SubjectCoefficient(subjectName: 'SVT', subjectCode: 'SVT', coefficient: 1, hasPractical: true),
    SubjectCoefficient(subjectName: 'Éducation Islamique', subjectCode: 'ISLAM', coefficient: 1),
    SubjectCoefficient(subjectName: 'Éducation Civique', subjectCode: 'CIVIC', coefficient: 1),
    SubjectCoefficient(subjectName: 'Histoire', subjectCode: 'HIST', coefficient: 1),
    SubjectCoefficient(subjectName: 'Géographie', subjectCode: 'GEO', coefficient: 1),
    SubjectCoefficient(subjectName: 'Technologie', subjectCode: 'TECH', coefficient: 1, hasPractical: true),
    SubjectCoefficient(subjectName: 'Informatique', subjectCode: 'INFO', coefficient: 1.5, hasPractical: true),
    SubjectCoefficient(subjectName: 'Musique', subjectCode: 'MUS', coefficient: 1, hasPractical: true),
    SubjectCoefficient(subjectName: 'Arts Plastiques', subjectCode: 'ART', coefficient: 1, hasPractical: true),
    SubjectCoefficient(
      subjectName: 'Éducation Physique', 
      subjectCode: 'EPS', 
      coefficient: 1,
      components: [GradeComponentType.oral, GradeComponentType.practical],
      hasPractical: true,
    ),
  ];

  /// 1ère Année Secondaire (Tronc Commun)
  static const lycee1Subjects = [
    SubjectCoefficient(subjectName: 'Arabe', subjectCode: 'AR', coefficient: 3),
    SubjectCoefficient(subjectName: 'Français', subjectCode: 'FR', coefficient: 2.5),
    SubjectCoefficient(subjectName: 'Anglais', subjectCode: 'ANG', coefficient: 1.5),
    SubjectCoefficient(subjectName: 'Mathématiques', subjectCode: 'MATH', coefficient: 3),
    SubjectCoefficient(subjectName: 'Physique', subjectCode: 'PHYS', coefficient: 2.5, hasPractical: true),
    SubjectCoefficient(subjectName: 'SVT', subjectCode: 'SVT', coefficient: 1.5, hasPractical: true),
    SubjectCoefficient(subjectName: 'Histoire', subjectCode: 'HIST', coefficient: 1.5),
    SubjectCoefficient(subjectName: 'Géographie', subjectCode: 'GEO', coefficient: 1.5),
    SubjectCoefficient(subjectName: 'Éducation Islamique', subjectCode: 'ISLAM', coefficient: 1),
    SubjectCoefficient(subjectName: 'Éducation Civique', subjectCode: 'CIVIC', coefficient: 1),
    SubjectCoefficient(subjectName: 'Technologie', subjectCode: 'TECH', coefficient: 1, hasPractical: true),
    SubjectCoefficient(subjectName: 'Informatique', subjectCode: 'INFO', coefficient: 1, hasPractical: true),
    SubjectCoefficient(
      subjectName: 'Éducation Physique', 
      subjectCode: 'EPS', 
      coefficient: 1,
      components: [GradeComponentType.oral, GradeComponentType.practical],
      hasPractical: true,
    ),
  ];

  /// 2ème Année - Section Mathématiques
  static const lycee2MathSubjects = [
    SubjectCoefficient(subjectName: 'Arabe', subjectCode: 'AR', coefficient: 1),
    SubjectCoefficient(subjectName: 'Français', subjectCode: 'FR', coefficient: 1),
    SubjectCoefficient(subjectName: 'Anglais', subjectCode: 'ANG', coefficient: 1),
    SubjectCoefficient(subjectName: 'Histoire', subjectCode: 'HIST', coefficient: 1),
    SubjectCoefficient(subjectName: 'Géographie', subjectCode: 'GEO', coefficient: 1),
    SubjectCoefficient(subjectName: 'Éducation Islamique', subjectCode: 'ISLAM', coefficient: 1),
    SubjectCoefficient(subjectName: 'Éducation Civique', subjectCode: 'CIVIC', coefficient: 1),
    SubjectCoefficient(subjectName: 'Mathématiques', subjectCode: 'MATH', coefficient: 4),
    SubjectCoefficient(subjectName: 'Physique', subjectCode: 'PHYS', coefficient: 4, hasPractical: true),
    SubjectCoefficient(subjectName: 'SVT', subjectCode: 'SVT', coefficient: 1, hasPractical: true),
    SubjectCoefficient(subjectName: 'Informatique', subjectCode: 'INFO', coefficient: 1, hasPractical: true),
    SubjectCoefficient(
      subjectName: 'Éducation Physique', 
      subjectCode: 'EPS', 
      coefficient: 1,
      components: [GradeComponentType.oral, GradeComponentType.practical],
      hasPractical: true,
    ),
  ];

  /// 2ème Année - Section Sciences Expérimentales
  static const lycee2SciencesSubjects = [
    SubjectCoefficient(subjectName: 'Arabe', subjectCode: 'AR', coefficient: 1),
    SubjectCoefficient(subjectName: 'Français', subjectCode: 'FR', coefficient: 1),
    SubjectCoefficient(subjectName: 'Anglais', subjectCode: 'ANG', coefficient: 1),
    SubjectCoefficient(subjectName: 'Histoire', subjectCode: 'HIST', coefficient: 1),
    SubjectCoefficient(subjectName: 'Géographie', subjectCode: 'GEO', coefficient: 1),
    SubjectCoefficient(subjectName: 'Éducation Islamique', subjectCode: 'ISLAM', coefficient: 1),
    SubjectCoefficient(subjectName: 'Éducation Civique', subjectCode: 'CIVIC', coefficient: 1),
    SubjectCoefficient(subjectName: 'Mathématiques', subjectCode: 'MATH', coefficient: 3),
    SubjectCoefficient(subjectName: 'Physique', subjectCode: 'PHYS', coefficient: 4, hasPractical: true),
    SubjectCoefficient(subjectName: 'SVT', subjectCode: 'SVT', coefficient: 4, hasPractical: true),
    SubjectCoefficient(subjectName: 'Informatique', subjectCode: 'INFO', coefficient: 1, hasPractical: true),
    SubjectCoefficient(
      subjectName: 'Éducation Physique', 
      subjectCode: 'EPS', 
      coefficient: 1,
      components: [GradeComponentType.oral, GradeComponentType.practical],
      hasPractical: true,
    ),
  ];

  /// 2ème Année - Section Technique
  static const lycee2TechSubjects = [
    SubjectCoefficient(subjectName: 'Arabe', subjectCode: 'AR', coefficient: 1),
    SubjectCoefficient(subjectName: 'Français', subjectCode: 'FR', coefficient: 1),
    SubjectCoefficient(subjectName: 'Anglais', subjectCode: 'ANG', coefficient: 1),
    SubjectCoefficient(subjectName: 'Histoire', subjectCode: 'HIST', coefficient: 1),
    SubjectCoefficient(subjectName: 'Géographie', subjectCode: 'GEO', coefficient: 1),
    SubjectCoefficient(subjectName: 'Éducation Islamique', subjectCode: 'ISLAM', coefficient: 1),
    SubjectCoefficient(subjectName: 'Éducation Civique', subjectCode: 'CIVIC', coefficient: 1),
    SubjectCoefficient(subjectName: 'Mathématiques', subjectCode: 'MATH', coefficient: 3),
    SubjectCoefficient(subjectName: 'Physique', subjectCode: 'PHYS', coefficient: 3, hasPractical: true),
    SubjectCoefficient(subjectName: 'Technologie', subjectCode: 'TECH', coefficient: 3, hasPractical: true),
    SubjectCoefficient(subjectName: 'Informatique', subjectCode: 'INFO', coefficient: 1, hasPractical: true),
    SubjectCoefficient(
      subjectName: 'Éducation Physique', 
      subjectCode: 'EPS', 
      coefficient: 1,
      components: [GradeComponentType.oral, GradeComponentType.practical],
      hasPractical: true,
    ),
  ];

  /// 2ème Année - Section Économie-Gestion
  static const lycee2EcoSubjects = [
    SubjectCoefficient(subjectName: 'Arabe', subjectCode: 'AR', coefficient: 1),
    SubjectCoefficient(subjectName: 'Français', subjectCode: 'FR', coefficient: 1),
    SubjectCoefficient(subjectName: 'Anglais', subjectCode: 'ANG', coefficient: 1),
    SubjectCoefficient(subjectName: 'Histoire', subjectCode: 'HIST', coefficient: 1),
    SubjectCoefficient(subjectName: 'Géographie', subjectCode: 'GEO', coefficient: 1),
    SubjectCoefficient(subjectName: 'Éducation Islamique', subjectCode: 'ISLAM', coefficient: 1),
    SubjectCoefficient(subjectName: 'Éducation Civique', subjectCode: 'CIVIC', coefficient: 1),
    SubjectCoefficient(subjectName: 'Mathématiques', subjectCode: 'MATH', coefficient: 2),
    SubjectCoefficient(subjectName: 'Économie', subjectCode: 'ECO', coefficient: 3),
    SubjectCoefficient(subjectName: 'Gestion', subjectCode: 'GEST', coefficient: 3),
    SubjectCoefficient(subjectName: 'Informatique', subjectCode: 'INFO', coefficient: 0.5, hasPractical: true),
    SubjectCoefficient(
      subjectName: 'Éducation Physique', 
      subjectCode: 'EPS', 
      coefficient: 1,
      components: [GradeComponentType.oral, GradeComponentType.practical],
      hasPractical: true,
    ),
  ];

  /// 2ème Année - Section Lettres
  static const lycee2LettresSubjects = [
    SubjectCoefficient(subjectName: 'Arabe', subjectCode: 'AR', coefficient: 4),
    SubjectCoefficient(subjectName: 'Français', subjectCode: 'FR', coefficient: 2),
    SubjectCoefficient(subjectName: 'Anglais', subjectCode: 'ANG', coefficient: 2),
    SubjectCoefficient(subjectName: 'Histoire', subjectCode: 'HIST', coefficient: 2),
    SubjectCoefficient(subjectName: 'Géographie', subjectCode: 'GEO', coefficient: 2),
    SubjectCoefficient(subjectName: 'Éducation Islamique', subjectCode: 'ISLAM', coefficient: 1),
    SubjectCoefficient(subjectName: 'Éducation Civique', subjectCode: 'CIVIC', coefficient: 1),
    SubjectCoefficient(subjectName: 'Mathématiques', subjectCode: 'MATH', coefficient: 1),
    SubjectCoefficient(subjectName: 'Informatique', subjectCode: 'INFO', coefficient: 1, hasPractical: true),
    SubjectCoefficient(
      subjectName: 'Éducation Physique', 
      subjectCode: 'EPS', 
      coefficient: 1,
      components: [GradeComponentType.oral, GradeComponentType.practical],
      hasPractical: true,
    ),
    SubjectCoefficient(subjectName: 'Arts/Musique', subjectCode: 'ART', coefficient: 1, hasPractical: true),
  ];

  /// 3ème Année - Section Mathématiques
  static const lycee3MathSubjects = [
    SubjectCoefficient(subjectName: 'Arabe', subjectCode: 'AR', coefficient: 1),
    SubjectCoefficient(subjectName: 'Français', subjectCode: 'FR', coefficient: 1),
    SubjectCoefficient(subjectName: 'Anglais', subjectCode: 'ANG', coefficient: 1),
    SubjectCoefficient(subjectName: 'Histoire', subjectCode: 'HIST', coefficient: 1),
    SubjectCoefficient(subjectName: 'Géographie', subjectCode: 'GEO', coefficient: 1),
    SubjectCoefficient(subjectName: 'Éducation Islamique', subjectCode: 'ISLAM', coefficient: 1),
    SubjectCoefficient(subjectName: 'Philosophie', subjectCode: 'PHILO', coefficient: 1),
    SubjectCoefficient(subjectName: 'Mathématiques', subjectCode: 'MATH', coefficient: 4),
    SubjectCoefficient(subjectName: 'Physique', subjectCode: 'PHYS', coefficient: 4, hasPractical: true),
    SubjectCoefficient(subjectName: 'SVT', subjectCode: 'SVT', coefficient: 1, hasPractical: true),
    SubjectCoefficient(subjectName: 'Informatique', subjectCode: 'INFO', coefficient: 1, hasPractical: true),
    SubjectCoefficient(
      subjectName: 'Éducation Physique', 
      subjectCode: 'EPS', 
      coefficient: 1,
      components: [GradeComponentType.oral, GradeComponentType.practical],
      hasPractical: true,
    ),
  ];

  /// 3ème Année - Section Sciences Expérimentales
  static const lycee3SciencesSubjects = [
    SubjectCoefficient(subjectName: 'Arabe', subjectCode: 'AR', coefficient: 1),
    SubjectCoefficient(subjectName: 'Français', subjectCode: 'FR', coefficient: 1),
    SubjectCoefficient(subjectName: 'Anglais', subjectCode: 'ANG', coefficient: 1),
    SubjectCoefficient(subjectName: 'Histoire', subjectCode: 'HIST', coefficient: 1),
    SubjectCoefficient(subjectName: 'Géographie', subjectCode: 'GEO', coefficient: 1),
    SubjectCoefficient(subjectName: 'Éducation Islamique', subjectCode: 'ISLAM', coefficient: 1),
    SubjectCoefficient(subjectName: 'Philosophie', subjectCode: 'PHILO', coefficient: 2),
    SubjectCoefficient(subjectName: 'Mathématiques', subjectCode: 'MATH', coefficient: 3),
    SubjectCoefficient(subjectName: 'Physique', subjectCode: 'PHYS', coefficient: 4, hasPractical: true),
    SubjectCoefficient(subjectName: 'SVT', subjectCode: 'SVT', coefficient: 4, hasPractical: true),
    SubjectCoefficient(subjectName: 'Informatique', subjectCode: 'INFO', coefficient: 1, hasPractical: true),
    SubjectCoefficient(
      subjectName: 'Éducation Physique', 
      subjectCode: 'EPS', 
      coefficient: 1,
      components: [GradeComponentType.oral, GradeComponentType.practical],
      hasPractical: true,
    ),
  ];

  /// 4ème Année (Bac) - Section Mathématiques
  static const lycee4MathSubjects = [
    SubjectCoefficient(subjectName: 'Arabe', subjectCode: 'AR', coefficient: 1),
    SubjectCoefficient(subjectName: 'Français', subjectCode: 'FR', coefficient: 1),
    SubjectCoefficient(subjectName: 'Anglais', subjectCode: 'ANG', coefficient: 1),
    SubjectCoefficient(subjectName: 'Philosophie', subjectCode: 'PHILO', coefficient: 1),
    SubjectCoefficient(subjectName: 'Mathématiques', subjectCode: 'MATH', coefficient: 4),
    SubjectCoefficient(subjectName: 'Physique', subjectCode: 'PHYS', coefficient: 4, hasPractical: true),
    SubjectCoefficient(subjectName: 'SVT', subjectCode: 'SVT', coefficient: 1, hasPractical: true),
    SubjectCoefficient(subjectName: 'Informatique', subjectCode: 'INFO', coefficient: 1, hasPractical: true),
    SubjectCoefficient(
      subjectName: 'Éducation Physique', 
      subjectCode: 'EPS', 
      coefficient: 1,
      components: [GradeComponentType.oral, GradeComponentType.practical],
      hasPractical: true,
    ),
  ];

  /// 4ème Année (Bac) - Section Sciences Expérimentales
  static const lycee4SciencesSubjects = [
    SubjectCoefficient(subjectName: 'Arabe', subjectCode: 'AR', coefficient: 1),
    SubjectCoefficient(subjectName: 'Français', subjectCode: 'FR', coefficient: 1),
    SubjectCoefficient(subjectName: 'Anglais', subjectCode: 'ANG', coefficient: 1),
    SubjectCoefficient(subjectName: 'Philosophie', subjectCode: 'PHILO', coefficient: 2),
    SubjectCoefficient(subjectName: 'Mathématiques', subjectCode: 'MATH', coefficient: 3),
    SubjectCoefficient(subjectName: 'Physique', subjectCode: 'PHYS', coefficient: 4, hasPractical: true),
    SubjectCoefficient(subjectName: 'SVT', subjectCode: 'SVT', coefficient: 4, hasPractical: true),
    SubjectCoefficient(
      subjectName: 'Éducation Physique', 
      subjectCode: 'EPS', 
      coefficient: 1,
      components: [GradeComponentType.oral, GradeComponentType.practical],
      hasPractical: true,
    ),
  ];

  /// 4ème Année (Bac) - Section Informatique
  static const lycee4InfoSubjects = [
    SubjectCoefficient(subjectName: 'Arabe', subjectCode: 'AR', coefficient: 1),
    SubjectCoefficient(subjectName: 'Français', subjectCode: 'FR', coefficient: 1),
    SubjectCoefficient(subjectName: 'Anglais', subjectCode: 'ANG', coefficient: 1),
    SubjectCoefficient(subjectName: 'Philosophie', subjectCode: 'PHILO', coefficient: 2),
    SubjectCoefficient(subjectName: 'Mathématiques', subjectCode: 'MATH', coefficient: 3),
    SubjectCoefficient(subjectName: 'Physique', subjectCode: 'PHYS', coefficient: 3, hasPractical: true),
    SubjectCoefficient(
      subjectName: 'Informatique', 
      subjectCode: 'INFO', 
      coefficient: 4, 
      hasPractical: true,
      components: [GradeComponentType.tp, GradeComponentType.dc, GradeComponentType.ds],
    ),
    SubjectCoefficient(
      subjectName: 'Éducation Physique', 
      subjectCode: 'EPS', 
      coefficient: 1,
      components: [GradeComponentType.oral, GradeComponentType.practical],
      hasPractical: true,
    ),
  ];

  /// Get default configuration for a level/section
  static GradingConfiguration getDefaultConfiguration(
    EducationLevel level, [
    AcademicSection? section,
  ]) {
    List<SubjectCoefficient> subjects;
    
    switch (level) {
      case EducationLevel.college7:
      case EducationLevel.college8:
      case EducationLevel.college9:
        subjects = collegeSubjects;
        break;
      case EducationLevel.lycee1:
        subjects = lycee1Subjects;
        section = AcademicSection.troncCommun;
        break;
      case EducationLevel.lycee2:
        subjects = _getLycee2Subjects(section ?? AcademicSection.math);
        break;
      case EducationLevel.lycee3:
        subjects = _getLycee3Subjects(section ?? AcademicSection.math);
        break;
      case EducationLevel.lycee4:
        subjects = _getLycee4Subjects(section ?? AcademicSection.math);
        break;
    }

    return GradingConfiguration(
      id: '${level.name}_${section?.name ?? 'default'}',
      level: level,
      section: section,
      subjects: subjects,
      defaultFormula: GradingFormula.standard,
      subjectFormulas: {
        'EPS': GradingFormula.sport,
      },
    );
  }

  static List<SubjectCoefficient> _getLycee2Subjects(AcademicSection section) {
    switch (section) {
      case AcademicSection.math:
        return lycee2MathSubjects;
      case AcademicSection.sciences:
        return lycee2SciencesSubjects;
      case AcademicSection.technique:
        return lycee2TechSubjects;
      case AcademicSection.economie:
        return lycee2EcoSubjects;
      case AcademicSection.lettres:
        return lycee2LettresSubjects;
      default:
        return lycee2MathSubjects;
    }
  }

  static List<SubjectCoefficient> _getLycee3Subjects(AcademicSection section) {
    switch (section) {
      case AcademicSection.math:
        return lycee3MathSubjects;
      case AcademicSection.sciences:
        return lycee3SciencesSubjects;
      default:
        return lycee3MathSubjects;
    }
  }

  static List<SubjectCoefficient> _getLycee4Subjects(AcademicSection section) {
    switch (section) {
      case AcademicSection.math:
        return lycee4MathSubjects;
      case AcademicSection.sciences:
        return lycee4SciencesSubjects;
      case AcademicSection.informatique:
        return lycee4InfoSubjects;
      default:
        return lycee4MathSubjects;
    }
  }

  /// Get all available sections for a level
  static List<AcademicSection> getSectionsForLevel(EducationLevel level) {
    switch (level) {
      case EducationLevel.college7:
      case EducationLevel.college8:
      case EducationLevel.college9:
        return [];
      case EducationLevel.lycee1:
        return [AcademicSection.troncCommun];
      case EducationLevel.lycee2:
        return [
          AcademicSection.math,
          AcademicSection.sciences,
          AcademicSection.technique,
          AcademicSection.economie,
          AcademicSection.lettres,
        ];
      case EducationLevel.lycee3:
        return [
          AcademicSection.math,
          AcademicSection.sciences,
          AcademicSection.technique,
          AcademicSection.economie,
          AcademicSection.lettres,
        ];
      case EducationLevel.lycee4:
        return [
          AcademicSection.math,
          AcademicSection.sciences,
          AcademicSection.technique,
          AcademicSection.economie,
          AcademicSection.lettres,
          AcademicSection.informatique,
        ];
    }
  }
}
