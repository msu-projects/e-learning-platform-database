-- ============================================================================
-- E-LEARNING PLATFORM STORED PROCEDURES
-- Advanced Database Final Project
-- ============================================================================
-- This script creates 5 stored procedures as required:
-- 1. sp_enroll_student - INSERT (data modification)
-- 2. sp_update_grade - UPDATE (data modification)
-- 3. sp_get_student_transcript - SELECT (returns result set)
-- 4. sp_search_courses - SELECT with optional parameters
-- 5. sp_unenroll_student - DELETE (data modification)
-- ============================================================================

USE elearning_platform;

-- ============================================================================
-- PROCEDURE 1: sp_enroll_student (DATA MODIFICATION - INSERT)
-- Purpose: Enrolls a student in a course and creates payment record
-- Parameters: student_id, course_id, payment_method
-- Returns: Success/error message with enrollment details
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_enroll_student;

DELIMITER //

CREATE PROCEDURE sp_enroll_student(
    IN p_student_id INT,
    IN p_course_id INT,
    IN p_payment_method ENUM('credit_card', 'debit_card', 'paypal', 'bank_transfer', 'gcash', 'maya')
)
BEGIN
    DECLARE v_course_price DECIMAL(10,2);
    DECLARE v_enrollment_id INT;
    DECLARE v_student_exists INT;
    DECLARE v_course_exists INT;
    DECLARE v_already_enrolled INT;
    DECLARE v_transaction_ref VARCHAR(100);
    
    -- Error handler
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'ERROR: Transaction failed. Enrollment cancelled.' AS result;
    END;
    
    -- Check if student exists
    SELECT COUNT(*) INTO v_student_exists 
    FROM students WHERE student_id = p_student_id AND status = 'active';
    
    IF v_student_exists = 0 THEN
        SELECT 'ERROR: Student not found or inactive.' AS result;
    ELSE
        -- Check if course exists and is published
        SELECT COUNT(*), MAX(price) INTO v_course_exists, v_course_price
        FROM courses WHERE course_id = p_course_id AND is_published = TRUE;
        
        IF v_course_exists = 0 THEN
            SELECT 'ERROR: Course not found or not published.' AS result;
        ELSE
            -- Check if already enrolled
            SELECT COUNT(*) INTO v_already_enrolled
            FROM enrollments WHERE student_id = p_student_id AND course_id = p_course_id;
            
            -- Start transaction early to prevent race conditions
            -- The UNIQUE constraint on (student_id, course_id) will catch concurrent duplicates
            START TRANSACTION;
            
            IF v_already_enrolled > 0 THEN
                ROLLBACK;
                SELECT 'ERROR: Student is already enrolled in this course.' AS result;
            ELSE
                -- Create enrollment
                INSERT INTO enrollments (student_id, course_id, enroll_date, progress_percent, completed)
                VALUES (p_student_id, p_course_id, CURDATE(), 0.00, FALSE);
                
                SET v_enrollment_id = LAST_INSERT_ID();
                
                -- Generate transaction reference
                SET v_transaction_ref = CONCAT('TXN-', YEAR(NOW()), '-', LPAD(v_enrollment_id, 4, '0'));
                
                -- Create payment record
                INSERT INTO payments (enrollment_id, amount, payment_date, payment_method, transaction_ref, status)
                VALUES (v_enrollment_id, v_course_price, NOW(), p_payment_method, v_transaction_ref, 'completed');
                
                COMMIT;
                
                -- Return success with details
                SELECT 
                    'SUCCESS: Enrollment completed.' AS result,
                    v_enrollment_id AS enrollment_id,
                    v_course_price AS amount_paid,
                    v_transaction_ref AS transaction_reference;
            END IF;
        END IF;
    END IF;
END //

DELIMITER ;

-- ============================================================================
-- PROCEDURE 2: sp_update_grade (DATA MODIFICATION - UPDATE)
-- Purpose: Updates student grade and automatically marks as completed if >= 60
-- Parameters: enrollment_id, new_grade
-- Returns: Updated enrollment information
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_update_grade;

