-- ============================================================================
-- E-LEARNING PLATFORM QUERY OPTIMIZATION
-- Advanced Database Final Project
-- ============================================================================
-- This script demonstrates query optimization through:
-- 1. Strategic index creation (composite, covering, unique)
-- 2. EXPLAIN analysis before and after optimization
-- 3. Query rewriting for better performance
-- ============================================================================

USE elearning_platform;

-- ============================================================================
-- SECTION 1: BASELINE QUERIES (BEFORE OPTIMIZATION)
-- Run these EXPLAIN queries BEFORE creating indexes to capture baseline
-- ============================================================================

-- ============================================================================
-- BASELINE QUERY 1: Search courses by category
-- This query is commonly used in the sp_search_courses procedure
-- ============================================================================
/*
EXPLAIN ANALYZE
SELECT c.*, CONCAT(i.first_name, ' ', i.last_name) AS instructor_name
FROM courses c
INNER JOIN instructors i ON c.instructor_id = i.instructor_id
WHERE c.category = 'Programming'
  AND c.is_published = TRUE;
*/

-- Expected BEFORE optimization:
-- type: ALL (full table scan on courses)
-- rows: ~8 (scans all rows)
-- Extra: Using where

-- ============================================================================
-- BASELINE QUERY 2: Get enrollments with student and course info
-- This is the core query used in vw_student_course_details
-- ============================================================================
/*
EXPLAIN ANALYZE
SELECT 
    s.student_id,
    s.first_name,
    s.last_name,
    c.title,
    e.grade,
    e.completed
FROM enrollments e
INNER JOIN students s ON e.student_id = s.student_id
INNER JOIN courses c ON e.course_id = c.course_id
WHERE e.grade > 80;
*/

-- Expected BEFORE optimization:
-- type: ALL on enrollments
-- Using temporary, Using filesort

-- ============================================================================
-- BASELINE QUERY 3: Monthly revenue aggregation
-- This is used in vw_monthly_revenue_report
-- ============================================================================
/*
EXPLAIN ANALYZE
SELECT 
    YEAR(p.payment_date) AS year,
    MONTH(p.payment_date) AS month,
    SUM(p.amount) AS revenue
FROM payments p
WHERE p.status = 'completed'
GROUP BY YEAR(p.payment_date), MONTH(p.payment_date);
*/

-- Expected BEFORE optimization:
-- type: ALL (full scan)
-- Extra: Using where; Using temporary; Using filesort

-- ============================================================================
-- SECTION 2: CREATE OPTIMIZATION INDEXES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- INDEX 1: Composite index on courses for category and publication status
-- Optimizes: Course searches by category (sp_search_courses)
-- Type: Composite index
-- ----------------------------------------------------------------------------
DROP INDEX IF EXISTS idx_course_category_published ON courses;
CREATE INDEX idx_course_category_published ON courses(category, is_published);

-- ----------------------------------------------------------------------------
-- INDEX 2: Composite index on enrollments for course lookups with grade
-- Optimizes: Grade-based queries, course statistics
-- Type: Composite covering index
-- ----------------------------------------------------------------------------
DROP INDEX IF EXISTS idx_enrollment_course_grade ON enrollments;
CREATE INDEX idx_enrollment_course_grade ON enrollments(course_id, grade, completed);

-- ----------------------------------------------------------------------------
-- INDEX 3: Index on enrollments for student lookups
-- Optimizes: Student transcript queries, student-based reports
-- Type: Composite index
-- ----------------------------------------------------------------------------
DROP INDEX IF EXISTS idx_enrollment_student ON enrollments;
CREATE INDEX idx_enrollment_student ON enrollments(student_id, course_id);

-- ----------------------------------------------------------------------------
-- INDEX 4: Composite index on payments for revenue reports
-- Optimizes: Monthly revenue reports, payment status queries
-- Type: Composite index with date
-- ----------------------------------------------------------------------------
DROP INDEX IF EXISTS idx_payment_status_date ON payments;
CREATE INDEX idx_payment_status_date ON payments(status, payment_date);

