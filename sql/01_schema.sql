-- ============================================================================
-- E-LEARNING PLATFORM DATABASE SCHEMA
-- Advanced Database Final Project
-- ============================================================================
-- This script creates the database schema for an online learning platform
-- with 7 tables demonstrating proper PKs, FKs, constraints, and data types.
-- ============================================================================

-- Drop database if exists and create fresh
DROP DATABASE IF EXISTS elearning_platform;
CREATE DATABASE elearning_platform;
USE elearning_platform;

-- ============================================================================
-- TABLE 1: INSTRUCTORS
-- Stores information about course instructors/teachers
-- ============================================================================
CREATE TABLE instructors (
    instructor_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    specialty VARCHAR(100) NOT NULL,
    rating DECIMAL(2,1) DEFAULT 0.0,
    hire_date DATE NOT NULL,
    bio TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_instructor_rating CHECK (rating >= 0.0 AND rating <= 5.0),
    CONSTRAINT chk_instructor_email CHECK (email LIKE '%@%.%')
);

-- ============================================================================
-- TABLE 2: STUDENTS
-- Stores information about enrolled students
-- ============================================================================
CREATE TABLE students (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    date_of_birth DATE,
    phone VARCHAR(20),
    address TEXT,
    join_date DATE NOT NULL,
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_student_email CHECK (email LIKE '%@%.%')
);

-- ============================================================================
-- TABLE 3: COURSES
-- Stores course information with instructor relationship
-- ============================================================================
CREATE TABLE courses (
    course_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    category VARCHAR(50) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    duration_hours INT NOT NULL,
    difficulty_level ENUM('beginner', 'intermediate', 'advanced') DEFAULT 'beginner',
    instructor_id INT NOT NULL,
    is_published BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_course_price CHECK (price >= 0),
    CONSTRAINT chk_course_duration CHECK (duration_hours > 0),
    
    -- Foreign Keys
    CONSTRAINT fk_course_instructor 
        FOREIGN KEY (instructor_id) REFERENCES instructors(instructor_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ============================================================================
-- TABLE 4: MODULES
-- Stores course modules/lessons with course relationship
-- ============================================================================
CREATE TABLE modules (
    module_id INT AUTO_INCREMENT PRIMARY KEY,
    course_id INT NOT NULL,
    title VARCHAR(150) NOT NULL,
    content TEXT,
    duration_minutes INT NOT NULL,
    seq_order INT NOT NULL,
    is_free_preview BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_module_duration CHECK (duration_minutes > 0),
    CONSTRAINT chk_module_order CHECK (seq_order > 0),
    
    -- Foreign Keys
    CONSTRAINT fk_module_course 
        FOREIGN KEY (course_id) REFERENCES courses(course_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    
    -- Unique constraint for course module ordering
    CONSTRAINT uq_course_module_order UNIQUE (course_id, seq_order)
);

-- ============================================================================
-- TABLE 5: ENROLLMENTS
-- Junction table linking students to courses with grade tracking
-- ============================================================================
CREATE TABLE enrollments (
    enrollment_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    course_id INT NOT NULL,
    enroll_date DATE NOT NULL,
    grade DECIMAL(5,2) DEFAULT NULL,
    progress_percent DECIMAL(5,2) DEFAULT 0.00,
    completed BOOLEAN DEFAULT FALSE,
    completion_date DATE DEFAULT NULL,
    certificate_issued BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_enrollment_grade CHECK (grade IS NULL OR (grade >= 0 AND grade <= 100)),
    CONSTRAINT chk_enrollment_progress CHECK (progress_percent >= 0 AND progress_percent <= 100),
    
    -- Foreign Keys
    CONSTRAINT fk_enrollment_student 
        FOREIGN KEY (student_id) REFERENCES students(student_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_enrollment_course 
        FOREIGN KEY (course_id) REFERENCES courses(course_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    
    -- Unique constraint: student can only enroll once per course
    CONSTRAINT uq_student_course UNIQUE (student_id, course_id)
);

-- ============================================================================
-- TABLE 6: PAYMENTS
-- Stores payment transactions linked to enrollments
-- ============================================================================
CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    enrollment_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_date DATETIME NOT NULL,
    payment_method ENUM('credit_card', 'debit_card', 'paypal', 'bank_transfer', 'gcash', 'maya') NOT NULL,
    transaction_ref VARCHAR(100),
    status ENUM('pending', 'completed', 'failed', 'refunded') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_payment_amount CHECK (amount >= 0),
    
    -- Foreign Keys
    CONSTRAINT fk_payment_enrollment 
        FOREIGN KEY (enrollment_id) REFERENCES enrollments(enrollment_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ============================================================================
-- TABLE 7: CERTIFICATES
-- Audit table for issued certificates (populated by cursor procedure)
-- ============================================================================
CREATE TABLE certificates (
    certificate_id INT AUTO_INCREMENT PRIMARY KEY,
    enrollment_id INT NOT NULL,
    student_id INT NOT NULL,
    course_id INT NOT NULL,
    serial_number VARCHAR(50) NOT NULL UNIQUE,
    issue_date DATETIME NOT NULL,
    final_grade DECIMAL(5,2) NOT NULL,
    instructor_name VARCHAR(100) NOT NULL,
    course_title VARCHAR(150) NOT NULL,
    student_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign Keys
    CONSTRAINT fk_certificate_enrollment 
        FOREIGN KEY (enrollment_id) REFERENCES enrollments(enrollment_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_certificate_student 
        FOREIGN KEY (student_id) REFERENCES students(student_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_certificate_course 
        FOREIGN KEY (course_id) REFERENCES courses(course_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ============================================================================
-- END OF SCHEMA DEFINITION
-- ============================================================================