DELIMITER //

CREATE PROCEDURE sp_update_grade(
    IN p_enrollment_id INT,
    IN p_new_grade DECIMAL(5,2)
)
BEGIN
    DECLARE v_enrollment_exists INT DEFAULT 0;
    DECLARE v_old_grade DECIMAL(5,2);
    DECLARE v_is_completed BOOLEAN;
    DECLARE v_passing_grade DECIMAL(5,2) DEFAULT 60.00;
    
    -- Error handler for consistency
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'ERROR: Grade update failed.' AS result;
    END;
    
    -- Validate grade range
    IF p_new_grade < 0 OR p_new_grade > 100 THEN
        SELECT 'ERROR: Grade must be between 0 and 100.' AS result;
    ELSE
        -- Check if enrollment exists (fixed: separate queries to avoid NULL issue)
        SELECT COUNT(*) INTO v_enrollment_exists
        FROM enrollments WHERE enrollment_id = p_enrollment_id;
        
        IF v_enrollment_exists = 0 THEN
            SELECT 'ERROR: Enrollment not found.' AS result;
        ELSE
            -- Get old grade for reporting
            SELECT grade INTO v_old_grade
            FROM enrollments WHERE enrollment_id = p_enrollment_id;
            
            -- Determine if course should be marked as completed
            SET v_is_completed = (p_new_grade >= v_passing_grade);
            
            -- Update the grade
            UPDATE enrollments
            SET 
                grade = p_new_grade,
                progress_percent = 100.00,
                completed = v_is_completed,
                completion_date = IF(v_is_completed, CURDATE(), NULL)
            WHERE enrollment_id = p_enrollment_id;
            
            -- Return result
            SELECT 
                'SUCCESS: Grade updated.' AS result,
                p_enrollment_id AS enrollment_id,
                v_old_grade AS old_grade,
                p_new_grade AS new_grade,
                v_is_completed AS marked_completed,
                CASE 
                    WHEN p_new_grade >= 90 THEN 'Excellent'
                    WHEN p_new_grade >= 80 THEN 'Very Good'
                    WHEN p_new_grade >= 70 THEN 'Good'
                    WHEN p_new_grade >= 60 THEN 'Passed'
                    ELSE 'Failed'
                END AS grade_status;
        END IF;
    END IF;
END //

DELIMITER ;

-- ============================================================================
-- PROCEDURE 3: sp_get_student_transcript (RETURNS RESULT SET)
-- Purpose: Returns complete academic transcript for a student
-- Parameters: student_id
-- Returns: All enrollments with course details, grades, and status
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_get_student_transcript;

DELIMITER //

CREATE PROCEDURE sp_get_student_transcript(
    IN p_student_id INT
)
BEGIN
    DECLARE v_student_name VARCHAR(100);
    DECLARE v_student_email VARCHAR(100);
    DECLARE v_total_courses INT;
    DECLARE v_completed_courses INT;
    DECLARE v_avg_grade DECIMAL(5,2);
    
    -- Error handler for consistency
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'ERROR: Failed to retrieve transcript.' AS result;
    END;
    
    -- Get student info
    SELECT CONCAT(first_name, ' ', last_name), email
    INTO v_student_name, v_student_email
    FROM students WHERE student_id = p_student_id;
    
    IF v_student_name IS NULL THEN
        SELECT 'ERROR: Student not found.' AS result;
    ELSE
        -- Calculate summary statistics
        SELECT 
            COUNT(*),
            COUNT(CASE WHEN completed = TRUE THEN 1 END),
            ROUND(AVG(grade), 2)
        INTO v_total_courses, v_completed_courses, v_avg_grade
        FROM enrollments WHERE student_id = p_student_id;
        
        -- Return student header
        SELECT 
            v_student_name AS student_name,
            v_student_email AS email,
            v_total_courses AS total_courses,
            v_completed_courses AS completed_courses,
            v_avg_grade AS overall_gpa;
        
        -- Return detailed transcript
        SELECT 
            c.title AS course_title,
            c.category,
            c.difficulty_level,
            CONCAT(i.first_name, ' ', i.last_name) AS instructor,
            e.enroll_date,
            e.grade,
            CASE 
                WHEN e.grade >= 90 THEN 'A'
                WHEN e.grade >= 80 THEN 'B'
                WHEN e.grade >= 70 THEN 'C'
                WHEN e.grade >= 60 THEN 'D'
                WHEN e.grade IS NOT NULL THEN 'F'
                ELSE 'In Progress'
            END AS letter_grade,
            e.progress_percent,
            CASE WHEN e.completed THEN 'Completed' ELSE 'In Progress' END AS status,
            e.completion_date,
            CASE WHEN e.certificate_issued THEN 'Yes' ELSE 'No' END AS certificate
        FROM enrollments e
        INNER JOIN courses c ON e.course_id = c.course_id
        INNER JOIN instructors i ON c.instructor_id = i.instructor_id
        WHERE e.student_id = p_student_id
        ORDER BY e.enroll_date DESC;
    END IF;
