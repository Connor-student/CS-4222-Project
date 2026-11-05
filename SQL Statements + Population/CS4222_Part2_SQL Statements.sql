-- CS 4222 University Database Project
-- PART II: Translate ER Diagram into Tables + Populate Sample Data
-- PostgreSQL / cs1.calstatela.edu
--
-- --
-- This script is intended to be run in the Query Tool for the assigned
-- CS4222 PostgreSQL database.
--
-- BEGIN;

-- ============================================================
-- 0. RESET PROJECT TABLES
-- ============================================================

DROP TABLE IF EXISTS RESEARCH_ASSISTANT CASCADE;
DROP TABLE IF EXISTS CO_INVESTIGATOR CASCADE;
DROP TABLE IF EXISTS PROJECT CASCADE;
DROP TABLE IF EXISTS GRAD_STUDENT CASCADE;
DROP TABLE IF EXISTS DEPARTMENT CASCADE;
DROP TABLE IF EXISTS PROFESSOR CASCADE;

-- ============================================================
-- 1. DEPARTMENT
-- ============================================================
-- Attributes from ER diagram:
-- dept_no, dept_name, main_office
--
-- chairman_ssn is added to represent the 1:1 "chairs" relationship.
-- It is initially nullable because DEPARTMENT and PROFESSOR reference
-- each other. NOT NULL is added after sample chairmen are inserted.

CREATE TABLE DEPARTMENT (
    dept_no INT PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL,
    main_office VARCHAR(100),
    chairman_ssn VARCHAR(20)
);

-- ============================================================
-- 2. PROFESSOR
-- ============================================================
-- Attributes from ER diagram:
-- ssn, name, age, gender, rank, research_specialty
--
-- dept_no implements the "works_in" relationship:
-- each professor works in exactly one department.

CREATE TABLE PROFESSOR (
    ssn VARCHAR(20) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    age INT,
    gender VARCHAR(10),
    rank VARCHAR(50),
    research_specialty VARCHAR(100),
    dept_no INT NOT NULL,

    CONSTRAINT fk_professor_department
        FOREIGN KEY (dept_no)
        REFERENCES DEPARTMENT(dept_no)
);

-- ============================================================
-- 3. PROJECT
-- ============================================================
-- Attributes from ER diagram:
-- project_no, sponsor_name, start_date, end_date, budget
--
-- pi_ssn implements the 1:N "manages" relationship:
-- each project has exactly one PI.

CREATE TABLE PROJECT (
    project_no INT PRIMARY KEY,
    sponsor_name VARCHAR(100),
    start_date DATE,
    end_date DATE,
    budget NUMERIC(12,2),
    pi_ssn VARCHAR(20) NOT NULL,

    CONSTRAINT fk_project_pi
        FOREIGN KEY (pi_ssn)
        REFERENCES PROFESSOR(ssn),

    CONSTRAINT chk_project_dates
        CHECK (end_date >= start_date),

    CONSTRAINT chk_project_budget
        CHECK (budget >= 0)
);

-- ============================================================
-- 4. GRAD_STUDENT
-- ============================================================
-- Attributes from ER diagram:
-- ssn, name, age, gender, degree_program
--
-- dept_no implements "majors_in".
-- advisor_ssn implements the recursive "advises" relationship.
--
-- advisor_ssn is initially nullable so that a most-senior sample
-- graduate student can be inserted without creating a circular
-- foreign-key dependency. The project assumption is that this
-- student represents the most-senior student in the sample data.

CREATE TABLE GRAD_STUDENT (
    ssn VARCHAR(20) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    age INT,
    gender VARCHAR(10),
    degree_program VARCHAR(20),
    dept_no INT NOT NULL,
    advisor_ssn VARCHAR(20),

    CONSTRAINT fk_grad_student_department
        FOREIGN KEY (dept_no)
        REFERENCES DEPARTMENT(dept_no),

    CONSTRAINT fk_grad_student_advisor
        FOREIGN KEY (advisor_ssn)
        REFERENCES GRAD_STUDENT(ssn),

    CONSTRAINT chk_grad_student_self_advisor
        CHECK (advisor_ssn IS NULL OR advisor_ssn <> ssn)
);

-- ============================================================
-- 5. CO_INVESTIGATOR
-- ============================================================
-- Implements the M:N relationship between PROFESSOR and PROJECT
-- for project co-investigators.

