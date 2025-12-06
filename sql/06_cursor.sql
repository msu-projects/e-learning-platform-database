-- ============================================================================
-- E-LEARNING PLATFORM CURSOR PROCEDURE
-- Advanced Database Final Project
-- ============================================================================
-- This script implements a cursor-based stored procedure for bulk
-- certificate generation. Comments explain why a cursor is required.
-- ============================================================================

USE elearning_platform;

-- ============================================================================
-- PROCEDURE: sp_award_bulk_certificates (USES CURSOR)
-- ============================================================================
-- PURPOSE:
-- This procedure processes completed enrollments and issues certificates
-- to students who have passed their courses (grade >= 60).
-- 
-- WHY A CURSOR IS REQUIRED (NOT SET-BASED):
-- ============================================================================
-- 1. UNIQUE SERIAL NUMBER GENERATION:
--    Each certificate requires a unique serial number that follows a specific
--    format: CERT-YYYY-COURSEID-STUDENTID-SEQUENCE
--    The sequence number must be generated incrementally based on existing
--    certificates for that course, which requires checking current state
--    for EACH row being processed.
--
-- 2. PER-RECORD VALIDATION:
--    Before issuing each certificate, we must validate:
--    - Student is still active (not suspended/inactive)
--    - Payment was completed (not refunded/failed)
--    - Certificate hasn't already been issued
--    These validations may have different outcomes per row.
--
-- 3. DENORMALIZED DATA CAPTURE:
--    The certificates table stores denormalized data (student_name, 
--    instructor_name, course_title) captured AT THE TIME of issuance.
--    This requires fetching related data for each specific enrollment
--    at the moment of processing.
--
-- 4. AUDIT TRAIL LOGGING:
--    Each certificate issuance should log processing details, which
--    requires individual row processing to capture specific outcomes.
--
-- 5. CONDITIONAL PROCESSING:
--    Different enrollments may require different processing paths based
--    on their specific data, which is better handled row-by-row.
--
-- A pure set-based INSERT would not allow for:
-- - Sequential serial number generation per row
-- - Individual validation and error handling per record
-- - Conditional logic that varies by row
-- - Capturing processing results for each record
-- ============================================================================

DROP PROCEDURE IF EXISTS sp_award_bulk_certificates;

DELIMITER //

