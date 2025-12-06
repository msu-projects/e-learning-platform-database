# E-Learning Platform Database

Advanced Database Final Project - A complete MySQL database system for an online learning platform demonstrating advanced SQL skills and practical database optimization.

## Project Overview

This project implements a database-centered system for an **Online Learning Platform** (similar to Coursera/Udemy) with the following features:

- Student enrollment and course management
- Instructor and course tracking
- Payment processing
- Certificate generation
- Performance analytics

## Database Schema

### Entity-Relationship Diagram

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

### Tables (7 total)

| Table          | Description                               | Rows |
| -------------- | ----------------------------------------- | ---- |
| `instructors`  | Course instructors/teachers               | 5    |
| `students`     | Enrolled students                         | 10   |
| `courses`      | Available courses                         | 8    |
| `modules`      | Course content modules                    | 15   |
| `enrollments`  | Student-course enrollments                | 20   |
| `payments`     | Payment transactions                      | 20   |
| `certificates` | Issued certificates (populated by cursor) | 0\*  |

**Total: 78 rows** (exceeds 30-row requirement)

## Project Components

### Views (5 total)

| View                         | Type                  | Purpose                                            |
| ---------------------------- | --------------------- | -------------------------------------------------- |
| `vw_course_enrollment_stats` | Aggregated (GROUP BY) | Enrollment count, avg grade, revenue per course    |
| `vw_student_course_details`  | Join (4 tables)       | Student + enrollment + course + instructor details |
| `vw_active_premium_students` | Filtered (WHERE)      | Active students in courses > ₱2,500                |
| `vw_instructor_performance`  | Computed column       | Instructor earnings (70% of revenue)               |
| `vw_monthly_revenue_report`  | Report-style          | Month-by-month revenue analysis                    |

### Stored Procedures (5 total)

| Procedure                   | Type            | Purpose                                                |
| --------------------------- | --------------- | ------------------------------------------------------ |
| `sp_enroll_student`         | INSERT          | Enroll student + create payment record                 |
| `sp_update_grade`           | UPDATE          | Update grade, set progress=100%, auto-complete if ≥60  |
| `sp_get_student_transcript` | Result Set      | Return student's complete academic record              |
| `sp_search_courses`         | Optional Params | Search with optional category/price/difficulty filters |
| `sp_unenroll_student`       | DELETE          | Unenroll student with optional refund                  |

### User-Defined Functions (5 total)

| Function                               | Returns | Purpose                        |
| -------------------------------------- | ------- | ------------------------------ |
| `fn_letter_grade(score)`               | VARCHAR | Convert 0-100 to A+/A/A-/.../F |
| `fn_course_completion_rate(course_id)` | DECIMAL | % of students who completed    |
| `fn_student_gpa(student_id)`           | DECIMAL | Calculate GPA on 4.0 scale     |
| `fn_instructor_revenue(instructor_id)` | DECIMAL | Total revenue from courses     |
| `fn_days_since_enrollment(date)`       | INT     | Days elapsed since enrollment  |

### Cursor

| Procedure                    | Purpose                                                |
| ---------------------------- | ------------------------------------------------------ |
| `sp_award_bulk_certificates` | Bulk certificate generation with unique serial numbers |

**Why cursor is required:**

1. Unique serial number generation per certificate (sequential)
2. Per-record validation (student status, payment status)
3. Denormalized data capture at time of issuance
4. Audit trail logging per record

### Optimization

| Index                           | Target          | Improvement        |
| ------------------------------- | --------------- | ------------------ |
| `idx_course_category_published` | Course searches | ALL → ref          |
| `idx_enrollment_course_grade`   | Grade queries   | Full scan → index  |
| `idx_enrollment_student`        | Student lookups | Improved JOIN      |
| `idx_payment_status_date`       | Revenue reports | Faster aggregation |
| `idx_payment_enrollment`        | Payment lookups | Index lookup       |
| `idx_module_course_order`       | Module listings | Ordered retrieval  |

## File Structure

```
sql/
├── 01_schema.sql        # DDL - CREATE TABLE statements
├── 02_sample_data.sql   # DML - INSERT sample data
├── 03_views.sql         # 5 view definitions
├── 04_procedures.sql    # 5 stored procedures
├── 05_functions.sql     # 5 user-defined functions
├── 06_cursor.sql        # Cursor procedure
└── 07_indexes.sql       # Optimization indexes + EXPLAIN
```

## Installation & Setup

### Prerequisites

- MySQL 8.0+
- MySQL Workbench (recommended)

### Execution Order

Run the SQL files in order:

```sql
-- In MySQL Workbench or command line:
SOURCE sql/01_schema.sql;
SOURCE sql/02_sample_data.sql;
SOURCE sql/03_views.sql;
SOURCE sql/04_procedures.sql;
SOURCE sql/05_functions.sql;
SOURCE sql/06_cursor.sql;
SOURCE sql/07_indexes.sql;
```

Or run individually by opening each file in MySQL Workbench and executing.

## Demo Queries

### Query Views

```sql
-- Aggregated view
SELECT * FROM vw_course_enrollment_stats;

-- Join view for specific student
SELECT * FROM vw_student_course_details WHERE student_id = 1;

-- Filtered view
SELECT * FROM vw_active_premium_students;

-- Computed column view
SELECT instructor_name, instructor_earnings FROM vw_instructor_performance;

-- Report view
SELECT * FROM vw_monthly_revenue_report WHERE revenue_year = 2023;
```

### Execute Procedures

```sql
-- Enroll a student
CALL sp_enroll_student(1, 5, 'credit_card');

-- Update a grade
CALL sp_update_grade(1, 85.50);

-- Get student transcript
CALL sp_get_student_transcript(1);

-- Search courses (all optional params)
CALL sp_search_courses('Programming', NULL, 3000, NULL, NULL);

-- Unenroll with refund
CALL sp_unenroll_student(5, TRUE);
```

### Use UDFs

```sql
-- Letter grade conversion
SELECT grade, fn_letter_grade(grade) FROM enrollments WHERE grade IS NOT NULL;

-- Student GPA
SELECT student_id, fn_student_gpa(student_id) AS gpa FROM students;

-- Course completion rate
SELECT course_id, title, fn_course_completion_rate(course_id) AS completion_rate
FROM courses;

-- Instructor revenue
SELECT instructor_id, fn_instructor_revenue(instructor_id) AS revenue
FROM instructors;
```

### Trigger Cursor

```sql
-- Award certificates to eligible students
CALL sp_award_bulk_certificates();

-- View issued certificates
SELECT * FROM certificates;
```

### Show Optimization

```sql
-- Before optimization (run before 07_indexes.sql)
EXPLAIN SELECT * FROM courses WHERE category = 'Programming';

-- After optimization (run after 07_indexes.sql)
EXPLAIN SELECT * FROM courses WHERE category = 'Programming';

-- Compare 'type' column: ALL (before) vs ref (after)
```

## Requirements Checklist

- [x] **Domain**: E-Learning Platform (not Sakila/World)
- [x] **Schema**: 7 tables with PKs, FKs, constraints
- [x] **Sample Data**: 78 rows (exceeds 30 requirement)
- [x] **Views**: 5 views (aggregated, join, filtered, computed, report)
- [x] **Stored Procedures**: 5 procedures (2 INSERT/UPDATE, 1 DELETE, 1 result set, 1 optional params)
- [x] **UDFs**: 5 functions (used in SELECTs and views)
- [x] **Cursor**: 1 cursor with justification comments
- [x] **Optimization**: Indexes with EXPLAIN before/after

## Authors

Advanced Database Final Project

## License

Academic use only.
