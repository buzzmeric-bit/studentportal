import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
  
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
  
  static const List<Locale> supportedLocales = [
    Locale('fr', ''), // French
    Locale('ar', ''), // Arabic
    Locale('en', ''), // English
  ];
  
  static const List<LocalizationsDelegate> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
  
  // Translations map
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // App
      'app_name': 'Student Portal',
      'welcome': 'Welcome',
      'logout': 'Logout',
      'settings': 'Settings',
      'profile': 'Profile',
      'contact_us': 'Contact Us',
      'about': 'About',
      
      // Auth
      'login': 'Login',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'forgot_password': 'Forgot Password?',
      'no_account': 'Don\'t have an account?',
      'already_account': 'Already have an account?',
      'sign_in': 'Sign In',
      'sign_up': 'Sign Up',
      
      // Home Menu Items
      'note_info': 'Info Notes',
      'messages': 'Messages',
      'suggestions': 'Suggestions',
      'absences': 'Absences',
      'resultats': 'Results',
      'emploi': 'Timetable',
      'mon_groupe': 'My Group',
      'mon_solde': 'My Balance',
      'documents': 'Documents',
      
      // Bottom Nav
      'my_profile': 'My Profile',
      'contact': 'Contact Us',
      'home': 'Home',
      'notifications': 'Notifications',
      
      // Absences
      'absence_list': 'Absence: List of Periods',
      'select_semester': 'Select Semester',
      'semester': 'Semester',
      'total_hours_charge': 'Total Hourly Load',
      'weekly_ci_hours': 'CI Hours/Week',
      'weekly_tp_hours': 'TP Hours/Week',
      'weeks': 'Weeks',
      'total_absent': 'Total Absent',
      'absence_percent': 'Absence %',
      'warning_absence': 'Warning! You are approaching the allowed absence threshold.',
      'critical_absence': 'Warning! You have exceeded the critical absence threshold.',
      'eliminated_absence': 'Warning! You have been eliminated from the main exam session.',
      
      // Results
      'semester_average': 'Semester Average',
      'coefficient': 'Coefficient',
      'subject_average': 'Subject Average',
      'grade_not_available': 'N/A',
      'grade_not_planned': 'N/P',
      
      // Suggestions
      'subject': 'Subject',
      'message': 'Message',
      'attachment': 'Attachment',
      'send': 'Send',
      'status_sent': 'Sent',
      'status_read': 'Read',
      'status_replied': 'Replied',
      
      // Payments
      'total_amount': 'Total Amount',
      'paid_amount': 'Paid Amount',
      'remaining_amount': 'Remaining Amount',
      'payment_history': 'Payment History',
      'payment_date': 'Date',
      'payment_method': 'Method',
      'payment_status': 'Status',
      'payment_pending': 'Pending',
      'payment_paid': 'Paid',
      'payment_overdue': 'Overdue',
      
      // Timetable
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',
      'saturday': 'Saturday',
      'sunday': 'Sunday',
      'room': 'Room',
      'teacher': 'Teacher',
      
      // Documents
      'download': 'Download',
      'category': 'Category',
      'administrative': 'Administrative',
      'courses': 'Courses',
      'exams': 'Exams',
      'other': 'Other',
      
      // Group
      'class_name': 'Class',
      'level': 'Level',
      'group': 'Group',
      'section': 'Section',
      
      // Settings
      'language': 'Language',
      'theme': 'Theme',
      'light_theme': 'Light',
      'dark_theme': 'Dark',
      'system_theme': 'System',
      'notifications_enabled': 'Notifications',
      
      // Common
      'loading': 'Loading...',
      'error': 'Error',
      'retry': 'Retry',
      'refresh': 'Refresh',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'confirm': 'Confirm',
      'no_data': 'No data available',
      'search': 'Search',
      'submit': 'Submit',
      'field_required': 'This field is required',
      'announcements': 'Announcements',
      
      // Absences Extended
      'total_hours': 'Total Hours',
      'ci_hours': 'CI Hours',
      'tp_hours': 'TP Hours',
      'absences_count': 'absences',
      'no_absences': 'No absences recorded',
      'absence_warning': 'Warning! You are approaching the allowed absence threshold.',
      'absence_critical': 'Critical! You have exceeded the critical absence threshold.',
      'absence_fail': 'Eliminated! You have been eliminated from the main exam session.',
      'no_classes': 'No classes scheduled',
      
      // Results Extended
      'component': 'Component',
      'weight': 'Weight',
      'grade': 'Grade',
      'no_grades_yet': 'No grades available yet',
      'passed': 'Passed',
      'failed': 'Failed',
      
      // Suggestions Extended
      'my_suggestions': 'My Suggestions',
      'new_suggestion': 'New Suggestion',
      'pending': 'Pending',
      'in_review': 'In Review',
      'replied': 'Replied',
      'closed': 'Closed',
      'reply': 'reply',
      'submitted_at': 'Submitted on',
      'admin_response': 'Admin Response',
      'submit_suggestion': 'Submit a Suggestion',
      'suggestion_desc': 'Share your ideas and feedback with us',
      'enter_subject': 'Enter subject',
      'your_suggestion': 'Your suggestion',
      'enter_suggestion': 'Describe your suggestion in detail...',
      'suggestion_min_length': 'Suggestion must be at least 20 characters',
      'suggestion_submitted': 'Suggestion submitted successfully!',
      
      // Payments Extended
      'payment_plan': 'Payment Plan',
      'remaining_balance': 'Remaining Balance',
      'paid': 'Paid',
      'total': 'Total',
      'fully_paid': 'Fully Paid',
      'in_progress': 'In Progress',
      'installment': 'Installment',
      'due_date': 'Due Date',
      'no_payments': 'No payments recorded',
      'cash': 'Cash',
      'bank_transfer': 'Bank Transfer',
      'check': 'Check',
      'card': 'Card',
      'receipt': 'Receipt',
      
      // Documents Extended
      'certificates': 'Certificates',
      'transcripts': 'Transcripts',
      'id_cards': 'ID Cards',
      'other_docs': 'Other Documents',
      'no_documents': 'No documents available',
      'downloading': 'Downloading',
      
      // Group Extended
      'search_students': 'Search students...',
      
      // Profile
      'personal_info': 'Personal Information',
      'academic_info': 'Academic Information',
      'full_name': 'Full Name',
      'phone': 'Phone',
      'birth_date': 'Birth Date',
      'group_name': 'Group',
      'academic_year': 'Academic Year',
      'student_id': 'Student ID',
      
      // Profile Extended
      'date_of_birth': 'Date of Birth',
      'address': 'Address',
      'student_code': 'Student Code',
      'current_class': 'Current Class',
      
      // Documents Extended
      'documents_description': 'Official documents and forms',
      'document_administrative': 'Administrative',
      'document_exams': 'Exams',
      'document_other': 'Other',
      
      // Timetable Extended
      'no_courses': 'No courses scheduled',
      
      // Absences Extended
      'absence_hours': 'hours of absence',
      
      // Payments Extended
      'payment_schedule': 'Payment Schedule',
      'status_paid': 'Paid',
      'status_overdue': 'Overdue',
      'status_pending': 'Pending',
      
      // Contact
      'need_help': 'Need Help?',
      'contact_desc': 'We are here to assist you with any questions or concerns.',
      'email_us': 'Email Us',
      'call_us': 'Call Us',
      'visit_us': 'Visit Us',
      'office_hours': 'Office Hours',
      'office_hours_value': 'Mon-Fri: 8:00 - 17:00',
      'follow_us': 'Follow Us',
      
      // About
      'about_desc': 'Student Portal is your comprehensive academic companion, designed to help you stay connected with your school and manage your academic journey effectively.',
      'features': 'Features',
      'feature_announcements': 'Real-time announcements and messages',
      'feature_grades': 'View your grades and academic performance',
      'feature_absences': 'Track your attendance and absences',
      'feature_timetable': 'Access your class schedule',
      'feature_payments': 'Manage tuition payments',
      'feature_documents': 'Download official documents',
      'developed_by': 'Developed By',
      'all_rights_reserved': 'All rights reserved.',
      'privacy_policy': 'Privacy Policy',
      'terms_of_service': 'Terms of Service',
    },
    'fr': {
      // App
      'app_name': 'Portail Étudiant',
      'welcome': 'Bienvenue',
      'logout': 'Déconnexion',
      'settings': 'Paramètres',
      'profile': 'Profil',
      'contact_us': 'Contactez-nous',
      'about': 'À propos de',
      
      // Auth
      'login': 'Connexion',
      'register': 'Inscription',
      'email': 'Email',
      'password': 'Mot de passe',
      'confirm_password': 'Confirmer le mot de passe',
      'forgot_password': 'Mot de passe oublié?',
      'no_account': 'Vous n\'avez pas de compte?',
      'already_account': 'Vous avez déjà un compte?',
      'sign_in': 'Se connecter',
      'sign_up': 'S\'inscrire',
      
      // Home Menu Items
      'note_info': 'Notifications',
      'messages': 'Messages',
      'suggestions': 'Suggestions',
      'absences': 'Absences',
      'resultats': 'Résultats',
      'emploi': 'Emploi',
      'mon_groupe': 'Mon Groupe',
      'mon_solde': 'Mon Solde',
      'documents': 'Documents',
      
      // Bottom Nav
      'my_profile': 'Mon Profil',
      'contact': 'Contactez-nous',
      'home': 'Accueil',
      'notifications': 'Notifications',
      
      // Absences
      'absence_list': 'Absence: Liste des périodes',
      'select_semester': 'Sélectionner le Semestre',
      'semester': 'Semestre',
      'total_hours_charge': 'Charge horaire totale',
      'weekly_ci_hours': 'Nbr H CI',
      'weekly_tp_hours': 'Nbr H TP',
      'weeks': 'Semaines',
      'total_absent': 'Total Absent',
      'absence_percent': '% Absence',
      'warning_absence': 'Attention! Vous approchez du seuil d\'absences autorisé.',
      'critical_absence': 'Attention! Vous avez dépassé le seuil critique d\'absences.',
      'eliminated_absence': 'Attention! Vous avez été éliminé de la session principale des examens.',
      
      // Results
      'semester_average': 'Moy Semestre',
      'coefficient': 'Coefficient',
      'subject_average': 'Moyenne Matière',
      'grade_not_available': 'ND',
      'grade_not_planned': 'NP',
      
      // Suggestions
      'subject': 'Sujet',
      'message': 'Message',
      'attachment': 'Pièce jointe',
      'send': 'Envoyer',
      'status_sent': 'Envoyé',
      'status_read': 'Lu',
      'status_replied': 'Répondu',
      
      // Payments
      'total_amount': 'Montant Total',
      'paid_amount': 'Montant Payé',
      'remaining_amount': 'Montant Restant',
      'payment_history': 'Historique des Paiements',
      'payment_date': 'Date',
      'payment_method': 'Méthode',
      'payment_status': 'Statut',
      'payment_pending': 'En attente',
      'payment_paid': 'Payé',
      'payment_overdue': 'En retard',
      
      // Timetable
      'monday': 'Lundi',
      'tuesday': 'Mardi',
      'wednesday': 'Mercredi',
      'thursday': 'Jeudi',
      'friday': 'Vendredi',
      'saturday': 'Samedi',
      'sunday': 'Dimanche',
      'room': 'Salle',
      'teacher': 'Enseignant',
      
      // Documents
      'download': 'Télécharger',
      'category': 'Catégorie',
      'administrative': 'Administratif',
      'courses': 'Cours',
      'exams': 'Examens',
      'other': 'Autre',
      
      // Group
      'class_name': 'Classe',
      'level': 'Niveau',
      'group': 'Groupe',
      'section': 'Section',
      
      // Settings
      'language': 'Langue',
      'theme': 'Thème',
      'light_theme': 'Clair',
      'dark_theme': 'Sombre',
      'system_theme': 'Système',
      'notifications_enabled': 'Notifications',
      
      // Common
      'loading': 'Chargement...',
      'error': 'Erreur',
      'retry': 'Réessayer',
      'refresh': 'Actualiser',
      'cancel': 'Annuler',
      'save': 'Enregistrer',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'confirm': 'Confirmer',
      'no_data': 'Aucune donnée disponible',
      'search': 'Rechercher',
      'submit': 'Envoyer',
      'field_required': 'Ce champ est requis',
      'announcements': 'Annonces',
      
      // Absences Extended
      'total_hours': 'Charge horaire totale',
      'ci_hours': 'Nbr H CI',
      'tp_hours': 'Nbr H TP',
      'absences_count': 'absences',
      'no_absences': 'Aucune absence enregistrée',
      'absence_warning': 'Attention! Vous approchez du seuil d\'absences autorisé.',
      'absence_critical': 'Critique! Vous avez dépassé le seuil critique d\'absences.',
      'absence_fail': 'Éliminé! Vous avez été éliminé de la session principale des examens.',
      'no_classes': 'Pas de cours programmés',
      
      // Results Extended
      'component': 'Composante',
      'weight': 'Poids',
      'grade': 'Note',
      'no_grades_yet': 'Aucune note disponible pour le moment',
      'passed': 'Validé',
      'failed': 'Non Validé',
      
      // Suggestions Extended
      'my_suggestions': 'Mes Suggestions',
      'new_suggestion': 'Nouvelle Suggestion',
      'pending': 'En attente',
      'in_review': 'En cours de traitement',
      'replied': 'Répondu',
      'closed': 'Fermé',
      'reply': 'réponse',
      'submitted_at': 'Soumis le',
      'admin_response': 'Réponse de l\'administration',
      'submit_suggestion': 'Soumettre une Suggestion',
      'suggestion_desc': 'Partagez vos idées et commentaires avec nous',
      'enter_subject': 'Entrez le sujet',
      'your_suggestion': 'Votre suggestion',
      'enter_suggestion': 'Décrivez votre suggestion en détail...',
      'suggestion_min_length': 'La suggestion doit contenir au moins 20 caractères',
      'suggestion_submitted': 'Suggestion soumise avec succès!',
      
      // Payments Extended
      'payment_plan': 'Plan de Paiement',
      'remaining_balance': 'Solde Restant',
      'paid': 'Payé',
      'total': 'Total',
      'fully_paid': 'Entièrement Payé',
      'in_progress': 'En cours',
      'installment': 'Tranche',
      'due_date': 'Échéance',
      'no_payments': 'Aucun paiement enregistré',
      'cash': 'Espèces',
      'bank_transfer': 'Virement bancaire',
      'check': 'Chèque',
      'card': 'Carte bancaire',
      'receipt': 'Reçu',
      
      // Documents Extended
      'certificates': 'Attestations',
      'transcripts': 'Relevés de notes',
      'id_cards': 'Cartes d\'étudiant',
      'other_docs': 'Autres documents',
      'no_documents': 'Aucun document disponible',
      'downloading': 'Téléchargement',
      
      // Group Extended
      'search_students': 'Rechercher des étudiants...',
      
      // Profile
      'personal_info': 'Informations Personnelles',
      'academic_info': 'Informations Académiques',
      'full_name': 'Nom Complet',
      'phone': 'Téléphone',
      'birth_date': 'Date de Naissance',
      'group_name': 'Groupe',
      'academic_year': 'Année Académique',
      'student_id': 'Numéro Étudiant',
      
      // Profile Extended
      'date_of_birth': 'Date de Naissance',
      'address': 'Adresse',
      'student_code': 'Code Étudiant',
      'current_class': 'Classe Actuelle',
      
      // Documents Extended FR
      'documents_description': 'Documents officiels et formulaires',
      'document_administrative': 'Administratif',
      'document_exams': 'Examens',
      'document_other': 'Autre',
      
      // Timetable Extended FR
      'no_courses': 'Pas de cours programmés',
      
      // Absences Extended FR
      'absence_hours': 'heures d\'absence',
      
      // Payments Extended FR
      'payment_schedule': 'Échéancier de Paiement',
      'status_paid': 'Payé',
      'status_overdue': 'En retard',
      'status_pending': 'En attente',
      
      // Contact
      'need_help': 'Besoin d\'aide?',
      'contact_desc': 'Nous sommes là pour vous aider avec toutes vos questions ou préoccupations.',
      'email_us': 'Envoyez-nous un Email',
      'call_us': 'Appelez-nous',
      'visit_us': 'Visitez-nous',
      'office_hours': 'Heures d\'ouverture',
      'office_hours_value': 'Lun-Ven: 8h00 - 17h00',
      'follow_us': 'Suivez-nous',
      
      // About
      'about_desc': 'Le Portail Étudiant est votre compagnon académique complet, conçu pour vous aider à rester connecté avec votre école et à gérer efficacement votre parcours académique.',
      'features': 'Fonctionnalités',
      'feature_announcements': 'Annonces et messages en temps réel',
      'feature_grades': 'Consultez vos notes et performances académiques',
      'feature_absences': 'Suivez votre présence et vos absences',
      'feature_timetable': 'Accédez à votre emploi du temps',
      'feature_payments': 'Gérez vos paiements de scolarité',
      'feature_documents': 'Téléchargez des documents officiels',
      'developed_by': 'Développé par',
      'all_rights_reserved': 'Tous droits réservés.',
      'privacy_policy': 'Politique de Confidentialité',
      'terms_of_service': 'Conditions d\'Utilisation',
    },
    'ar': {
      // App
      'app_name': 'بوابة الطالب',
      'welcome': 'مرحباً',
      'logout': 'تسجيل الخروج',
      'settings': 'الإعدادات',
      'profile': 'الملف الشخصي',
      'contact_us': 'اتصل بنا',
      'about': 'حول',
      
      // Auth
      'login': 'تسجيل الدخول',
      'register': 'التسجيل',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'confirm_password': 'تأكيد كلمة المرور',
      'forgot_password': 'نسيت كلمة المرور؟',
      'no_account': 'ليس لديك حساب؟',
      'already_account': 'لديك حساب بالفعل؟',
      'sign_in': 'دخول',
      'sign_up': 'إنشاء حساب',
      
      // Home Menu Items
      'note_info': 'ملاحظات',
      'messages': 'الرسائل',
      'suggestions': 'الاقتراحات',
      'absences': 'الغيابات',
      'resultats': 'النتائج',
      'emploi': 'الجدول الزمني',
      'mon_groupe': 'مجموعتي',
      'mon_solde': 'رصيدي',
      'documents': 'الوثائق',
      
      // Bottom Nav
      'my_profile': 'ملفي الشخصي',
      'contact': 'اتصل بنا',
      
      // Absences
      'absence_list': 'الغياب: قائمة الفترات',
      'select_semester': 'اختر الفصل الدراسي',
      'semester': 'الفصل الدراسي',
      'total_hours_charge': 'إجمالي الساعات',
      'weekly_ci_hours': 'ساعات المحاضرات/أسبوع',
      'weekly_tp_hours': 'ساعات التطبيق/أسبوع',
      'weeks': 'الأسابيع',
      'total_absent': 'إجمالي الغياب',
      'absence_percent': 'نسبة الغياب',
      'warning_absence': 'تحذير! أنت تقترب من حد الغياب المسموح.',
      'critical_absence': 'تحذير! لقد تجاوزت حد الغياب الحرج.',
      'eliminated_absence': 'تحذير! تم استبعادك من الجلسة الرئيسية للامتحانات.',
      
      // Results
      'semester_average': 'معدل الفصل',
      'coefficient': 'المعامل',
      'subject_average': 'معدل المادة',
      'grade_not_available': 'غ/م',
      'grade_not_planned': 'غ/م',
      
      // Suggestions
      'subject': 'الموضوع',
      'message': 'الرسالة',
      'attachment': 'مرفق',
      'send': 'إرسال',
      'status_sent': 'مرسل',
      'status_read': 'مقروء',
      'status_replied': 'تم الرد',
      
      // Payments
      'total_amount': 'المبلغ الإجمالي',
      'paid_amount': 'المبلغ المدفوع',
      'remaining_amount': 'المبلغ المتبقي',
      'payment_history': 'سجل الدفعات',
      'payment_date': 'التاريخ',
      'payment_method': 'طريقة الدفع',
      'payment_status': 'الحالة',
      'payment_pending': 'قيد الانتظار',
      'payment_paid': 'مدفوع',
      'payment_overdue': 'متأخر',
      
      // Timetable
      'monday': 'الإثنين',
      'tuesday': 'الثلاثاء',
      'wednesday': 'الأربعاء',
      'thursday': 'الخميس',
      'friday': 'الجمعة',
      'saturday': 'السبت',
      'sunday': 'الأحد',
      'room': 'القاعة',
      'teacher': 'الأستاذ',
      
      // Documents
      'download': 'تحميل',
      'category': 'الفئة',
      'administrative': 'إداري',
      'courses': 'دروس',
      'exams': 'امتحانات',
      'other': 'أخرى',
      
      // Group
      'class_name': 'الصف',
      'level': 'المستوى',
      'group': 'المجموعة',
      'section': 'الشعبة',
      
      // Settings
      'language': 'اللغة',
      'theme': 'المظهر',
      'light_theme': 'فاتح',
      'dark_theme': 'داكن',
      'system_theme': 'النظام',
      'notifications': 'الإشعارات',
      
      // Common
      'loading': 'جاري التحميل...',
      'error': 'خطأ',
      'retry': 'إعادة المحاولة',
      'refresh': 'تحديث',
      'cancel': 'إلغاء',
      'save': 'حفظ',
      'delete': 'حذف',
      'edit': 'تعديل',
      'confirm': 'تأكيد',
      'no_data': 'لا توجد بيانات',
      'search': 'بحث',
      'submit': 'إرسال',
      'field_required': 'هذا الحقل مطلوب',
      'announcements': 'الإعلانات',
      
      // Absences Extended
      'total_hours': 'إجمالي الساعات',
      'ci_hours': 'ساعات المحاضرات',
      'tp_hours': 'ساعات التطبيق',
      'absences_count': 'غيابات',
      'no_absences': 'لا يوجد غياب مسجل',
      'absence_warning': 'تحذير! أنت تقترب من حد الغياب المسموح.',
      'absence_critical': 'حرج! لقد تجاوزت حد الغياب الحرج.',
      'absence_fail': 'مستبعد! تم استبعادك من الجلسة الرئيسية للامتحانات.',
      'no_classes': 'لا توجد حصص مجدولة',
      
      // Results Extended
      'component': 'المكون',
      'weight': 'الوزن',
      'grade': 'الدرجة',
      'no_grades_yet': 'لا توجد درجات متاحة حالياً',
      'passed': 'ناجح',
      'failed': 'راسب',
      
      // Suggestions Extended
      'my_suggestions': 'اقتراحاتي',
      'new_suggestion': 'اقتراح جديد',
      'pending': 'قيد الانتظار',
      'in_review': 'قيد المراجعة',
      'replied': 'تم الرد',
      'closed': 'مغلق',
      'reply': 'رد',
      'submitted_at': 'تم التقديم في',
      'admin_response': 'رد الإدارة',
      'submit_suggestion': 'تقديم اقتراح',
      'suggestion_desc': 'شارك أفكارك وملاحظاتك معنا',
      'enter_subject': 'أدخل الموضوع',
      'your_suggestion': 'اقتراحك',
      'enter_suggestion': 'صف اقتراحك بالتفصيل...',
      'suggestion_min_length': 'يجب أن يحتوي الاقتراح على 20 حرفًا على الأقل',
      'suggestion_submitted': 'تم تقديم الاقتراح بنجاح!',
      
      // Payments Extended
      'payment_plan': 'خطة الدفع',
      'remaining_balance': 'الرصيد المتبقي',
      'paid': 'مدفوع',
      'total': 'الإجمالي',
      'fully_paid': 'مدفوع بالكامل',
      'in_progress': 'قيد التنفيذ',
      'installment': 'القسط',
      'due_date': 'تاريخ الاستحقاق',
      'no_payments': 'لا توجد مدفوعات مسجلة',
      'cash': 'نقداً',
      'bank_transfer': 'تحويل بنكي',
      'check': 'شيك',
      'card': 'بطاقة',
      'receipt': 'إيصال',
      
      // Documents Extended
      'certificates': 'الشهادات',
      'transcripts': 'كشوف الدرجات',
      'id_cards': 'بطاقات الطالب',
      'other_docs': 'مستندات أخرى',
      'no_documents': 'لا توجد مستندات متاحة',
      'downloading': 'جاري التحميل',
      
      // Group Extended
      'search_students': 'البحث عن طلاب...',
      
      // Profile
      'personal_info': 'المعلومات الشخصية',
      'academic_info': 'المعلومات الأكاديمية',
      'full_name': 'الاسم الكامل',
      'phone': 'الهاتف',
      'birth_date': 'تاريخ الميلاد',
      'group_name': 'المجموعة',
      'academic_year': 'السنة الدراسية',
      'student_id': 'رقم الطالب',
      
      // Profile Extended
      'date_of_birth': 'تاريخ الميلاد',
      'address': 'العنوان',
      'student_code': 'رمز الطالب',
      'current_class': 'الصف الحالي',
      
      // Documents Extended AR
      'documents_description': 'المستندات الرسمية والنماذج',
      'document_administrative': 'إداري',
      'document_exams': 'امتحانات',
      'document_other': 'أخرى',
      
      // Timetable Extended AR
      'no_courses': 'لا توجد حصص مجدولة',
      
      // Absences Extended AR
      'absence_hours': 'ساعات الغياب',
      
      // Payments Extended AR
      'payment_schedule': 'جدول الدفع',
      'status_paid': 'مدفوع',
      'status_overdue': 'متأخر',
      'status_pending': 'قيد الانتظار',
      
      // Contact
      'need_help': 'هل تحتاج مساعدة؟',
      'contact_desc': 'نحن هنا لمساعدتك في أي أسئلة أو استفسارات.',
      'email_us': 'راسلنا',
      'call_us': 'اتصل بنا',
      'visit_us': 'زورنا',
      'office_hours': 'ساعات العمل',
      'office_hours_value': 'الإثنين-الجمعة: 8:00 - 17:00',
      'follow_us': 'تابعنا',
      
      // About
      'about_desc': 'بوابة الطالب هي رفيقك الأكاديمي الشامل، مصممة لمساعدتك على البقاء على اتصال بمدرستك وإدارة مسيرتك الأكاديمية بفعالية.',
      'features': 'المميزات',
      'feature_announcements': 'إعلانات ورسائل فورية',
      'feature_grades': 'عرض درجاتك وأدائك الأكاديمي',
      'feature_absences': 'تتبع حضورك وغيابك',
      'feature_timetable': 'الوصول إلى جدول حصصك',
      'feature_payments': 'إدارة مدفوعات الرسوم الدراسية',
      'feature_documents': 'تحميل المستندات الرسمية',
      'developed_by': 'تم التطوير بواسطة',
      'all_rights_reserved': 'جميع الحقوق محفوظة.',
      'privacy_policy': 'سياسة الخصوصية',
      'terms_of_service': 'شروط الخدمة',
    },
  };
  
  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? 
           _localizedValues['en']?[key] ?? 
           key;
  }
  
  // Convenience getters
  String get appName => translate('app_name');
  String get welcome => translate('welcome');
  String get logout => translate('logout');
  String get settings => translate('settings');
  String get home => translate('home');
  String get profile => translate('profile');
  String get contactUs => translate('contact_us');
  String get about => translate('about');
  
  // Auth
  String get login => translate('login');
  String get register => translate('register');
  String get email => translate('email');
  String get password => translate('password');
  String get confirmPassword => translate('confirm_password');
  String get forgotPassword => translate('forgot_password');
  String get noAccount => translate('no_account');
  String get alreadyAccount => translate('already_account');
  String get signIn => translate('sign_in');
  String get signUp => translate('sign_up');
  
  // Home Menu
  String get noteInfo => translate('note_info');
  String get messages => translate('messages');
  String get suggestions => translate('suggestions');
  String get absences => translate('absences');
  String get resultats => translate('resultats');
  String get emploi => translate('emploi');
  String get monGroupe => translate('mon_groupe');
  String get monSolde => translate('mon_solde');
  String get documents => translate('documents');
  
  // Bottom Nav
  String get myProfile => translate('my_profile');
  String get contact => translate('contact');
  
  // Common
  String get loading => translate('loading');
  String get error => translate('error');
  String get retry => translate('retry');
  String get refresh => translate('refresh');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get noData => translate('no_data');
  String get search => translate('search');
  String get confirm => translate('confirm');
  String get submit => translate('submit');
  String get fieldRequired => translate('field_required');
  
  // Settings
  String get language => translate('language');
  String get theme => translate('theme');
  String get lightTheme => translate('light_theme');
  String get darkTheme => translate('dark_theme');
  String get systemTheme => translate('system_theme');
  String get notifications => translate('notifications');
  String get announcements => translate('announcements');
  
  // Semester/Timetable
  String get semester => translate('semester');
  String get monday => translate('monday');
  String get tuesday => translate('tuesday');
  String get wednesday => translate('wednesday');
  String get thursday => translate('thursday');
  String get friday => translate('friday');
  String get saturday => translate('saturday');
  String get noClasses => translate('no_classes');
  
  // Absences
  String get totalHours => translate('total_hours');
  String get ciHours => translate('ci_hours');
  String get tpHours => translate('tp_hours');
  String get weeks => translate('weeks');
  String get absencesCount => translate('absences_count');
  String get noAbsences => translate('no_absences');
  String get absenceWarning => translate('absence_warning');
  String get absenceCritical => translate('absence_critical');
  String get absenceFail => translate('absence_fail');
  
  // Results
  String get semesterAverage => translate('semester_average');
  String get coefficient => translate('coefficient');
  String get component => translate('component');
  String get weight => translate('weight');
  String get grade => translate('grade');
  String get noGradesYet => translate('no_grades_yet');
  String get passed => translate('passed');
  String get failed => translate('failed');
  
  // Suggestions
  String get mySuggestions => translate('my_suggestions');
  String get newSuggestion => translate('new_suggestion');
  String get pending => translate('pending');
  String get inReview => translate('in_review');
  String get replied => translate('replied');
  String get closed => translate('closed');
  String get reply => translate('reply');
  String get submittedAt => translate('submitted_at');
  String get adminResponse => translate('admin_response');
  String get submitSuggestion => translate('submit_suggestion');
  String get suggestionDesc => translate('suggestion_desc');
  String get subject => translate('subject');
  String get enterSubject => translate('enter_subject');
  String get yourSuggestion => translate('your_suggestion');
  String get enterSuggestion => translate('enter_suggestion');
  String get suggestionMinLength => translate('suggestion_min_length');
  String get suggestionSubmitted => translate('suggestion_submitted');
  
  // Payments
  String get paymentPlan => translate('payment_plan');
  String get paymentHistory => translate('payment_history');
  String get remainingBalance => translate('remaining_balance');
  String get paid => translate('paid');
  String get total => translate('total');
  String get fullyPaid => translate('fully_paid');
  String get inProgress => translate('in_progress');
  String get installment => translate('installment');
  String get dueDate => translate('due_date');
  String get noPayments => translate('no_payments');
  String get cash => translate('cash');
  String get bankTransfer => translate('bank_transfer');
  String get check => translate('check');
  String get card => translate('card');
  String get receipt => translate('receipt');
  
  // Documents
  String get certificates => translate('certificates');
  String get transcripts => translate('transcripts');
  String get idCards => translate('id_cards');
  String get otherDocs => translate('other_docs');
  String get noDocuments => translate('no_documents');
  String get download => translate('download');
  String get downloading => translate('downloading');
  
  // Group
  String get searchStudents => translate('search_students');
  
  // Profile
  String get personalInfo => translate('personal_info');
  String get academicInfo => translate('academic_info');
  String get fullName => translate('full_name');
  String get phone => translate('phone');
  String get birthDate => translate('birth_date');
  String get className => translate('class_name');
  String get groupName => translate('group_name');
  String get academicYear => translate('academic_year');
  String get studentId => translate('student_id');
  
  // Profile Extended
  String get monProfil => translate('my_profile');
  String get dateOfBirth => translate('date_of_birth');
  String get address => translate('address');
  String get studentCode => translate('student_code');
  String get currentClass => translate('current_class');
  String get group => translate('group');
  
  // Documents Extended
  String get documentsDescription => translate('documents_description');
  String get documentAdministrative => translate('document_administrative');
  String get documentExams => translate('document_exams');
  String get documentOther => translate('document_other');
  
  // Timetable Extended
  String get noCourses => translate('no_courses');
  
  // Absences Extended
  String get absenceHours => translate('absence_hours');
  
  // Payments Extended
  String get paymentSchedule => translate('payment_schedule');
  String get statusPaid => translate('status_paid');
  String get statusOverdue => translate('status_overdue');
  String get statusPending => translate('status_pending');
  
  // Contact
  String get needHelp => translate('need_help');
  String get contactDesc => translate('contact_desc');
  String get emailUs => translate('email_us');
  String get callUs => translate('call_us');
  String get visitUs => translate('visit_us');
  String get officeHours => translate('office_hours');
  String get officeHoursValue => translate('office_hours_value');
  String get followUs => translate('follow_us');
  
  // About
  String get aboutDesc => translate('about_desc');
  String get features => translate('features');
  String get featureAnnouncements => translate('feature_announcements');
  String get featureGrades => translate('feature_grades');
  String get featureAbsences => translate('feature_absences');
  String get featureTimetable => translate('feature_timetable');
  String get featurePayments => translate('feature_payments');
  String get featureDocuments => translate('feature_documents');
  String get developedBy => translate('developed_by');
  String get allRightsReserved => translate('all_rights_reserved');
  String get privacyPolicy => translate('privacy_policy');
  String get termsOfService => translate('terms_of_service');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  
  @override
  bool isSupported(Locale locale) {
    return ['en', 'fr', 'ar'].contains(locale.languageCode);
  }
  
  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }
  
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// Extension for easier access
extension AppLocalizationsExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