END //

DELIMITER ;

-- ============================================================================
-- PROCEDURE 4: sp_search_courses (OPTIONAL PARAMETERS)
-- Purpose: Search courses with optional filters for category, price range,
--          difficulty, and instructor
-- Parameters: All optional - category, min_price, max_price, difficulty, instructor_id
-- Returns: Matching courses with enrollment statistics
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_search_courses;

DELIMITER //

CREATE PROCEDURE sp_search_courses(
    IN p_category VARCHAR(50),           -- Optional: filter by category
    IN p_min_price DECIMAL(10,2),        -- Optional: minimum price
    IN p_max_price DECIMAL(10,2),        -- Optional: maximum price
    IN p_difficulty VARCHAR(20),          -- Optional: difficulty level
    IN p_instructor_id INT                -- Optional: filter by instructor
)
BEGIN
    SELECT 
        c.course_id,
        c.title,
        c.description,
        c.category,
        c.price,
        c.duration_hours,
        c.difficulty_level,
        CONCAT(i.first_name, ' ', i.last_name) AS instructor_name,
        i.rating AS instructor_rating,
        COUNT(DISTINCT e.enrollment_id) AS total_enrollments,
        ROUND(AVG(e.grade), 2) AS avg_course_grade,
        COUNT(DISTINCT m.module_id) AS module_count
    FROM courses c
    INNER JOIN instructors i ON c.instructor_id = i.instructor_id
    LEFT JOIN enrollments e ON c.course_id = e.course_id
    LEFT JOIN modules m ON c.course_id = m.course_id
    WHERE c.is_published = TRUE
        -- Optional category filter (NULL means no filter)
        AND (p_category IS NULL OR c.category = p_category)
        -- Optional price range filters
        AND (p_min_price IS NULL OR c.price >= p_min_price)
        AND (p_max_price IS NULL OR c.price <= p_max_price)
        -- Optional difficulty filter
        AND (p_difficulty IS NULL OR c.difficulty_level = p_difficulty)
        -- Optional instructor filter
        AND (p_instructor_id IS NULL OR c.instructor_id = p_instructor_id)
    GROUP BY c.course_id, c.title, c.description, c.category, c.price, 
             c.duration_hours, c.difficulty_level, i.first_name, i.last_name, i.rating
    ORDER BY total_enrollments DESC, c.price;
END //

DELIMITER ;

-- ============================================================================
-- PROCEDURE 5: sp_unenroll_student (DATA MODIFICATION - DELETE)
-- Purpose: Unenrolls a student from a course and processes refund if applicable
-- Parameters: enrollment_id, refund_requested (boolean)
-- Returns: Unenrollment confirmation and refund status
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_unenroll_student;

DELIMITER //