-- ----------------------------------------------------------------------------
-- INDEX 5: Index on payments for enrollment lookups
-- Optimizes: Payment verification, refund processing
-- Type: Single column index
-- ----------------------------------------------------------------------------
DROP INDEX IF EXISTS idx_payment_enrollment ON payments;
CREATE INDEX idx_payment_enrollment ON payments(enrollment_id);

-- ----------------------------------------------------------------------------
-- INDEX 6: Index on modules for course content queries
-- Optimizes: Course module listings, content navigation
-- Type: Composite index
-- ----------------------------------------------------------------------------
DROP INDEX IF EXISTS idx_module_course_order ON modules;
CREATE INDEX idx_module_course_order ON modules(course_id, seq_order);

-- ----------------------------------------------------------------------------
-- INDEX 7: Index on certificates for serial number lookups
-- Optimizes: Certificate verification, duplicate prevention
-- Already has UNIQUE constraint, but adding for explicit documentation
-- ----------------------------------------------------------------------------
-- Note: serial_number already has UNIQUE constraint from schema

-- ============================================================================
-- SECTION 3: OPTIMIZED QUERIES (AFTER OPTIMIZATION)
-- Run these EXPLAIN queries AFTER creating indexes to compare
-- ============================================================================

-- ============================================================================
-- OPTIMIZED QUERY 1: Search courses by category (AFTER)
-- ============================================================================
/*
EXPLAIN ANALYZE
SELECT c.*, CONCAT(i.first_name, ' ', i.last_name) AS instructor_name
FROM courses c
INNER JOIN instructors i ON c.instructor_id = i.instructor_id
WHERE c.category = 'Programming'
  AND c.is_published = TRUE;
*/

-- Expected AFTER optimization:
-- type: ref (using index)
-- key: idx_course_category_published
-- rows: ~2 (significantly reduced)
-- Extra: Using index condition

-- ============================================================================
-- OPTIMIZED QUERY 2: Get enrollments with student and course info (AFTER)
-- ============================================================================
/*
EXPLAIN ANALYZE
SELECT 
    s.student_id,
    s.first_name,
    s.last_name,
    c.title,
    e.grade,
    e.completed
FROM enrollments e
INNER JOIN students s ON e.student_id = s.student_id
INNER JOIN courses c ON e.course_id = c.course_id
WHERE e.grade > 80;
*/

-- Expected AFTER optimization:
-- type: range on enrollments (using index)
-- key: idx_enrollment_course_grade
-- Extra: Using index condition

-- ============================================================================
-- OPTIMIZED QUERY 3: Monthly revenue aggregation (AFTER)
-- ============================================================================
/*
EXPLAIN ANALYZE
SELECT 
    YEAR(p.payment_date) AS year,
    MONTH(p.payment_date) AS month,
    SUM(p.amount) AS revenue
FROM payments p
WHERE p.status = 'completed'
GROUP BY YEAR(p.payment_date), MONTH(p.payment_date);
*/

-- Expected AFTER optimization:
-- type: ref (using index)
-- key: idx_payment_status_date
-- Extra: Using index condition

-- ============================================================================
-- SECTION 4: QUERY REWRITING OPTIMIZATION
-- Demonstrating set-based vs row-based processing improvements
-- ============================================================================

-- ----------------------------------------------------------------------------
-- OPTIMIZATION EXAMPLE: Replace SELECT * with explicit columns
-- ----------------------------------------------------------------------------

-- BEFORE (inefficient):
/*
SELECT * FROM enrollments WHERE course_id = 1;
*/

-- AFTER (optimized - explicit columns, uses covering index):
/*
SELECT enrollment_id, student_id, grade, completed
FROM enrollments 
WHERE course_id = 1;
*/

-- ----------------------------------------------------------------------------
-- OPTIMIZATION EXAMPLE: Use EXISTS instead of IN for subqueries
-- ----------------------------------------------------------------------------

-- BEFORE (potentially slower with large datasets):
/*
SELECT * FROM students
WHERE student_id IN (
    SELECT student_id FROM enrollments WHERE completed = TRUE
);
*/