CREATE TABLE CO_INVESTIGATOR (
    project_no INT,
    professor_ssn VARCHAR(20),

    PRIMARY KEY (project_no, professor_ssn),

    CONSTRAINT fk_co_investigator_project
        FOREIGN KEY (project_no)
        REFERENCES PROJECT(project_no)
        ON DELETE CASCADE,

    CONSTRAINT fk_co_investigator_professor
        FOREIGN KEY (professor_ssn)
        REFERENCES PROFESSOR(ssn)
);

-- ============================================================
-- 6. RESEARCH_ASSISTANT
-- ============================================================
-- Implements the M:N "assists" relationship between
-- GRAD_STUDENT and PROJECT.

CREATE TABLE RESEARCH_ASSISTANT (
    project_no INT,
    student_ssn VARCHAR(20),

    PRIMARY KEY (project_no, student_ssn),

    CONSTRAINT fk_research_assistant_project
        FOREIGN KEY (project_no)
        REFERENCES PROJECT(project_no)
        ON DELETE CASCADE,

    CONSTRAINT fk_research_assistant_student
        FOREIGN KEY (student_ssn)
        REFERENCES GRAD_STUDENT(ssn)
);

-- ============================================================
-- 7. DEPARTMENT CHAIRMAN CONSTRAINTS
-- ============================================================
-- The ER diagram shows a 1:1 "chairs" relationship.
-- UNIQUE ensures one professor cannot chair multiple departments.
-- NOT NULL ensures every department has a chairman after sample
-- data is populated.

ALTER TABLE DEPARTMENT
ADD CONSTRAINT fk_department_chairman
FOREIGN KEY (chairman_ssn)
REFERENCES PROFESSOR(ssn);

ALTER TABLE DEPARTMENT
ADD CONSTRAINT unique_department_chairman
UNIQUE (chairman_ssn);

-- ============================================================
-- 8. SAMPLE DATA: DEPARTMENTS
-- ============================================================

INSERT INTO DEPARTMENT
    (dept_no, dept_name, main_office)
VALUES
    (10, 'Computer Science', 'Engineering Building'),
    (20, 'Mathematics', 'Science Building'),
    (30, 'Physics', 'Science Building');

-- ============================================================
-- 9. SAMPLE DATA: PROFESSORS
-- ============================================================

INSERT INTO PROFESSOR
    (ssn, name, age, gender, rank, research_specialty, dept_no)
VALUES
    ('111', 'John Smith', 55, 'M', 'Professor',
     'Artificial Intelligence', 10),

    ('222', 'Sarah Lee', 48, 'F', 'Associate Professor',
     'Database Systems', 10),

    ('333', 'Michael Brown', 52, 'M', 'Professor',
     'Applied Mathematics', 20),

    ('444', 'Emily Davis', 45, 'F', 'Associate Professor',
     'Quantum Physics', 30),

    ('555', 'David Wilson', 40, 'M', 'Assistant Professor',
     'Machine Learning', 10);

-- ============================================================
-- 10. SAMPLE DATA: DEPARTMENT CHAIRMEN
-- ============================================================

UPDATE DEPARTMENT
SET chairman_ssn = '111'
WHERE dept_no = 10;

UPDATE DEPARTMENT
SET chairman_ssn = '333'
WHERE dept_no = 20;

UPDATE DEPARTMENT
SET chairman_ssn = '444'
WHERE dept_no = 30;

-- Now that every sample department has a chairman, enforce
-- the mandatory participation shown by the ER design.

ALTER TABLE DEPARTMENT
ALTER COLUMN chairman_ssn SET NOT NULL;

-- ============================================================
-- 11. SAMPLE DATA: GRADUATE STUDENTS
-- ============================================================
-- Robert Anderson is used as the most-senior sample graduate
-- student. His advisor is NULL because there is no more-senior
-- graduate student represented in this sample dataset.

INSERT INTO GRAD_STUDENT
    (ssn, name, age, gender, degree_program, dept_no, advisor_ssn)
VALUES
    ('600', 'Robert Anderson', 32, 'M', 'PhD', 10, NULL),

    ('601', 'Alex Johnson', 25, 'M', 'PhD', 10, '600'),

    ('602', 'Maria Garcia', 24, 'F', 'MS', 10, '600'),

    ('603', 'Kevin White', 27, 'M', 'PhD', 20, '600'),

    ('604', 'Jessica Miller', 23, 'F', 'MS', 30, '600'),

    ('605', 'Daniel Clark', 26, 'M', 'PhD', 10, '600');