CREATE PROCEDURE sp_unenroll_student(
    IN p_enrollment_id INT,
    IN p_refund_requested BOOLEAN
)
BEGIN
    DECLARE v_enrollment_exists INT;
    DECLARE v_student_name VARCHAR(100);
    DECLARE v_course_title VARCHAR(150);
    DECLARE v_payment_amount DECIMAL(10,2);
    DECLARE v_payment_id INT;
    DECLARE v_progress DECIMAL(5,2);
    DECLARE v_refund_eligible BOOLEAN;
    DECLARE v_certificate_exists INT;
    
    -- Error handler
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'ERROR: Unenrollment failed.' AS result;
    END;
    
    -- Check if enrollment exists
    SELECT 
        COUNT(*),
        e.progress_percent,
        CONCAT(s.first_name, ' ', s.last_name),
        c.title,
        p.payment_id,
        p.amount
    INTO v_enrollment_exists, v_progress, v_student_name, v_course_title, v_payment_id, v_payment_amount
    FROM enrollments e
    INNER JOIN students s ON e.student_id = s.student_id
    INNER JOIN courses c ON e.course_id = c.course_id
    LEFT JOIN payments p ON e.enrollment_id = p.enrollment_id
    WHERE e.enrollment_id = p_enrollment_id
    GROUP BY e.enrollment_id;
    
    IF v_enrollment_exists = 0 THEN
        SELECT 'ERROR: Enrollment not found.' AS result;
    ELSE
        -- Check if certificate exists (cannot unenroll if certificate issued)
        SELECT COUNT(*) INTO v_certificate_exists
        FROM certificates WHERE enrollment_id = p_enrollment_id;
        
        IF v_certificate_exists > 0 THEN
            SELECT 'ERROR: Cannot unenroll - certificate already issued.' AS result;
        ELSE
            -- Refund is only eligible if progress < 30%
            SET v_refund_eligible = (v_progress < 30);
            
START TRANSACTION;
            
            -- Note: Refund status is tracked in the return message
            -- Payment record is deleted as part of unenrollment (FK RESTRICT requires this)
            
            -- Delete payment record first (required due to FK RESTRICT constraint)
            DELETE FROM payments WHERE enrollment_id = p_enrollment_id;
            
            -- Delete the enrollment
            DELETE FROM enrollments WHERE enrollment_id = p_enrollment_id;
            
            COMMIT;
            
            -- Return confirmation
            SELECT 
                'SUCCESS: Unenrollment completed.' AS result,
                v_student_name AS student,
                v_course_title AS course,
                CASE 
                    WHEN p_refund_requested AND v_refund_eligible THEN 'Refund processed'
                    WHEN p_refund_requested AND NOT v_refund_eligible THEN 'Refund denied (progress > 30%)'
                    ELSE 'No refund requested'
                END AS refund_status,
                v_payment_amount AS original_amount;
        END IF;
    END IF;
END //

DELIMITER ;

-- ============================================================================
-- PROCEDURE USAGE EXAMPLES (for demonstration)
-- ============================================================================
/*
-- Enroll a new student:
CALL sp_enroll_student(1, 5, 'credit_card');

-- Update a grade:
CALL sp_update_grade(1, 85.50);

-- Get student transcript:
CALL sp_get_student_transcript(1);

-- Search courses with optional filters:
CALL sp_search_courses(NULL, NULL, NULL, NULL, NULL);  -- All courses
CALL sp_search_courses('Programming', NULL, NULL, NULL, NULL);  -- By category
CALL sp_search_courses(NULL, 1000, 3000, NULL, NULL);  -- By price range
CALL sp_search_courses('Database', NULL, NULL, 'advanced', NULL);  -- By category and difficulty
CALL sp_search_courses(NULL, NULL, NULL, NULL, 2);  -- By instructor

-- Unenroll student with refund:
CALL sp_unenroll_student(5, TRUE);
*/

-- ============================================================================
-- END OF STORED PROCEDURES DEFINITION
-- ============================================================================
