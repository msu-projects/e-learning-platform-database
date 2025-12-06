-- ============================================================================
-- E-LEARNING PLATFORM USER-DEFINED FUNCTIONS (UDFs)
-- Advanced Database Final Project
-- ============================================================================
-- This script creates 5 UDFs as required:
-- 1. fn_letter_grade - Converts numeric grade to letter grade
-- 2. fn_course_completion_rate - Calculates completion percentage
-- 3. fn_student_gpa - Calculates weighted GPA for a student
-- 4. fn_instructor_revenue - Calculates total instructor revenue
-- 5. fn_days_since_enrollment - Calculates days since enrollment
-- ============================================================================

USE elearning_platform;

-- ============================================================================
-- FUNCTION 1: fn_letter_grade
-- Purpose: Converts numeric grade (0-100) to letter grade (A, B, C, D, F)
-- Usage: Used in SELECTs and views for displaying grade information
-- ============================================================================
DROP FUNCTION IF EXISTS fn_letter_grade;

DELIMITER //

CREATE FUNCTION fn_letter_grade(p_score DECIMAL(5,2))
RETURNS VARCHAR(2)
DETERMINISTIC
BEGIN
    DECLARE v_letter VARCHAR(2);
    
    IF p_score IS NULL THEN
        SET v_letter = 'IP';  -- In Progress
    ELSEIF p_score >= 97 THEN
        SET v_letter = 'A+';
    ELSEIF p_score >= 93 THEN
        SET v_letter = 'A';
    ELSEIF p_score >= 90 THEN
        SET v_letter = 'A-';
    ELSEIF p_score >= 87 THEN
        SET v_letter = 'B+';
    ELSEIF p_score >= 83 THEN
        SET v_letter = 'B';
    ELSEIF p_score >= 80 THEN
        SET v_letter = 'B-';
    ELSEIF p_score >= 77 THEN
        SET v_letter = 'C+';
    ELSEIF p_score >= 73 THEN
        SET v_letter = 'C';
    ELSEIF p_score >= 70 THEN
        SET v_letter = 'C-';
    ELSEIF p_score >= 67 THEN
        SET v_letter = 'D+';
    ELSEIF p_score >= 63 THEN
        SET v_letter = 'D';
    ELSEIF p_score >= 60 THEN
        SET v_letter = 'D-';
    ELSE
        SET v_letter = 'F';
    END IF;
    
    RETURN v_letter;
END //

DELIMITER ;

-- ============================================================================
-- FUNCTION 2: fn_course_completion_rate
-- Purpose: Calculates the percentage of students who completed a course
-- Usage: Used in views and reports for course performance analysis
-- ============================================================================
DROP FUNCTION IF EXISTS fn_course_completion_rate;

DELIMITER //

CREATE FUNCTION fn_course_completion_rate(p_course_id INT)
RETURNS DECIMAL(5,2)
READS SQL DATA
BEGIN
    DECLARE v_total_enrolled INT;
    DECLARE v_total_completed INT;
    DECLARE v_completion_rate DECIMAL(5,2);
    
    -- Get enrollment counts
    SELECT 
        COUNT(*),
        COUNT(CASE WHEN completed = TRUE THEN 1 END)
    INTO v_total_enrolled, v_total_completed
    FROM enrollments
    WHERE course_id = p_course_id;
    
    -- Calculate rate (avoid division by zero)
    IF v_total_enrolled = 0 THEN
        SET v_completion_rate = 0.00;
    ELSE
        SET v_completion_rate = ROUND((v_total_completed / v_total_enrolled) * 100, 2);
    END IF;
    
    RETURN v_completion_rate;
END //

DELIMITER ;

-- ============================================================================
-- FUNCTION 3: fn_student_gpa
-- Purpose: Calculates weighted GPA for a student on a 4.0 scale
-- Usage: Used in student transcript and academic reports
-- Note: Only considers completed courses with grades
-- ============================================================================
DROP FUNCTION IF EXISTS fn_student_gpa;

DELIMITER //