-- ============================================================
-- 12. SAMPLE DATA: PROJECTS
-- ============================================================

INSERT INTO PROJECT
    (project_no, sponsor_name, start_date, end_date, budget, pi_ssn)
VALUES
    (1001, 'National Science Foundation',
     '2026-01-01', '2027-12-31', 150000.00, '111'),

    (1002, 'NASA',
     '2026-03-01', '2027-06-30', 200000.00, '333'),

    (1003, 'Department of Energy',
     '2026-06-01', '2028-05-31', 175000.00, '444');

-- ============================================================
-- 13. SAMPLE DATA: CO-INVESTIGATORS
-- ============================================================
-- Each project has two sample co-investigators.
-- The Part III faculty_restrict trigger will later enforce
-- the maximum of four CO-PIs.

INSERT INTO CO_INVESTIGATOR
    (project_no, professor_ssn)
VALUES
    (1001, '222'),
    (1001, '555'),

    (1002, '111'),
    (1002, '444'),

    (1003, '222'),
    (1003, '333');

-- ============================================================
-- 14. SAMPLE DATA: RESEARCH ASSISTANTS
-- ============================================================
-- Each project has two sample graduate student assistants.
-- Alex Johnson works on two projects, which is allowed by
-- the Part III student_restrict requirement.

INSERT INTO RESEARCH_ASSISTANT
    (project_no, student_ssn)
VALUES
    (1001, '601'),
    (1001, '602'),

    (1002, '603'),
    (1002, '604'),

    (1003, '605'),
    (1003, '601');

COMMIT;

-- ============================================================
-- 15. VERIFICATION QUERIES
-- ============================================================
-- These SELECT statements do not change the database.
-- They are included so you can verify the populated data.

-- Departments
SELECT * FROM DEPARTMENT
ORDER BY dept_no;

-- Professors
SELECT * FROM PROFESSOR
ORDER BY ssn;

-- Graduate students and their advisors
SELECT
    s.name AS student,
    a.name AS advisor,
    s.degree_program,
    s.dept_no
FROM GRAD_STUDENT s
LEFT JOIN GRAD_STUDENT a
    ON s.advisor_ssn = a.ssn
ORDER BY s.ssn;

-- Projects and their PI
SELECT
    p.project_no,
    p.sponsor_name,
    p.start_date,
    p.end_date,
    p.budget,
    prof.name AS principal_investigator
FROM PROJECT p
JOIN PROFESSOR prof
    ON p.pi_ssn = prof.ssn
ORDER BY p.project_no;

-- Co-investigators
SELECT
    ci.project_no,
    prof.name AS co_investigator
FROM CO_INVESTIGATOR ci
JOIN PROFESSOR prof
    ON ci.professor_ssn = prof.ssn
ORDER BY ci.project_no, prof.name;

-- Research assistants
SELECT
    ra.project_no,
    gs.name AS research_assistant
FROM RESEARCH_ASSISTANT ra
JOIN GRAD_STUDENT gs
    ON ra.student_ssn = gs.ssn
ORDER BY ra.project_no, gs.name;

-- Complete project summary
SELECT
    p.project_no,
    p.sponsor_name,
    pi.name AS principal_investigator,
    COUNT(DISTINCT ci.professor_ssn) AS co_investigators,
    COUNT(DISTINCT ra.student_ssn) AS research_assistants
FROM PROJECT p
JOIN PROFESSOR pi
    ON p.pi_ssn = pi.ssn
LEFT JOIN CO_INVESTIGATOR ci
    ON p.project_no = ci.project_no
LEFT JOIN RESEARCH_ASSISTANT ra
    ON p.project_no = ra.project_no
GROUP BY p.project_no, p.sponsor_name, pi.name
ORDER BY p.project_no;

-- Row counts
SELECT 'DEPARTMENT' AS table_name, COUNT(*) AS total_records
FROM DEPARTMENT
UNION ALL
SELECT 'PROFESSOR', COUNT(*) FROM PROFESSOR
UNION ALL
SELECT 'PROJECT', COUNT(*) FROM PROJECT
UNION ALL
SELECT 'GRAD_STUDENT', COUNT(*) FROM GRAD_STUDENT
UNION ALL
SELECT 'CO_INVESTIGATOR', COUNT(*) FROM CO_INVESTIGATOR
UNION ALL
SELECT 'RESEARCH_ASSISTANT', COUNT(*) FROM RESEARCH_ASSISTANT;
