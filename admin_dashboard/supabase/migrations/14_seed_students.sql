-- ============================================================================
-- STUDENT SEEDING - 10 students per class = 440 students total
-- Run this AFTER the main academic fix script
-- ============================================================================

DO $$
DECLARE
    v_school_id UUID;
    v_academic_year_id UUID;
    v_class RECORD;
    v_student_num INT;
    v_student_counter INT := 0;
    v_user_id UUID;
    v_email TEXT;
    v_full_name TEXT;
    v_first_names TEXT[] := ARRAY[
        'Ahmed', 'Mohamed', 'Youssef', 'Ali', 'Omar', 'Khalil', 'Hamza', 'Amine', 'Sami', 'Rami',
        'Fatma', 'Mariem', 'Ines', 'Sarah', 'Nour', 'Amira', 'Rania', 'Hiba', 'Yasmine', 'Salma',
        'Bilel', 'Nabil', 'Karim', 'Tarek', 'Slim', 'Hichem', 'Zied', 'Fathi', 'Mehdi', 'Chokri',
        'Rim', 'Sana', 'Wafa', 'Olfa', 'Houda', 'Nejla', 'Asma', 'Ines', 'Marwa', 'Ameni'
    ];
    v_last_names TEXT[] := ARRAY[
        'Ben Ali', 'Trabelsi', 'Bouzid', 'Hammami', 'Jebali', 'Chaari', 'Miled', 'Rezgui', 'Sassi', 'Kallel',
        'Mansouri', 'Gharbi', 'Dridi', 'Zouari', 'Mejri', 'Belhaj', 'Fehri', 'Jaziri', 'Tlili', 'Gueddiche',
        'Bouaziz', 'Messaoudi', 'Khalfaoui', 'Amri', 'Bouzguenda', 'Ben Salah', 'Guesmi', 'Ben Salem', 'Khelifi', 'Brahmi'
    ];
    v_first_name TEXT;
    v_last_name TEXT;
    v_count INT;
    v_existing_id UUID;
BEGIN
    -- Get school and academic year
    SELECT id INTO v_school_id FROM schools LIMIT 1;
    SELECT id INTO v_academic_year_id FROM academic_years 
    WHERE school_id = v_school_id AND is_current = true LIMIT 1;
    
    IF v_school_id IS NULL THEN
        RAISE EXCEPTION 'No school found!';
    END IF;
    
    RAISE NOTICE 'Creating students for school: %', v_school_id;
    RAISE NOTICE 'Academic year: %', v_academic_year_id;
    
    -- Clean up existing student data first
    RAISE NOTICE 'Cleaning up existing students...';
    
    -- Delete enrollments for existing students
    DELETE FROM enrollments WHERE user_id IN (
        SELECT id FROM users WHERE school_id = v_school_id AND role = 'student'
    );
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Deleted % enrollments', v_count;
    
    -- Delete from users table
    DELETE FROM users WHERE school_id = v_school_id AND role = 'student';
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Deleted % user profiles', v_count;
    
    -- Delete from auth.users (students only - by email pattern)
    DELETE FROM auth.users WHERE email LIKE '%@student.pythaone.tn';
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Deleted % auth users', v_count;
    
    -- Loop through each class
    FOR v_class IN SELECT id, name FROM classes WHERE school_id = v_school_id ORDER BY name
    LOOP
        RAISE NOTICE 'Creating 10 students for class: %', v_class.name;
        
        -- Create 10 students per class
        FOR v_student_num IN 1..10 LOOP
            v_student_counter := v_student_counter + 1;
            
            -- Pick random names
            v_first_name := v_first_names[1 + (v_student_counter % array_length(v_first_names, 1))];
            v_last_name := v_last_names[1 + ((v_student_counter / 10) % array_length(v_last_names, 1))];
            v_full_name := v_first_name || ' ' || v_last_name;
            
            -- Create unique email
            v_email := lower(replace(v_first_name, ' ', '')) || '.' || 
                       lower(replace(v_last_name, ' ', '')) || 
                       v_student_counter || '@student.pythaone.tn';
            
            -- Generate UUID
            v_user_id := gen_random_uuid();
            
            -- Insert into auth.users
            INSERT INTO auth.users (
                id,
                instance_id,
                email,
                encrypted_password,
                email_confirmed_at,
                raw_app_meta_data,
                raw_user_meta_data,
                created_at,
                updated_at,
                aud,
                role
            ) VALUES (
                v_user_id,
                '00000000-0000-0000-0000-000000000000',
                v_email,
                crypt('Student123!', gen_salt('bf')),
                now(),
                '{"provider": "email", "providers": ["email"]}'::jsonb,
                jsonb_build_object('full_name', v_full_name),
                now(),
                now(),
                'authenticated',
                'authenticated'
            );
            
            -- Insert into users table
            INSERT INTO users (id, school_id, email, full_name, role, phone, date_of_birth, address)
            VALUES (
                v_user_id,
                v_school_id,
                v_email,
                v_full_name,
                'student',
                '+216 ' || (20000000 + v_student_counter)::TEXT,
                ('2008-01-01'::DATE + (v_student_counter % 365))::DATE,
                'Tunisia'
            );
            
            -- Create enrollment
            INSERT INTO enrollments (id, user_id, class_id)
            VALUES (gen_random_uuid(), v_user_id, v_class.id);
            
        END LOOP;
    END LOOP;
    
    -- Summary
    SELECT COUNT(*) INTO v_count FROM users WHERE school_id = v_school_id AND role = 'student';
    RAISE NOTICE '=== COMPLETE ===';
    RAISE NOTICE 'Total students created: %', v_count;
    
    SELECT COUNT(*) INTO v_count FROM enrollments;
    RAISE NOTICE 'Total enrollments: %', v_count;
END $$;

-- Verify counts
SELECT 'Students' AS entity, COUNT(*) AS count FROM users WHERE role = 'student'
UNION ALL
SELECT 'Enrollments', COUNT(*) FROM enrollments
UNION ALL
SELECT 'Classes', COUNT(*) FROM classes;
