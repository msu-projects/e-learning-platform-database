# 🎓 E-Learning Platform Database

[![MySQL](https://img.shields.io/badge/MySQL-8.0+-4479A1?style=flat&logo=mysql&logoColor=white)](https://www.mysql.com/)
[![License](https://img.shields.io/badge/License-Academic-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Complete-success.svg)]()

> A comprehensive MySQL database system for an online learning platform, demonstrating advanced SQL techniques including stored procedures, user-defined functions, cursors, and query optimization.

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Database Schema](#-database-schema)
- [Project Components](#-project-components)
- [Installation](#-installation--setup)
- [Usage Examples](#-usage-examples)
- [Project Structure](#-project-structure)
- [Requirements Checklist](#-requirements-checklist)
- [License](#-license)

## 🎯 Overview

This project implements a complete database system for an **Online Learning Platform** (similar to Coursera/Udemy). It serves as a demonstration of advanced database concepts and best practices in MySQL development.

### 🌟 Features

| Feature                   | Description                                              |
| ------------------------- | -------------------------------------------------------- |
| 👨‍🎓 **Student Management** | Track student enrollment, progress, and academic records |
| 📚 **Course Catalog**     | Organize courses by category with instructor assignments |
| 💳 **Payment Processing** | Handle transactions with multiple payment methods        |
| 🏆 **Certification**      | Auto-generate certificates for completed courses         |
| 📊 **Analytics**          | Performance metrics and revenue reporting                |

## 🗄️ Database Schema

### 📐 Entity-Relationship Diagram

```
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│ INSTRUCTORS │───┐   │   COURSES   │   ┌───│  STUDENTS   │
├─────────────┤   │   ├─────────────┤   │   ├─────────────┤
│ instructor_id│   └──►│ course_id   │   │   │ student_id  │
│ first_name  │       │ title       │   │   │ first_name  │
│ last_name   │       │ category    │   │   │ last_name   │
│ email       │       │ price       │   │   │ email       │
│ specialty   │       │instructor_id│   │   │ join_date   │
│ rating      │       │ is_published│   │   │ status      │
└─────────────┘       └──────┬──────┘   │   └──────┬──────┘
                             │          │          │
                      ┌──────┴──────┐   │   ┌──────┴──────┐
                      │   MODULES   │   │   │ ENROLLMENTS │
                      ├─────────────┤   │   ├─────────────┤
                      │ module_id   │   └──►│enrollment_id│
                      │ course_id   │       │ student_id  │
                      │ title       │   ┌───│ course_id   │
                      │ seq_order   │   │   │ grade       │
                      └─────────────┘   │   │ completed   │
                                        │   └──────┬──────┘
                      ┌─────────────┐   │          │
                      │ CERTIFICATES│   │   ┌──────┴──────┐
                      ├─────────────┤   │   │  PAYMENTS   │
                      │certificate_id│   │   ├─────────────┤
                      │enrollment_id│◄──┤   │ payment_id  │
                      │serial_number│   │   │enrollment_id│
                      │ issue_date  │   │   │ amount      │
                      └─────────────┘   │   │ status      │
                                        │   └─────────────┘
                                        │
                                        └───────────────────
```

### 📊 Tables Overview

| Table          | Description                       | Records |
| :------------- | :-------------------------------- | :-----: |
| `instructors`  | Course instructors and teachers   |    5    |
| `students`     | Registered platform users         |   10    |
| `courses`      | Available course catalog          |    8    |
| `modules`      | Course content modules            |   15    |
| `enrollments`  | Student-course enrollment records |   20    |
| `payments`     | Payment transactions              |   20    |
| `certificates` | Issued completion certificates    |   0\*   |

> **📈 Total Records:** 78 rows of sample data

---

## 🔧 Project Components

### 👁️ Views (5)

| View                         | Type       | Description                                               |
| :--------------------------- | :--------- | :-------------------------------------------------------- |
| `vw_course_enrollment_stats` | Aggregated | Enrollment counts, average grades, and revenue per course |
| `vw_student_course_details`  | Multi-Join | Combines student, enrollment, course, and instructor data |
| `vw_active_premium_students` | Filtered   | Active students enrolled in premium courses (>₱2,500)     |
| `vw_instructor_performance`  | Computed   | Instructor earnings calculated at 70% revenue share       |
| `vw_monthly_revenue_report`  | Report     | Month-by-month revenue breakdown and analysis             |

### ⚙️ Stored Procedures (5)

| Procedure                   | Operation | Description                                                     |
| :-------------------------- | :-------- | :-------------------------------------------------------------- |
| `sp_enroll_student`         | INSERT    | Enrolls a student and creates corresponding payment record      |
| `sp_update_grade`           | UPDATE    | Updates grade, sets progress to 100%, auto-completes if ≥60     |
| `sp_get_student_transcript` | SELECT    | Returns complete academic record for a student                  |
| `sp_search_courses`         | SELECT    | Advanced search with optional category/price/difficulty filters |
| `sp_unenroll_student`       | DELETE    | Removes enrollment with optional refund processing              |

### 🔢 User-Defined Functions (5)

| Function                               | Returns | Description                                              |
| :------------------------------------- | :------ | :------------------------------------------------------- |
| `fn_letter_grade(score)`               | VARCHAR | Converts numeric score (0-100) to letter grade (A+ to F) |
| `fn_course_completion_rate(course_id)` | DECIMAL | Calculates percentage of students who completed a course |
| `fn_student_gpa(student_id)`           | DECIMAL | Computes student's GPA on a 4.0 scale                    |
| `fn_instructor_revenue(instructor_id)` | DECIMAL | Calculates total revenue generated by an instructor      |
| `fn_days_since_enrollment(date)`       | INT     | Returns days elapsed since enrollment date               |

### 🔄 Cursor Implementation

| Procedure                    | Description                                            |
| :--------------------------- | :----------------------------------------------------- |
| `sp_award_bulk_certificates` | Bulk certificate generation with unique serial numbers |

<details>
<summary><strong>Why a cursor is required for this operation</strong></summary>

1. **Sequential Processing** — Unique serial numbers must be generated sequentially
2. **Per-Record Validation** — Each record requires individual status checks (student active, payment completed)
3. **Denormalized Capture** — Student/course names captured at time of issuance for historical accuracy
4. **Audit Trail** — Individual logging per certificate for compliance

</details>

### ⚡ Index Optimization

| Index                           | Target          | Performance Improvement        |
| :------------------------------ | :-------------- | :----------------------------- |
| `idx_course_category_published` | Course searches | `ALL` → `ref` (index lookup)   |
| `idx_enrollment_course_grade`   | Grade queries   | Full table scan → Index scan   |
| `idx_enrollment_student`        | Student lookups | Faster JOIN operations         |
| `idx_payment_status_date`       | Revenue reports | Optimized aggregation queries  |
| `idx_payment_enrollment`        | Payment lookups | Direct index access            |
| `idx_module_course_order`       | Module listings | Ordered retrieval without sort |

---

## 🚀 Installation & Setup

### Prerequisites

- **MySQL 8.0+** — [Download MySQL](https://dev.mysql.com/downloads/)
- **MySQL Workbench** (recommended) — [Download Workbench](https://dev.mysql.com/downloads/workbench/)

### Quick Start

Run the SQL files in sequential order:

```bash
# Using MySQL command line
mysql -u root -p < sql/01_schema.sql
mysql -u root -p elearning_platform < sql/02_sample_data.sql
mysql -u root -p elearning_platform < sql/03_views.sql
mysql -u root -p elearning_platform < sql/04_procedures.sql
mysql -u root -p elearning_platform < sql/05_functions.sql
mysql -u root -p elearning_platform < sql/06_cursor.sql
mysql -u root -p elearning_platform < sql/07_indexes.sql
```

**Or using MySQL Workbench:**

```sql
SOURCE sql/01_schema.sql;
SOURCE sql/02_sample_data.sql;
SOURCE sql/03_views.sql;
SOURCE sql/04_procedures.sql;
SOURCE sql/05_functions.sql;
SOURCE sql/06_cursor.sql;
SOURCE sql/07_indexes.sql;
```

> **💡 Tip:** Open each file individually in MySQL Workbench and execute (⚡ or Ctrl+Shift+Enter).

---

## 📖 Usage Examples

### Querying Views

```sql
-- Course statistics with enrollment data
SELECT * FROM vw_course_enrollment_stats;

-- Student details with enrolled courses
SELECT * FROM vw_student_course_details WHERE student_id = 1;

-- Premium course students
SELECT * FROM vw_active_premium_students;

-- Instructor performance metrics
SELECT instructor_name, instructor_earnings
FROM vw_instructor_performance;

-- Monthly revenue breakdown
SELECT * FROM vw_monthly_revenue_report
WHERE revenue_year = 2024;
```

### Calling Stored Procedures

```sql
-- Enroll student (student_id, course_id, payment_method)
CALL sp_enroll_student(1, 5, 'credit_card');

-- Update student grade (enrollment_id, new_grade)
CALL sp_update_grade(1, 85.50);

-- Get complete transcript
CALL sp_get_student_transcript(1);

-- Search courses with filters
CALL sp_search_courses('Programming', NULL, 3000, NULL, NULL);

-- Unenroll with refund option
CALL sp_unenroll_student(5, TRUE);
```

### Using Functions

```sql
-- Convert numeric grades to letter grades
SELECT grade, fn_letter_grade(grade) AS letter_grade
FROM enrollments
WHERE grade IS NOT NULL;

-- Calculate student GPAs
SELECT student_id, fn_student_gpa(student_id) AS gpa
FROM students;

-- Get course completion rates
SELECT course_id, title,
       fn_course_completion_rate(course_id) AS completion_rate
FROM courses;

-- Calculate instructor revenue
SELECT instructor_id,
       fn_instructor_revenue(instructor_id) AS total_revenue
FROM instructors;
```

### Running the Cursor Procedure

```sql
-- Generate certificates for all eligible students
CALL sp_award_bulk_certificates();

-- View issued certificates
SELECT * FROM certificates;
```

### Verifying Index Optimization

```sql
-- Check query execution plan (before adding indexes)
EXPLAIN SELECT * FROM courses WHERE category = 'Programming';

-- After running 07_indexes.sql, compare the 'type' column:
-- Before: ALL (full table scan)
-- After:  ref (index lookup)
```

---

## 📁 Project Structure

```
adv-database-final-project/
│
├── 📄 README.md              # Project documentation
├── 📄 LICENSE                # License information
│
└── 📂 sql/
    ├── 01_schema.sql         # Database and table definitions (DDL)
    ├── 02_sample_data.sql    # Sample data insertion (DML)
    ├── 03_views.sql          # View definitions
    ├── 04_procedures.sql     # Stored procedures
    ├── 05_functions.sql      # User-defined functions
    ├── 06_cursor.sql         # Cursor implementation
    └── 07_indexes.sql        # Index optimization + EXPLAIN analysis
```

---

## ✅ Requirements Checklist

| Requirement            | Status | Details                                                            |
| :--------------------- | :----: | :----------------------------------------------------------------- |
| Custom Domain          |   ✅   | E-Learning Platform (original design)                              |
| Database Schema        |   ✅   | 7 tables with PKs, FKs, and constraints                            |
| Sample Data            |   ✅   | 78 rows (exceeds 30-row minimum)                                   |
| Views                  |   ✅   | 5 views (aggregated, join, filtered, computed, report)             |
| Stored Procedures      |   ✅   | 5 procedures (INSERT, UPDATE, DELETE, result set, optional params) |
| User-Defined Functions |   ✅   | 5 functions (used in SELECTs and views)                            |
| Cursor                 |   ✅   | 1 cursor with detailed justification                               |
| Optimization           |   ✅   | 6 indexes with EXPLAIN before/after comparison                     |

---

## 📄 License

This project is for **academic use only** as part of the Advanced Database course final project.

---

<div align="center">

**Built with ❤️ for Advanced Database Final Project**

</div>
