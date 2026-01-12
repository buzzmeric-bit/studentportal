# Student Portal Redesign - Modern 2026 UI/UX

## Overview
Complete redesign of the Student Portal with modern 2026 UI/UX and new Courses feature.

## Changes Implemented

### 1. Database Migrations
Created Supabase migrations for the courses feature:

#### `07_create_courses_tables.sql`
- **courses** table: Stores course information
  - Fields: id, school_id, class_id, group_id (nullable), subject, teacher_id, teacher_name, title, description, external_link, published_at, created_by, created_at, updated_at, is_published
  - Indexes on: school_id, class_id, group_id, published_at, is_published, subject, teacher_id
  - RLS policies for students (can SELECT published courses for their class/group)
  - RLS policies for teachers/admins (can INSERT, UPDATE, DELETE)

- **course_attachments** table: Stores file attachments
  - Fields: id, course_id, file_url, file_name, file_type, file_size, created_at
  - RLS policies aligned with courses table

- **course_views** table: Tracks student views
  - Fields: id, course_id, student_id, seen_at
  - Unique constraint on (course_id, student_id)
  - RLS policies for tracking views

#### `08_create_courses_storage.sql`
- Storage bucket: **courses**
- Folder structure: `courses/{course_id}/{filename}`
- Storage policies for upload/download/delete based on user role

### 2. Data Models

#### `course_model.dart`
- **CourseModel**: Main course data model
  - Properties include all database fields plus computed properties
  - Methods: `hasAttachments`, `attachmentCount`, `imageAttachments`, `documentAttachments`

- **CourseAttachmentModel**: Attachment data model
  - Properties for file metadata
  - Helper methods: `isImage`, `isPdf`, `isDocument`, `fileSizeFormatted`, `fileExtension`

- **CourseViewModel**: Tracks which students viewed courses

### 3. Data Access

#### `course_repository.dart`
- `fetchCourses()`: Get courses with filters (subject, teacher, search, attachments)
- `fetchCourseById()`: Get single course with attachments
- `fetchSubjects()`: Get unique subjects list
- `fetchTeacherNames()`: Get unique teachers list
- `markAsViewed()`: Mark course as seen by student
- `hasViewed()`: Check if student viewed course
- `getCourseCount()`: Get filtered course count
- `getAttachmentUrl()`: Get signed URL for file download

### 4. State Management

#### `course_provider.dart`
- **courseRepositoryProvider**: Repository instance
- **coursesProvider**: Fetch courses with filters
- **courseDetailProvider**: Fetch single course
- **subjectsProvider**: List of subjects for filters
- **teachersProvider**: List of teachers for filters
- **coursesFilterProvider**: Manages filter state
- **filteredCoursesProvider**: Courses list with current filters
- **markCourseAsViewedProvider**: Action to mark course as viewed

**CoursesFilter** model:
- Properties: subject, teacherName, searchQuery, hasAttachments, orderBy, ascending
- Method: `hasActiveFilters` to check if any filter is applied

### 5. Modern Theme (2026 Design)