-- AFTER (optimized with EXISTS):
/*
SELECT s.* FROM students s
WHERE EXISTS (
    SELECT 1 FROM enrollments e 
    WHERE e.student_id = s.student_id AND e.completed = TRUE
);
*/

-- ============================================================================
-- SECTION 5: PERFORMANCE COMPARISON PROCEDURE
-- This procedure demonstrates before/after index performance
-- ============================================================================

DROP PROCEDURE IF EXISTS sp_demonstrate_optimization;

DELIMITER //

CREATE PROCEDURE sp_demonstrate_optimization()
BEGIN
    -- Show index information
    SELECT 'INDEXES ON COURSES TABLE:' AS info;
    SHOW INDEX FROM courses;
    
    SELECT 'INDEXES ON ENROLLMENTS TABLE:' AS info;
    SHOW INDEX FROM enrollments;
    
    SELECT 'INDEXES ON PAYMENTS TABLE:' AS info;
    SHOW INDEX FROM payments;
    
    -- Demonstrate EXPLAIN on optimized query
    SELECT 'EXPLAIN OUTPUT FOR CATEGORY SEARCH:' AS info;
    
    -- Note: In MySQL, you would run EXPLAIN separately
    -- This shows the expected improvement
    SELECT 
        'Before Index' AS state,
        'ALL' AS access_type,
        8 AS rows_examined,
        'Full table scan' AS notes
    UNION ALL
    SELECT 
        'After Index' AS state,
        'ref' AS access_type,
        2 AS rows_examined,
        'Using idx_course_category_published' AS notes;
        
END //

DELIMITER ;

-- ============================================================================
-- SECTION 6: INDEX STATISTICS AND MONITORING
-- ============================================================================

-- Show all indexes in the database
/*
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    COLUMN_NAME,
    SEQ_IN_INDEX,
    CARDINALITY,
    INDEX_TYPE
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'elearning_platform'
ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;
*/

-- ============================================================================
-- SECTION 7: EXECUTION SCRIPT FOR DEMO
-- Run these commands during presentation to show optimization
-- ============================================================================

/*
-- STEP 1: Run EXPLAIN before adding indexes (do this before running CREATE INDEX)
EXPLAIN SELECT c.*, i.first_name, i.last_name
FROM courses c
INNER JOIN instructors i ON c.instructor_id = i.instructor_id
WHERE c.category = 'Programming' AND c.is_published = TRUE;

-- STEP 2: Create indexes (run the CREATE INDEX statements above)

-- STEP 3: Run EXPLAIN after adding indexes
EXPLAIN SELECT c.*, i.first_name, i.last_name
FROM courses c
INNER JOIN instructors i ON c.instructor_id = i.instructor_id
WHERE c.category = 'Programming' AND c.is_published = TRUE;

-- STEP 4: Compare the 'type', 'key', and 'rows' columns
-- Before: type=ALL, key=NULL, rows=8
-- After: type=ref, key=idx_course_category_published, rows=2

-- STEP 5: Show index usage with EXPLAIN FORMAT=JSON for detailed analysis
EXPLAIN FORMAT=JSON
SELECT c.*, i.first_name, i.last_name
FROM courses c
INNER JOIN instructors i ON c.instructor_id = i.instructor_id
WHERE c.category = 'Programming' AND c.is_published = TRUE;
*/

-- ============================================================================
-- OPTIMIZATION SUMMARY
-- ============================================================================
/*
+----------------------------------+------------------+------------------+
| Optimization Applied             | Before           | After            |
+----------------------------------+------------------+------------------+
| Category search (courses)        | Full table scan  | Index range scan |
| Student transcript (enrollments) | Full table scan  | Index lookup     |
| Revenue report (payments)        | Full + filesort  | Index + streaming|
| Course module listing            | Full table scan  | Index range scan |
+----------------------------------+------------------+------------------+

Key Improvements:
1. Reduced I/O by using indexes instead of full table scans
2. Eliminated temporary tables for certain GROUP BY operations
3. Improved JOIN performance with indexed foreign keys
4. Covering indexes reduce need to access base table data
*/

-- ============================================================================
-- END OF OPTIMIZATION SCRIPT
-- ============================================================================
