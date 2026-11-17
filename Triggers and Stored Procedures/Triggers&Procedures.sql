------------------
A)
------------------

CREATE OR REPLACE FUNCTION female_faculty()
RETURNS NUMERIC(5,2)
LANGUAGE plpgsql
AS $$
DECLARE
    total_faculty INTEGER;
    female_count INTEGER;
    percentage NUMERIC(5,2);
BEGIN
    SELECT COUNT(*)
    INTO total_faculty
    FROM PROFESSOR;

    SELECT COUNT(*)
    INTO female_count
    FROM PROFESSOR
    WHERE gender = 'F';

    IF total_faculty = 0 THEN
        RETURN 0;
    END IF;

    percentage :=
        (female_count * 100.0) / total_faculty;

    RETURN percentage;
END;
$$;

---------------------

test SELECT female_faculty();

---------------------
B)
---------------------

CREATE OR REPLACE FUNCTION total_people(pno INTEGER)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    pi_count INTEGER;
    copi_count INTEGER;
    student_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO pi_count
    FROM PROJECT
    WHERE project_no = pno;

    SELECT COUNT(*)
    INTO copi_count
    FROM CO_INVESTIGATOR
    WHERE project_no = pno;

    SELECT COUNT(*)
    INTO student_count
    FROM RESEARCH_ASSISTANT
    WHERE project_no = pno;

    RETURN pi_count + copi_count + student_count;
END;
$$;

-------------------------

test SELECT total_people(1001);

-------------------------
c)
-------------------------

CREATE OR REPLACE FUNCTION check_faculty_limit()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    faculty_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO faculty_count
    FROM CO_INVESTIGATOR
    WHERE project_no = NEW.project_no;

    IF faculty_count >= 4 THEN
        RAISE EXCEPTION
        'A project cannot have more than 4 Co-Investigators';
    END IF;

    RETURN NEW;
END;
$$;

-------------------------
CREATE TRIGGER faculty_restrict
BEFORE INSERT ON CO_INVESTIGATOR
FOR EACH ROW
EXECUTE FUNCTION check_faculty_limit();

-------------------------
D)
-------------------------
CREATE OR REPLACE FUNCTION check_student_limit()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    project_count INTEGER;
BEGIN
    SELECT COUNT(DISTINCT project_no)
    INTO project_count
    FROM RESEARCH_ASSISTANT
    WHERE student_ssn = NEW.student_ssn;

    IF project_count >= 2 THEN
        RAISE EXCEPTION
        'A student cannot work on more than 2 projects';
    END IF;

    RETURN NEW;
END;
$$;
----------------------------
CREATE TRIGGER student_restrict
BEFORE INSERT ON RESEARCH_ASSISTANT
FOR EACH ROW
EXECUTE FUNCTION check_student_limit();


-----------------------------
TESTING
-----------------------------

INSERT INTO CO_INVESTIGATOR
VALUES
(1001, '333'),
(1001, '444');

WORKS FINE
------------------------------
INSERT INTO CO_INVESTIGATOR
VALUES (1001, '111'); 

RESULTS IN ERROR

-----------------------------

INSERT INTO RESEARCH_ASSISTANT
VALUES (1002, '601');

RESULTS IN ERROR