CREATE FUNCTION fn_student_gpa(p_student_id INT)
RETURNS DECIMAL(3,2)
READS SQL DATA
BEGIN
    DECLARE v_total_points DECIMAL(10,2);
    DECLARE v_total_courses INT;
    DECLARE v_gpa DECIMAL(3,2);
    
    -- Calculate weighted GPA based on numeric grades
    -- Converting percentage to 4.0 scale with finer granularity (12+ tiers)
    -- Matches standard US GPA scale: A+=4.0, A=4.0, A-=3.7, B+=3.3, etc.
    SELECT 
        SUM(
            CASE 
                WHEN grade >= 97 THEN 4.0   -- A+
                WHEN grade >= 93 THEN 4.0   -- A
                WHEN grade >= 90 THEN 3.7   -- A-
                WHEN grade >= 87 THEN 3.3   -- B+
                WHEN grade >= 83 THEN 3.0   -- B
                WHEN grade >= 80 THEN 2.7   -- B-
                WHEN grade >= 77 THEN 2.3   -- C+
                WHEN grade >= 73 THEN 2.0   -- C
                WHEN grade >= 70 THEN 1.7   -- C-
                WHEN grade >= 67 THEN 1.3   -- D+
                WHEN grade >= 63 THEN 1.0   -- D
                WHEN grade >= 60 THEN 0.7   -- D-
                ELSE 0.0                    -- F
            END
        ),
        COUNT(*)
    INTO v_total_points, v_total_courses
    FROM enrollments
    WHERE student_id = p_student_id
      AND grade IS NOT NULL;
    
    -- Calculate GPA (avoid division by zero)
    IF v_total_courses = 0 OR v_total_courses IS NULL THEN
        SET v_gpa = 0.00;
    ELSE
        SET v_gpa = ROUND(v_total_points / v_total_courses, 2);
    END IF;
    
    RETURN v_gpa;
END //

DELIMITER ;

-- ============================================================================
-- FUNCTION 4: fn_instructor_revenue
-- Purpose: Calculates total revenue generated by an instructor's courses
-- Usage: Used in instructor performance reports and payroll calculations
-- ============================================================================
DROP FUNCTION IF EXISTS fn_instructor_revenue;

DELIMITER //

CREATE FUNCTION fn_instructor_revenue(p_instructor_id INT)
RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
    DECLARE v_total_revenue DECIMAL(12,2);
    
    -- Sum all completed payments for instructor's courses
    SELECT COALESCE(SUM(p.amount), 0.00)
    INTO v_total_revenue
    FROM instructors i
    INNER JOIN courses c ON i.instructor_id = c.instructor_id
    INNER JOIN enrollments e ON c.course_id = e.course_id
    INNER JOIN payments p ON e.enrollment_id = p.enrollment_id
    WHERE i.instructor_id = p_instructor_id
      AND p.status = 'completed';
    
    RETURN v_total_revenue;
END //

DELIMITER ;

-- ============================================================================
-- FUNCTION 5: fn_days_since_enrollment
-- Purpose: Calculates the number of days since a student enrolled
-- Usage: Used for tracking course progress and sending reminders
-- ============================================================================
DROP FUNCTION IF EXISTS fn_days_since_enrollment;

DELIMITER //

CREATE FUNCTION fn_days_since_enrollment(p_enroll_date DATE)
RETURNS INT
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_days INT;
    
    IF p_enroll_date IS NULL THEN
        SET v_days = 0;
    ELSE
        SET v_days = DATEDIFF(CURDATE(), p_enroll_date);
        -- Ensure non-negative value
        IF v_days < 0 THEN
            SET v_days = 0;
        END IF;
    END IF;
    
    RETURN v_days;
END //

DELIMITER ;

-- ============================================================================
-- UDF USAGE EXAMPLES (for demonstration)
-- ============================================================================
/*
-- Using fn_letter_grade in a SELECT:
SELECT 
    student_id,
    course_id,
    grade,
    fn_letter_grade(grade) AS letter_grade
FROM enrollments
WHERE grade IS NOT NULL;

-- Using fn_course_completion_rate for all courses:
SELECT 
    course_id,
    title,
    fn_course_completion_rate(course_id) AS completion_rate_percent
FROM courses;

-- Using fn_student_gpa for all students:
SELECT 
    student_id,
    CONCAT(first_name, ' ', last_name) AS student_name,
    fn_student_gpa(student_id) AS gpa
FROM students;

-- Using fn_instructor_revenue for all instructors:
SELECT 
    instructor_id,
    CONCAT(first_name, ' ', last_name) AS instructor_name,
    fn_instructor_revenue(instructor_id) AS total_revenue
FROM instructors;

-- Using fn_days_since_enrollment for tracking:
SELECT 
    e.enrollment_id,
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    c.title AS course,
    e.enroll_date,
    fn_days_since_enrollment(e.enroll_date) AS days_enrolled,
    e.progress_percent
FROM enrollments e
INNER JOIN students s ON e.student_id = s.student_id
INNER JOIN courses c ON e.course_id = c.course_id
WHERE e.completed = FALSE
ORDER BY days_enrolled DESC;

-- Combining multiple UDFs in one query:
SELECT 
    e.enrollment_id,
    CONCAT(s.first_name, ' ', s.last_name) AS student,
    c.title AS course,
    e.grade,
    fn_letter_grade(e.grade) AS letter_grade,
    fn_student_gpa(s.student_id) AS student_gpa,
    fn_days_since_enrollment(e.enroll_date) AS days_enrolled,
    fn_course_completion_rate(c.course_id) AS course_completion_rate
FROM enrollments e
INNER JOIN students s ON e.student_id = s.student_id
INNER JOIN courses c ON e.course_id = c.course_id;
*/

-- ============================================================================
-- END OF USER-DEFINED FUNCTIONS
-- ============================================================================
