-- ============================================================================
-- E-LEARNING PLATFORM SAMPLE DATA
-- Advanced Database Final Project
-- ============================================================================
-- This script populates the database with 80+ rows of sample data
-- distributed across all tables for testing and demonstration.
-- ============================================================================

USE elearning_platform;

-- ============================================================================
-- INSTRUCTORS (5 rows)
-- ============================================================================
INSERT INTO instructors (first_name, last_name, email, specialty, rating, hire_date, bio) VALUES
('Maria', 'Santos', 'maria.santos@elearn.com', 'Web Development', 4.8, '2020-03-15', 'Senior web developer with 10+ years of experience in full-stack development.'),
('Juan', 'Dela Cruz', 'juan.delacruz@elearn.com', 'Data Science', 4.9, '2019-06-01', 'Data scientist specializing in machine learning and statistical analysis.'),
('Ana', 'Reyes', 'ana.reyes@elearn.com', 'Mobile Development', 4.5, '2021-01-10', 'iOS and Android developer with expertise in cross-platform frameworks.'),
('Carlos', 'Garcia', 'carlos.garcia@elearn.com', 'Database Administration', 4.7, '2018-09-20', 'DBA with expertise in MySQL, PostgreSQL, and Oracle databases.'),
('Lisa', 'Mendoza', 'lisa.mendoza@elearn.com', 'UI/UX Design', 4.6, '2020-11-05', 'Creative designer focused on user-centered design principles.');

-- ============================================================================
-- STUDENTS (10 rows)
-- ============================================================================
INSERT INTO students (first_name, last_name, email, date_of_birth, phone, address, join_date, status) VALUES
('Miguel', 'Ramos', 'miguel.ramos@email.com', '1998-05-12', '09171234567', '123 Rizal St, Manila', '2023-01-15', 'active'),
('Sofia', 'Cruz', 'sofia.cruz@email.com', '2000-08-23', '09181234567', '456 Bonifacio Ave, Quezon City', '2023-02-20', 'active'),
('Gabriel', 'Torres', 'gabriel.torres@email.com', '1999-03-07', '09191234567', '789 Mabini Blvd, Makati', '2023-03-10', 'active'),
('Isabella', 'Villanueva', 'isabella.v@email.com', '2001-11-30', '09201234567', '321 Luna St, Pasig', '2023-04-05', 'active'),
('Rafael', 'Gonzales', 'rafael.g@email.com', '1997-07-18', '09211234567', '654 Del Pilar Rd, Mandaluyong', '2023-05-12', 'active'),
('Camila', 'Fernandez', 'camila.f@email.com', '2002-02-14', '09221234567', '987 Aguinaldo St, Taguig', '2023-06-18', 'active'),
('Andres', 'Lopez', 'andres.lopez@email.com', '1996-09-25', '09231234567', '147 Quezon Ave, Caloocan', '2023-07-22', 'inactive'),
('Valentina', 'Martinez', 'valentina.m@email.com', '2000-12-08', '09241234567', '258 Roxas Blvd, Paranaque', '2023-08-30', 'active'),
('Diego', 'Hernandez', 'diego.h@email.com', '1998-04-16', '09251234567', '369 Osmeña St, Las Pinas', '2023-09-14', 'active'),
('Lucia', 'Aquino', 'lucia.aquino@email.com', '2001-06-22', '09261234567', '741 Laurel Ave, Muntinlupa', '2023-10-08', 'suspended');

-- ============================================================================
-- COURSES (8 rows)
-- ============================================================================
INSERT INTO courses (title, description, category, price, duration_hours, difficulty_level, instructor_id, is_published) VALUES
('Complete Web Development Bootcamp', 'Learn HTML, CSS, JavaScript, React, Node.js and more to become a full-stack developer.', 'Programming', 2999.00, 60, 'beginner', 1, TRUE),
('Python for Data Science', 'Master Python programming for data analysis, visualization, and machine learning.', 'Data Science', 3499.00, 45, 'intermediate', 2, TRUE),
('Advanced SQL Masterclass', 'Deep dive into SQL with stored procedures, triggers, optimization, and advanced queries.', 'Database', 1999.00, 30, 'advanced', 4, TRUE),
('iOS App Development with Swift', 'Build professional iOS applications using Swift and SwiftUI.', 'Mobile Development', 3999.00, 50, 'intermediate', 3, TRUE),
('UI/UX Design Fundamentals', 'Learn design thinking, wireframing, prototyping, and user research techniques.', 'Design', 2499.00, 35, 'beginner', 5, TRUE),
('Machine Learning A-Z', 'Comprehensive guide to machine learning algorithms and their implementations.', 'Data Science', 4499.00, 70, 'advanced', 2, TRUE),
('React Native Mobile Development', 'Create cross-platform mobile apps with React Native framework.', 'Mobile Development', 2999.00, 40, 'intermediate', 3, TRUE),
('Database Design & Optimization', 'Learn to design efficient database schemas and optimize query performance.', 'Database', 1799.00, 25, 'intermediate', 4, FALSE);

