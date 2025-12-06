-- ============================================================================
-- E-LEARNING PLATFORM VIEWS
-- Advanced Database Final Project
-- ============================================================================
-- This script creates 5 MySQL views as required:
-- 1. Aggregated view (GROUP BY)
-- 2. Join view (≥3 tables)
-- 3. Filtered view (WHERE)
-- 4. Computed column view
-- 5. Report-style view (analytical/summary)
-- ============================================================================

USE elearning_platform;

-- ============================================================================
-- VIEW 1: AGGREGATED VIEW (GROUP BY)
-- vw_course_enrollment_stats
-- Purpose: Shows enrollment statistics per course including count, 
--          average grade, completion rate, and total revenue
-- ============================================================================
DROP VIEW IF EXISTS vw_course_enrollment_stats;

CREATE VIEW vw_course_enrollment_stats AS
SELECT 
    c.course_id,
    c.title AS course_title,
    c.category,
    c.price,
    COUNT(e.enrollment_id) AS total_enrollments,
    COUNT(CASE WHEN e.completed = TRUE THEN 1 END) AS completed_count,
    ROUND(AVG(e.grade), 2) AS average_grade,
    ROUND(AVG(e.progress_percent), 2) AS average_progress,
    SUM(CASE WHEN p.status = 'completed' THEN p.amount ELSE 0 END) AS total_revenue
FROM courses c
LEFT JOIN enrollments e ON c.course_id = e.course_id
LEFT JOIN payments p ON e.enrollment_id = p.enrollment_id
GROUP BY c.course_id, c.title, c.category, c.price
ORDER BY total_enrollments DESC;

-- ============================================================================
-- VIEW 2: JOIN VIEW (≥3 TABLES)
-- vw_student_course_details
-- Purpose: Comprehensive view showing student enrollment details with
--          course and instructor information (joins 4 tables)
-- ============================================================================
DROP VIEW IF EXISTS vw_student_course_details;

CREATE VIEW vw_student_course_details AS
SELECT 
    s.student_id,
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    s.email AS student_email,
    s.status AS student_status,
    c.course_id,
    c.title AS course_title,
    c.category,
    c.difficulty_level,
    CONCAT(i.first_name, ' ', i.last_name) AS instructor_name,
    i.rating AS instructor_rating,
    e.enroll_date,
    e.grade,
    e.progress_percent,
    e.completed,
    e.completion_date
FROM students s
INNER JOIN enrollments e ON s.student_id = e.student_id
INNER JOIN courses c ON e.course_id = c.course_id
INNER JOIN instructors i ON c.instructor_id = i.instructor_id
ORDER BY s.student_id, e.enroll_date;

-- ============================================================================
-- VIEW 3: FILTERED VIEW (WHERE)
-- vw_active_premium_students
-- Purpose: Shows active students enrolled in premium courses (price > 2500)
--          Used for targeted marketing and premium support identification
-- ============================================================================
DROP VIEW IF EXISTS vw_active_premium_students;

CREATE VIEW vw_active_premium_students AS
SELECT 
    s.student_id,
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    s.email,
    s.phone,
    c.title AS premium_course,
    c.price AS course_price,
    e.enroll_date,
    e.progress_percent,
    p.payment_method,
    p.status AS payment_status
FROM students s
INNER JOIN enrollments e ON s.student_id = e.student_id
INNER JOIN courses c ON e.course_id = c.course_id
INNER JOIN payments p ON e.enrollment_id = p.enrollment_id
WHERE s.status = 'active'
  AND c.price > 2500.00
  AND p.status = 'completed'
ORDER BY c.price DESC, e.enroll_date;

-- ============================================================================
-- VIEW 4: COMPUTED COLUMN VIEW
-- vw_instructor_performance
-- Purpose: Shows instructor performance metrics with computed earnings
--          (70% of course revenue goes to instructor)
-- ============================================================================
DROP VIEW IF EXISTS vw_instructor_performance;