CREATE PROCEDURE sp_award_bulk_certificates()
BEGIN
    -- ========================================================================
    -- VARIABLE DECLARATIONS
    -- ========================================================================
    -- Cursor fetch variables
    DECLARE v_enrollment_id INT;
    DECLARE v_student_id INT;
    DECLARE v_course_id INT;
    DECLARE v_grade DECIMAL(5,2);
    DECLARE v_student_fname VARCHAR(50);
    DECLARE v_student_lname VARCHAR(50);
    DECLARE v_course_title VARCHAR(150);
    DECLARE v_instructor_fname VARCHAR(50);
    DECLARE v_instructor_lname VARCHAR(50);
    
    -- Processing variables
    DECLARE v_serial_number VARCHAR(50);
    DECLARE v_sequence INT;
    DECLARE v_student_status VARCHAR(20);
    DECLARE v_payment_status VARCHAR(20);
    DECLARE v_done INT DEFAULT FALSE;
    
    -- Counters for reporting
    DECLARE v_processed INT DEFAULT 0;
    DECLARE v_issued INT DEFAULT 0;
    DECLARE v_skipped INT DEFAULT 0;
    
    -- ========================================================================
    -- CURSOR DECLARATION
    -- Fetches all completed enrollments that don't have certificates yet
    -- ========================================================================
    DECLARE cert_cursor CURSOR FOR
        SELECT 
            e.enrollment_id,
            e.student_id,
            e.course_id,
            e.grade,
            s.first_name AS student_fname,
            s.last_name AS student_lname,
            c.title AS course_title,
            i.first_name AS instructor_fname,
            i.last_name AS instructor_lname
        FROM enrollments e
        INNER JOIN students s ON e.student_id = s.student_id
        INNER JOIN courses c ON e.course_id = c.course_id
        INNER JOIN instructors i ON c.instructor_id = i.instructor_id
        WHERE e.completed = TRUE
          AND e.grade >= 60  -- Passing grade required
          AND e.certificate_issued = FALSE;
    
    -- Handler for when cursor reaches end of result set
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;
    
    -- ========================================================================
    -- MAIN PROCESSING LOGIC
    -- ========================================================================
    
    -- Open the cursor
    OPEN cert_cursor;
    
    -- Start processing loop
    read_loop: LOOP
        -- Fetch next row from cursor
        FETCH cert_cursor INTO 
            v_enrollment_id, v_student_id, v_course_id, v_grade,
            v_student_fname, v_student_lname, v_course_title,
            v_instructor_fname, v_instructor_lname;
        
        -- Exit loop if no more rows
        IF v_done THEN
            LEAVE read_loop;
        END IF;
        
        -- Increment processed counter
        SET v_processed = v_processed + 1;
        
        -- ====================================================================
        -- PER-RECORD VALIDATION (Reason for cursor)
        -- Each enrollment needs individual validation checks
        -- ====================================================================
        
        -- Check student status
        SELECT status INTO v_student_status
        FROM students WHERE student_id = v_student_id;
        
        -- Check payment status
        SELECT status INTO v_payment_status
        FROM payments WHERE enrollment_id = v_enrollment_id
        LIMIT 1;
        
        -- Skip if student is not active
        IF v_student_status != 'active' THEN
            SET v_skipped = v_skipped + 1;
            ITERATE read_loop;  -- Skip to next iteration
        END IF;
        
        -- Skip if payment not completed
        IF v_payment_status != 'completed' THEN
            SET v_skipped = v_skipped + 1;
            ITERATE read_loop;
        END IF;
        
        -- ====================================================================
        -- GENERATE UNIQUE SERIAL NUMBER (Reason for cursor)
        -- Must be done sequentially per row to ensure uniqueness
        -- ====================================================================
        
        -- Get current sequence for this course
        SELECT COALESCE(MAX(
            CAST(SUBSTRING_INDEX(serial_number, '-', -1) AS UNSIGNED)
        ), 0) + 1
        INTO v_sequence
        FROM certificates
        WHERE course_id = v_course_id;
        
        -- Generate serial number: CERT-YEAR-COURSEID-STUDENTID-SEQUENCE
        SET v_serial_number = CONCAT(
            'CERT-',
            YEAR(NOW()), '-',
            LPAD(v_course_id, 3, '0'), '-',
            LPAD(v_student_id, 4, '0'), '-',
            LPAD(v_sequence, 4, '0')
        );
        
        -- ====================================================================
        -- INSERT CERTIFICATE WITH DENORMALIZED DATA (Reason for cursor)
        -- Captures data at the moment of processing for each specific row
        -- ====================================================================
        
        INSERT INTO certificates (
            enrollment_id,
            student_id,
            course_id,
            serial_number,
            issue_date,
            final_grade,
            instructor_name,
            course_title,
            student_name
        ) VALUES (
            v_enrollment_id,
            v_student_id,
            v_course_id,
            v_serial_number,
            NOW(),
            v_grade,
            CONCAT(v_instructor_fname, ' ', v_instructor_lname),
            v_course_title,
            CONCAT(v_student_fname, ' ', v_student_lname)
        );
        
        -- ====================================================================
        -- UPDATE ENROLLMENT TO MARK CERTIFICATE AS ISSUED
        -- ====================================================================
        
        UPDATE enrollments
        SET certificate_issued = TRUE
        WHERE enrollment_id = v_enrollment_id;
        
        -- Increment issued counter
        SET v_issued = v_issued + 1;
        
    END LOOP;
    
    -- Close the cursor
    CLOSE cert_cursor;
    
    -- ========================================================================
    -- RETURN PROCESSING SUMMARY
    -- ========================================================================
    SELECT 
        v_processed AS enrollments_processed,
        v_issued AS certificates_issued,
        v_skipped AS enrollments_skipped,
        CONCAT('Processed ', v_processed, ' enrollments. Issued ', v_issued, 
               ' certificates. Skipped ', v_skipped, ' due to validation.') AS summary;
    
    -- Show recently issued certificates
    SELECT 
        certificate_id,
        serial_number,
        student_name,
        course_title,
        final_grade,
        fn_letter_grade(final_grade) AS letter_grade,
        issue_date
    FROM certificates
    ORDER BY issue_date DESC
    LIMIT 10;
    
END //

DELIMITER ;

-- ============================================================================
-- ADDITIONAL CURSOR EXAMPLE: sp_calculate_instructor_bonuses
-- Purpose: Calculates and displays bonuses for instructors based on
--          their course performance (uses cursor for complex per-row logic)
-- ============================================================================

