# Données de Test - Système de Notes Tunisien

## 📋 Structure des Données

### Étudiants (15 au total)
| Classe | Nombre | IDs |
|--------|--------|-----|
| 4ème Math | 3 | 11000000-...-001 à 003 |
| 4ème Sciences | 3 | 11000000-...-004 à 006 |
| 3ème Année | 3 | 11000000-...-007 à 009 |
| 2ème Année | 3 | 11000000-...-010 à 012 |
| 1ère Année | 3 | 11000000-...-013 à 015 |

### Formule de Calcul Tunisienne
```
Moyenne Matière = (Oral + DC + 2×Synthèse) / 4
Moyenne Générale = Σ(Moyenne × Coefficient) / Σ(Coefficients)
```

### Composantes de Notes
| Composante | Poids | Description |
|------------|-------|-------------|
| ORALE | 25% (1/4) | Participation, devoirs, oral |
| CC | 25% (1/4) | Devoir de Contrôle |
| SYNTHESE | 50% (2/4) | Devoir de Synthèse (poids double) |

### Cas Spécial: Sport
```
Moyenne Sport = (Continue + 2×Pratique) / 3
```
- CC: 33.33%
- TP (Pratique): 66.67%

## 📚 Coefficients par Section

### 4ème Math
| Matière | Coefficient |
|---------|-------------|
| Mathématiques | 4 |
| Physique | 3 |
| SVT | 2 |
| Français | 2 |
| Anglais | 2 |
| Arabe | 2 |
| Philosophie | 1 |
| Sport | 1 |
| **Total** | **17** |

### 4ème Sciences
| Matière | Coefficient |
|---------|-------------|
| SVT | 4 |
| Physique | 3 |
| Mathématiques | 3 |
| Français | 2 |
| Anglais | 2 |
| Arabe | 2 |
| Philosophie | 1 |
| Sport | 1 |
| **Total** | **18** |

## 🚀 Utilisation

### 1. Nettoyer les anciennes données
```sql
-- Exécuter dans Supabase SQL Editor
\i 00_cleanup.sql
```

### 2. Insérer les nouvelles données
```sql
-- Exécuter dans Supabase SQL Editor
\i 01_test_data.sql
```

### 3. Vérifier les données
```sql
-- Compter les étudiants
SELECT COUNT(*) FROM users WHERE role = 'student';

-- Voir les notes
SELECT 
  u.full_name,
  s.name as subject,
  gc.name as component,
  g.grade_value
FROM grades g
JOIN enrollments e ON g.enrollment_id = e.id
JOIN users u ON e.user_id = u.id
JOIN subject_offerings so ON g.subject_offering_id = so.id
JOIN subjects s ON so.subject_id = s.id
JOIN grade_components gc ON g.component_id = gc.id
ORDER BY u.full_name, s.name, gc.name;
```

## 📊 Exemples de Calcul

### Yassine Khelifi (4ème Math - Excellent)
| Matière | Oral | CC | Synthèse | Moyenne | Coef | Pondérée |
|---------|------|----|----|---------|------|----------|
| Math | 18 | 17 | 19 | 18.25 | 4 | 73.00 |
| Physique | 17 | 16 | 18 | 17.25 | 3 | 51.75 |
| SVT | 16 | 15 | 17 | 16.25 | 2 | 32.50 |
| Français | 17 | 16 | 17 | 16.75 | 2 | 33.50 |
| Anglais | 18 | 17 | 18 | 17.75 | 2 | 35.50 |
| **Total** | | | | | **13** | **226.25** |

**Moyenne Générale = 226.25 / 13 = 17.40**

### Salma Mansour (4ème Sciences - Excellente)
| Matière | Oral | CC | Synthèse | Moyenne | Coef | Pondérée |
|---------|------|----|----|---------|------|----------|
| Math | 19 | 18 | 20 | 19.25 | 3 | 57.75 |
| Physique | 18 | 17 | 19 | 18.25 | 3 | 54.75 |
| SVT | 20 | 19 | 20 | 19.75 | 4 | 79.00 |
| Français | 17 | 16 | 18 | 17.25 | 2 | 34.50 |
| Anglais | 18 | 17 | 18 | 17.75 | 2 | 35.50 |
| **Total** | | | | | **14** | **261.50** |

**Moyenne Générale = 261.50 / 14 = 18.68**

## 🔧 Comptes de Test

### Admin
- Email: `admin@pythagore.tn`
- Password: `Test123!`

### Staff
- Email: `staff1@pythagore.tn`
- Password: `Test123!`

### Étudiants
- Email: `yassine.khelifi@student.pythagore.tn`
- Password: `Test123!`