CREATE VIEW vw_instructor_performance AS
SELECT 
    i.instructor_id,
    CONCAT(i.first_name, ' ', i.last_name) AS instructor_name,
    i.email,
    i.specialty,
    i.rating,
    COUNT(DISTINCT c.course_id) AS courses_created,
    COUNT(DISTINCT e.enrollment_id) AS total_students,
    SUM(CASE WHEN p.status = 'completed' THEN p.amount ELSE 0 END) AS gross_revenue,
    -- Computed column: instructor earnings (70% of revenue)
    ROUND(SUM(CASE WHEN p.status = 'completed' THEN p.amount ELSE 0 END) * 0.70, 2) AS instructor_earnings,
    -- Computed column: platform fee (30% of revenue)
    ROUND(SUM(CASE WHEN p.status = 'completed' THEN p.amount ELSE 0 END) * 0.30, 2) AS platform_fee,
    -- Computed column: average revenue per student
    ROUND(
        SUM(CASE WHEN p.status = 'completed' THEN p.amount ELSE 0 END) / 
        NULLIF(COUNT(DISTINCT e.enrollment_id), 0), 
        2
    ) AS avg_revenue_per_student
FROM instructors i
LEFT JOIN courses c ON i.instructor_id = c.instructor_id
LEFT JOIN enrollments e ON c.course_id = e.course_id
LEFT JOIN payments p ON e.enrollment_id = p.enrollment_id
GROUP BY i.instructor_id, i.first_name, i.last_name, i.email, i.specialty, i.rating
ORDER BY instructor_earnings DESC;

-- ============================================================================
-- VIEW 5: REPORT-STYLE VIEW (ANALYTICAL/SUMMARY)
-- vw_monthly_revenue_report
-- Purpose: Month-by-month revenue analysis with cumulative totals,
--          enrollment counts, and year-over-year comparison data
-- ============================================================================
DROP VIEW IF EXISTS vw_monthly_revenue_report;

CREATE VIEW vw_monthly_revenue_report AS
SELECT 
    YEAR(p.payment_date) AS revenue_year,
    MONTH(p.payment_date) AS revenue_month,
    MONTHNAME(p.payment_date) AS month_name,
    COUNT(DISTINCT e.enrollment_id) AS new_enrollments,
    COUNT(DISTINCT e.student_id) AS unique_students,
    COUNT(CASE WHEN p.status = 'completed' THEN 1 END) AS successful_payments,
    COUNT(CASE WHEN p.status = 'refunded' THEN 1 END) AS refunded_payments,
    SUM(CASE WHEN p.status = 'completed' THEN p.amount ELSE 0 END) AS monthly_revenue,
    SUM(CASE WHEN p.status = 'refunded' THEN p.amount ELSE 0 END) AS refunded_amount,
    -- Computed: Net revenue after refunds
    SUM(CASE WHEN p.status = 'completed' THEN p.amount ELSE 0 END) - 
    SUM(CASE WHEN p.status = 'refunded' THEN p.amount ELSE 0 END) AS net_revenue,
    -- Computed: Average transaction value
    ROUND(
        SUM(CASE WHEN p.status = 'completed' THEN p.amount ELSE 0 END) / 
        NULLIF(COUNT(CASE WHEN p.status = 'completed' THEN 1 END), 0),
        2
    ) AS avg_transaction_value
FROM enrollments e
INNER JOIN payments p ON e.enrollment_id = p.enrollment_id
GROUP BY YEAR(p.payment_date), MONTH(p.payment_date), MONTHNAME(p.payment_date)
ORDER BY revenue_year, revenue_month;

-- ============================================================================
-- VIEW USAGE EXAMPLES (for demonstration)
-- ============================================================================
/*
-- Query aggregated view:
SELECT * FROM vw_course_enrollment_stats;

-- Query join view for specific student:
SELECT * FROM vw_student_course_details WHERE student_id = 1;

-- Query filtered view:
SELECT * FROM vw_active_premium_students;

-- Query computed column view:
SELECT instructor_name, instructor_earnings, platform_fee 
FROM vw_instructor_performance;

-- Query report view:
SELECT month_name, monthly_revenue, net_revenue 
FROM vw_monthly_revenue_report 
WHERE revenue_year = 2023;
*/

-- ============================================================================
-- END OF VIEWS DEFINITION
-- ============================================================================