-- ============================================================================
-- MODULES (15 rows - distributed across courses)
-- ============================================================================
INSERT INTO modules (course_id, title, content, duration_minutes, seq_order, is_free_preview) VALUES
-- Web Development Bootcamp (course_id = 1)
(1, 'Introduction to HTML', 'Learn the basics of HTML structure, tags, and semantic markup.', 120, 1, TRUE),
(1, 'CSS Styling Fundamentals', 'Master CSS selectors, properties, flexbox, and grid layouts.', 150, 2, FALSE),
(1, 'JavaScript Essentials', 'Understand variables, functions, DOM manipulation, and events.', 180, 3, FALSE),

-- Python for Data Science (course_id = 2)
(2, 'Python Basics', 'Introduction to Python syntax, data types, and control structures.', 90, 1, TRUE),
(2, 'Data Analysis with Pandas', 'Learn to manipulate and analyze data using Pandas library.', 120, 2, FALSE),
(2, 'Data Visualization', 'Create stunning visualizations with Matplotlib and Seaborn.', 100, 3, FALSE),

-- Advanced SQL Masterclass (course_id = 3)
(3, 'Complex Joins & Subqueries', 'Master advanced join techniques and subquery patterns.', 90, 1, TRUE),
(3, 'Stored Procedures & Functions', 'Create reusable database logic with procedures and UDFs.', 120, 2, FALSE),
(3, 'Query Optimization', 'Learn indexing strategies and query performance tuning.', 110, 3, FALSE),

-- iOS App Development (course_id = 4)
(4, 'Swift Language Basics', 'Learn Swift syntax, optionals, and error handling.', 100, 1, TRUE),
(4, 'SwiftUI Fundamentals', 'Build user interfaces with SwiftUI declarative syntax.', 130, 2, FALSE),

-- UI/UX Design (course_id = 5)
(5, 'Design Thinking Process', 'Understand the 5 stages of design thinking methodology.', 80, 1, TRUE),
(5, 'Wireframing & Prototyping', 'Create wireframes and interactive prototypes with Figma.', 110, 2, FALSE),

-- Machine Learning A-Z (course_id = 6)
(6, 'Introduction to ML', 'Overview of machine learning concepts and types.', 90, 1, TRUE),
(6, 'Supervised Learning', 'Implement regression and classification algorithms.', 150, 2, FALSE);

-- ============================================================================
-- ENROLLMENTS (20 rows)
-- ============================================================================
INSERT INTO enrollments (student_id, course_id, enroll_date, grade, progress_percent, completed, completion_date, certificate_issued) VALUES
-- Miguel's enrollments
(1, 1, '2023-01-20', 85.50, 100.00, TRUE, '2023-04-15', FALSE),
(1, 3, '2023-05-01', 92.00, 100.00, TRUE, '2023-07-10', FALSE),

-- Sofia's enrollments
(2, 2, '2023-02-25', 78.25, 100.00, TRUE, '2023-05-20', FALSE),
(2, 6, '2023-06-01', 65.00, 75.00, FALSE, NULL, FALSE),

-- Gabriel's enrollments
(3, 1, '2023-03-15', 88.75, 100.00, TRUE, '2023-06-10', FALSE),
(3, 4, '2023-07-01', 45.00, 60.00, FALSE, NULL, FALSE),

-- Isabella's enrollments
(4, 5, '2023-04-10', 95.00, 100.00, TRUE, '2023-06-25', FALSE),
(4, 1, '2023-07-15', 72.50, 85.00, FALSE, NULL, FALSE),

-- Rafael's enrollments
(5, 3, '2023-05-20', 88.00, 100.00, TRUE, '2023-08-01', FALSE),
(5, 2, '2023-08-10', NULL, 30.00, FALSE, NULL, FALSE),