#### Updated `app_theme.dart`
**Modern Color Palette:**
- Primary: Indigo 600 (#4F46E5)
- Secondary: Teal 500 (#14B8A6)
- Accent: Rose 500 (#F43F5E)
- Background: Slate 50 (#F8FAFC)
- Gradient: Indigo 500 → Violet 500

**Menu Tile Colors:**
- Note Info: Emerald (#10B981)
- Messages: Blue (#3B82F6)
- Suggestions: Amber (#F59E0B)
- Absences: Red (#EF4444)
- Results: Violet (#8B5CF6)
- Timetable: Teal (#14B8A6)
- **Courses: Indigo (#6366F1)** ← NEW
- Balance: Cyan (#06B6D4)
- Documents: Pink (#EC4899)

**Updated Sizes:**
- Border radius increased (more rounded): 6-28px
- Card elevation: 0 (flat design)
- Card shadow: softer 24px blur
- Grid tile icon: 64px container, 28px icon
- Badge sizing for notifications

### 6. UI Components

#### Redesigned `home_screen.dart`
**Modern Features:**
- **SliverAppBar** with gradient (Indigo → Violet)
- Header with:
  - App name subtitle
  - Student full name (large, bold)
  - Profile avatar (48px, bordered, with shadow)
  - Class/group pill badge (white translucent)
- **3×3 Grid** using SliverGrid
  - 9 tiles exactly
  - Replaced "Mon Groupe" with "Cours"
  - Added badges (Messages: 3, Suggestions: 1, Courses: 2)
  - Added helper text for some tiles

#### Enhanced `menu_tile.dart`
- Gradient icon backgrounds
- Badge support (count or indicator dot)
- Helper text display
- Modern shadows (softer, larger blur)
- Improved typography (12.5px, letter spacing)

#### Updated `bottom_nav_drawer.dart`
**New 4-Tab Navigation:**
1. **Accueil** (Home) - with home icon
2. **Messages** - with badge support (3 unread)
3. **Notifications** - with badge support (1 new)
4. **Profil** - navigates to profile

**Removed:**
- Logout button (moved to Profile)
- Settings button
- Contact button
- About button

### 7. Courses Feature Screens

#### `courses_screen.dart`
**Features:**
- Search bar (real-time filtering)
- Filter panel (toggle-able):
  - Subject dropdown
  - Teacher dropdown
  - "With attachments only" checkbox
  - Sort by: Date/Title
- Active filter chips (removable)
- Course cards with:
  - Subject badge
  - Date published
  - Title + description preview
  - Teacher name
  - Attachment count badge
- Empty state
- Error handling with retry
- Pull-to-refresh support

#### `course_detail_screen.dart`
**Features:**
- Gradient SliverAppBar with book icon overlay
- Header card:
  - Course title (large)
  - Teacher info with avatar icon
  - Published date
- Description section (if available)
- External link button (if provided)
- Attachments section:
  - **Image attachments**: Grid of thumbnails (tap to view)
  - **Document attachments**: List tiles with:
    - Icon based on file type (PDF, Document, etc.)
    - File name
    - File size + extension
    - Download button
- Auto-marks course as viewed on open
- Error handling

### 8. Profile Screen Updates

#### `profile_screen.dart`
Added **Settings Section** at bottom:
- Settings (navigates to /settings)
- Contact Us (navigates to /contact)
- About (navigates to /about)
- **Logout** (shows confirmation dialog)

**Logout Dialog:**
- Modern styled with icon
- Red destructive button
- Confirmation required

### 9. Router Updates

#### `app_router.dart`
- Changed initial route from `/login` to `/`
- Added courses routes:
  ```dart
  /courses → CoursesScreen
  /courses/:courseId → CourseDetailScreen
  ```
- Removed `/mon-groupe` route
- Updated home route to `/` instead of `/home`

### 10. Localization

#### Updated `app_localizations.dart`
Added missing keys:
- `home`: 'Home' (EN), 'Accueil' (FR)
- `notifications`: 'Notifications' (EN/FR)
- `profile`: 'Profile' (EN), 'Profil' (FR)

## File Structure

```
studentportal01/
├── lib/
│   ├── core/
│   │   ├── router/
│   │   │   └── app_router.dart (updated)
│   │   ├── theme/
│   │   │   └── app_theme.dart (updated)
│   │   └── l10n/
│   │       └── app_localizations.dart (updated)
│   ├── data/
│   │   ├── models/
│   │   │   └── course_model.dart (NEW)
│   │   └── repositories/
│   │       └── course_repository.dart (NEW)
│   └── presentation/
│       ├── providers/
│       │   └── course_provider.dart (NEW)
│       ├── screens/
│       │   ├── home/
│       │   │   └── home_screen.dart (redesigned)
│       │   ├── profile/
│       │   │   └── profile_screen.dart (updated)
│       │   └── courses/
│       │       ├── courses_screen.dart (NEW)
│       │       └── course_detail_screen.dart (NEW)
│       └── widgets/
│           ├── menu_tile.dart (enhanced)
│           └── bottom_nav_drawer.dart (redesigned)
└── supabase/
    └── migrations/
        ├── 07_create_courses_tables.sql (NEW)
        └── 08_create_courses_storage.sql (NEW)
```

## Dependencies Required

Make sure these packages are in your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.0
  go_router: ^13.0.0
  supabase_flutter: ^2.0.0
  intl: ^0.19.0
  google_fonts: ^6.1.0
  url_launcher: ^6.2.0  # For opening attachments and external links
```

## Setup Instructions

### 1. Database Setup
Run the SQL migrations in your Supabase project:
```bash
# In Supabase Dashboard SQL Editor
1. Run 07_create_courses_tables.sql
2. Run 08_create_courses_storage.sql
3. Create storage bucket "courses" (if not done via SQL)
```

### 2. Storage Bucket
Create the `courses` bucket in Supabase Storage:
- Name: **courses**
- Public: **No** (private)
- Policies will be applied via migration

### 3. Install Dependencies
```bash
cd studentportal01
flutter pub get
```

### 4. Run the App
```bash
flutter run
```

## Key Features

### Modern UI/UX
✅ Gradient headers with smooth transitions
✅ Soft shadows (24px blur, 8% opacity)
✅ Rounded corners (18-22px radius)
✅ Clean typography (Poppins font)
✅ Consistent spacing
✅ Badge notifications
✅ Micro-animations

### Courses Module
✅ Full CRUD operations (admin/teacher)
✅ Student read access with RLS
✅ Search and advanced filtering
✅ Multiple file attachments
✅ Image thumbnails
✅ Document downloads
✅ External links support
✅ View tracking
✅ Subject and teacher filtering

### Navigation
✅ 4-tab bottom navigation
✅ Logout moved to Profile
✅ Clean hierarchy
✅ Badge notifications on tabs
✅ Smooth transitions

### Performance
✅ No heavy animations
✅ Lightweight transitions
✅ Efficient state management
✅ Lazy loading
✅ Image caching

## Testing Checklist

- [ ] Database migrations run successfully
- [ ] Storage bucket created and accessible
- [ ] Courses list loads with filters
- [ ] Course detail shows all information
- [ ] Attachments download properly
- [ ] Images display as thumbnails
- [ ] Search works in real-time
- [ ] Filters apply correctly
- [ ] View tracking works
- [ ] Home screen displays 9 tiles in 3×3 grid
- [ ] Bottom navigation has 4 tabs
- [ ] Logout works from Profile screen
- [ ] Gradient headers display correctly
- [ ] Badges show on tiles and nav items

## Future Enhancements

- [ ] Offline support for courses
- [ ] Push notifications for new courses
- [ ] Course favorites/bookmarks
- [ ] Comments on courses
- [ ] Course completion tracking
- [ ] PDF viewer inline
- [ ] Image gallery viewer
- [ ] Dark mode optimization

## Notes

- All UI text in French (matching existing app)
- Code variables in English (best practice)
- RLS ensures students only see their class/group courses
- Teachers can publish to specific groups or entire class
- File upload limits should be configured in Supabase
- Consider adding course categories/tags for better organization
- Badge counts are currently hardcoded examples - connect to real data

## Support

For issues or questions, refer to:
- Supabase Documentation: https://supabase.com/docs
- Flutter Documentation: https://flutter.dev/docs
- Riverpod Documentation: https://riverpod.dev