DROP PROCEDURE IF EXISTS sp_calculate_instructor_bonuses;

DELIMITER //

CREATE PROCEDURE sp_calculate_instructor_bonuses(
    IN p_bonus_rate DECIMAL(4,2)  -- Bonus rate as percentage (e.g., 5.00 for 5%)
)
BEGIN
    -- ========================================================================
    -- WHY CURSOR IS USED HERE:
    -- Each instructor's bonus calculation requires:
    -- 1. Fetching individual revenue totals
    -- 2. Applying different bonus tiers based on revenue brackets
    -- 3. Generating bonus report with progressive calculations
    -- This complex per-row logic is more readable with a cursor.
    -- ========================================================================
    
    DECLARE v_instructor_id INT;
    DECLARE v_instructor_name VARCHAR(100);
    DECLARE v_revenue DECIMAL(12,2);
    DECLARE v_bonus DECIMAL(12,2);
    DECLARE v_tier VARCHAR(20);
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_total_bonus DECIMAL(12,2) DEFAULT 0;
    
    -- Cursor for instructors with revenue
    DECLARE bonus_cursor CURSOR FOR
        SELECT 
            i.instructor_id,
            CONCAT(i.first_name, ' ', i.last_name) AS name,
            fn_instructor_revenue(i.instructor_id) AS revenue
        FROM instructors i
        WHERE fn_instructor_revenue(i.instructor_id) > 0;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;
    
    -- Create temporary table for results
    DROP TEMPORARY TABLE IF EXISTS tmp_bonus_report;
    CREATE TEMPORARY TABLE tmp_bonus_report (
        instructor_id INT,
        instructor_name VARCHAR(100),
        revenue DECIMAL(12,2),
        bonus_tier VARCHAR(20),
        bonus_amount DECIMAL(12,2)
    );
    
    OPEN bonus_cursor;
    
    bonus_loop: LOOP
        FETCH bonus_cursor INTO v_instructor_id, v_instructor_name, v_revenue;
        
        IF v_done THEN
            LEAVE bonus_loop;
        END IF;
        
        -- Calculate bonus based on revenue tier (complex per-row logic)
        IF v_revenue >= 50000 THEN
            SET v_tier = 'Platinum';
            SET v_bonus = v_revenue * (p_bonus_rate / 100) * 1.5;  -- 150% bonus rate
        ELSEIF v_revenue >= 25000 THEN
            SET v_tier = 'Gold';
            SET v_bonus = v_revenue * (p_bonus_rate / 100) * 1.25;  -- 125% bonus rate
        ELSEIF v_revenue >= 10000 THEN
            SET v_tier = 'Silver';
            SET v_bonus = v_revenue * (p_bonus_rate / 100);  -- Standard bonus rate
        ELSE
            SET v_tier = 'Bronze';
            SET v_bonus = v_revenue * (p_bonus_rate / 100) * 0.75;  -- 75% bonus rate
        END IF;
        
        -- Insert into temporary report table
        INSERT INTO tmp_bonus_report VALUES 
            (v_instructor_id, v_instructor_name, v_revenue, v_tier, ROUND(v_bonus, 2));
        
        SET v_total_bonus = v_total_bonus + v_bonus;
        
    END LOOP;
    
    CLOSE bonus_cursor;
    
    -- Return bonus report
    SELECT * FROM tmp_bonus_report ORDER BY revenue DESC;
    
    -- Return summary
    SELECT 
        CONCAT('Total bonus payout: ₱', FORMAT(v_total_bonus, 2)) AS total_bonus_payout,
        CONCAT('Bonus rate: ', p_bonus_rate, '%') AS applied_rate;
    
    DROP TEMPORARY TABLE IF EXISTS tmp_bonus_report;
    
END //

DELIMITER ;

-- ============================================================================
-- CURSOR USAGE EXAMPLES (for demonstration)
-- ============================================================================
/*
-- Award certificates to all eligible students:
CALL sp_award_bulk_certificates();

-- View issued certificates:
SELECT * FROM certificates;

-- Calculate instructor bonuses at 5% rate:
CALL sp_calculate_instructor_bonuses(5.00);

-- Calculate instructor bonuses at 10% rate:
CALL sp_calculate_instructor_bonuses(10.00);
*/

-- ============================================================================
-- END OF CURSOR PROCEDURES
-- ============================================================================