-- Camila's enrollments
(6, 4, '2023-06-25', 91.25, 100.00, TRUE, '2023-09-15', FALSE),
(6, 7, '2023-09-20', 82.00, 90.00, FALSE, NULL, FALSE),

-- Andres's enrollments
(7, 2, '2023-07-30', 55.00, 100.00, TRUE, '2023-10-20', FALSE),
(7, 3, '2023-11-01', NULL, 15.00, FALSE, NULL, FALSE),

-- Valentina's enrollments
(8, 5, '2023-09-05', 89.50, 100.00, TRUE, '2023-11-10', FALSE),
(8, 6, '2023-11-15', 76.00, 80.00, FALSE, NULL, FALSE),

-- Diego's enrollments
(9, 1, '2023-09-20', 94.00, 100.00, TRUE, '2023-12-05', FALSE),
(9, 7, '2023-12-10', NULL, 25.00, FALSE, NULL, FALSE),

-- Lucia's enrollments (suspended student)
(10, 2, '2023-10-15', 42.00, 50.00, FALSE, NULL, FALSE),
(10, 5, '2023-11-01', NULL, 10.00, FALSE, NULL, FALSE);

-- ============================================================================
-- PAYMENTS (20 rows - matching enrollments)
-- ============================================================================
INSERT INTO payments (enrollment_id, amount, payment_date, payment_method, transaction_ref, status) VALUES
-- Payments for each enrollment
(1, 2999.00, '2023-01-20 10:30:00', 'credit_card', 'TXN-2023-001', 'completed'),
(2, 1999.00, '2023-05-01 14:15:00', 'gcash', 'TXN-2023-002', 'completed'),
(3, 3499.00, '2023-02-25 09:45:00', 'paypal', 'TXN-2023-003', 'completed'),
(4, 4499.00, '2023-06-01 16:20:00', 'credit_card', 'TXN-2023-004', 'completed'),
(5, 2999.00, '2023-03-15 11:00:00', 'debit_card', 'TXN-2023-005', 'completed'),
(6, 3999.00, '2023-07-01 13:30:00', 'maya', 'TXN-2023-006', 'completed'),
(7, 2499.00, '2023-04-10 15:45:00', 'bank_transfer', 'TXN-2023-007', 'completed'),
(8, 2999.00, '2023-07-15 10:00:00', 'gcash', 'TXN-2023-008', 'completed'),
(9, 1999.00, '2023-05-20 12:30:00', 'credit_card', 'TXN-2023-009', 'completed'),
(10, 3499.00, '2023-08-10 14:00:00', 'paypal', 'TXN-2023-010', 'completed'),
(11, 3999.00, '2023-06-25 09:15:00', 'debit_card', 'TXN-2023-011', 'completed'),
(12, 2999.00, '2023-09-20 16:45:00', 'maya', 'TXN-2023-012', 'completed'),
(13, 3499.00, '2023-07-30 11:30:00', 'credit_card', 'TXN-2023-013', 'completed'),
(14, 1999.00, '2023-11-01 13:00:00', 'gcash', 'TXN-2023-014', 'pending'),
(15, 2499.00, '2023-09-05 10:45:00', 'bank_transfer', 'TXN-2023-015', 'completed'),
(16, 4499.00, '2023-11-15 15:20:00', 'credit_card', 'TXN-2023-016', 'completed'),
(17, 2999.00, '2023-09-20 12:00:00', 'paypal', 'TXN-2023-017', 'completed'),
(18, 2999.00, '2023-12-10 14:30:00', 'debit_card', 'TXN-2023-018', 'pending'),
(19, 3499.00, '2023-10-15 09:00:00', 'maya', 'TXN-2023-019', 'completed'),
(20, 2499.00, '2023-11-01 11:15:00', 'gcash', 'TXN-2023-020', 'refunded');

-- ============================================================================
-- CERTIFICATES TABLE
-- Will be populated by the cursor procedure (sp_award_bulk_certificates)
-- No initial data inserted here
-- ============================================================================

-- ============================================================================
-- DATA SUMMARY
-- ============================================================================
-- instructors: 5 rows
-- students: 10 rows  
-- courses: 8 rows
-- modules: 15 rows
-- enrollments: 20 rows
-- payments: 20 rows
-- certificates: 0 rows (populated by cursor)
-- TOTAL: 78 rows (exceeds 30-row requirement)
-- ============================================================================
