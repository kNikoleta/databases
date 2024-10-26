
/*
======================================================================================================================================================

--------------------------------------------------------------------------------2.1-------------------------------------------------------------------

======================================================================================================================================================
*/

CREATE TYPE public.program_type AS ENUM (
    'Normal',
    'ForeignLanguage',
    'Seasonal'
);


-- FUNCTION: public.create_students(integer, integer)

-- DROP FUNCTION IF EXISTS public.create_students(integer, integer);

CREATE OR REPLACE FUNCTION public.create_students(
	year integer,
	num integer)
    RETURNS TABLE(am character, name character varying, surname character varying, amka character, email text) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
DECLARE
	cnt integer:=0;
	i integer:=0;
	am character(10);
	g_amka character(11); 
	na character varying;
	email text;
	sex character(1):='n';
	fn character varying;
	sn character varying;
BEGIN	
<<loop1>>
loop
	i=i+1;
	
	SELECT create_person() INTO g_amka;
	SELECT pe.name INTO na FROM "Person" pe WHERE pe.amka=g_amka;
	SELECT pe.surname INTO sn FROM "Person" pe WHERE pe.amka=g_amka;
	SELECT pe.father_name INTO fn FROM "Person" pe WHERE pe.amka=g_amka;
	SELECT pe.email INTO email FROM "Person" pe WHERE pe.amka=g_amka;

    SELECT create_am(year) INTO am;

	INSERT INTO "Student" (amka, am, entry_date)
    VALUES (
        g_amka, 
        am,
        TO_DATE(year::text || lpad(floor(random() * 12 + 1)::integer::text, 2, '0') || lpad(floor(random() * 28 + 1)::integer::text, 2, '0'), 'YYYYMMDD')

    );

	RETURN QUERY
	SELECT am, na, sn, g_amka,email ;
EXIT loop1 WHEN i=num;	
end loop;
END;
$BODY$;

ALTER FUNCTION public.create_students(integer, integer)
    OWNER TO postgres;

------------------------------------------------------------------------------------------------------------------------------------------------------
-- FUNCTION: public.create_professor(integer)

-- DROP FUNCTION IF EXISTS public.create_professor(integer);

CREATE OR REPLACE FUNCTION public.create_professor(
	num integer)
    RETURNS TABLE(name character varying, surname character varying, amka character, email text, lab_joins integer, prank rank_type) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
DECLARE
	cnt integer:=0;
	i integer:=0;
	lab_joins integer;
	prank rank_type;
	g_amka character(11); 
	na character varying;
	email text;
	fn character varying;
	sn character varying;
BEGIN	
<<loop1>>
loop
	i=i+1;
	
	SELECT create_person() INTO g_amka;
	SELECT pe.name INTO na FROM "Person" pe WHERE pe.amka=g_amka;
	SELECT pe.surname INTO sn FROM "Person" pe WHERE pe.amka=g_amka;
	SELECT pe.father_name INTO fn FROM "Person" pe WHERE pe.amka=g_amka;
	SELECT pe.email INTO email FROM "Person" pe WHERE pe.amka=g_amka;
	
	SELECT prankaki FROM unnest(enum_range(NULL::rank_type)) prankaki ORDER BY random() LIMIT 1 INTO prank;

    SELECT random_lab_id() INTO lab_joins;

	INSERT INTO "Professor" (amka, labjoins, rank)
    VALUES (
        g_amka, 
        lab_joins,
       	prank
    );

	RETURN QUERY
	SELECT na, sn, g_amka,email,lab_joins,prank ;
EXIT loop1 WHEN i=num;	
end loop;
END;
$BODY$;

ALTER FUNCTION public.create_professor(integer)
    OWNER TO postgres;
------------------------------------------------------------------------------------------------------------------------------------------------------
-- FUNCTION: public.create_lab_teacher(integer)

-- DROP FUNCTION IF EXISTS public.create_lab_teacher(integer);

CREATE OR REPLACE FUNCTION public.create_lab_teacher(
	num integer)
    RETURNS TABLE(name character varying, surname character varying, amka character, email text, works_in integer, flat level_type) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
DECLARE
	cnt integer:=0;
	i integer:=0;
	works_in integer;
	flat level_type;
	g_amka character(11); 
	na character varying;
	email text;
	fn character varying;
	sn character varying;
BEGIN	
<<loop1>>
loop
	i=i+1;
	
	SELECT create_person() INTO g_amka;
	SELECT pe.name INTO na FROM "Person" pe WHERE pe.amka=g_amka;
	SELECT pe.surname INTO sn FROM "Person" pe WHERE pe.amka=g_amka;
	SELECT pe.father_name INTO fn FROM "Person" pe WHERE pe.amka=g_amka;
	SELECT pe.email INTO email FROM "Person" pe WHERE pe.amka=g_amka;
	
	SELECT levelaki FROM unnest(enum_range(NULL::level_type)) levelaki ORDER BY random() LIMIT 1 INTO flat;

    SELECT random_lab_id() INTO works_in;

	INSERT INTO "LabTeacher" (amka, labworks, level)
    VALUES (
        g_amka, 
        works_in,
       	flat
    );

	RETURN QUERY
	SELECT na, sn, g_amka,email,works_in,flat ;
EXIT loop1 WHEN i=num;	
end loop;
END;
$BODY$;

ALTER FUNCTION public.create_lab_teacher(integer)
    OWNER TO postgres;

------------------------------------------------------------------------------------------------------------------------------------------------------

-- FUNCTION: public.create_person()

-- DROP FUNCTION IF EXISTS public.create_person();

CREATE OR REPLACE FUNCTION public.create_person(
	)
    RETURNS character
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	cnt integer:=0;
	num integer:=1;
	amka character(11); 
	na character varying;
	email text;
	sex character(1):='n';
	fn character varying;
	sn character varying;
BEGIN	
	
	SELECT COUNT(*) + 1 INTO cnt FROM "Person";
	SELECT create_amka(cnt) INTO amka;
	
	SELECT n.name,n.sex INTO na,sex FROM random_names(num) n ;
	SELECT adapt_surname(s.surname,sex) INTO sn FROM random_surnames(num) s ;
	SELECT random_father_names() INTO fn; 
 	SELECT convert_greek_to_latin(sn) || floor(random() * 90 + 10)::text || '@tuc.gr'INTO email;
	
	INSERT INTO "Person" (amka, name, father_name, surname, email)
    VALUES (
        amka,
        na,
        fn,
        sn,
        email
    );
	
	RETURN amka;
END;
$BODY$;

ALTER FUNCTION public.create_person()
    OWNER TO postgres;
------------------------------------------------------------------------------------------------------------------------------------------------------

-- FUNCTION: public.random_names(integer)

-- DROP FUNCTION IF EXISTS public.random_names(integer);

CREATE OR REPLACE FUNCTION public.random_names(
	n integer)
    RETURNS TABLE(name character varying, sex character, id integer) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
	RETURN QUERY
	SELECT nam.name, nam.sex, row_number() OVER ()::integer
	FROM (SELECT "Name".name, "Name".sex
		  FROM "Name"
		  ORDER BY random() LIMIT n) as nam;
END;
$BODY$;

ALTER FUNCTION public.random_names(integer)
    OWNER TO postgres;
------------------------------------------------------------------------------------------------------------------------------------------------------

-- FUNCTION: public.random_surnames(integer)

-- DROP FUNCTION IF EXISTS public.random_surnames(integer);

CREATE OR REPLACE FUNCTION public.random_surnames(
	n integer)
    RETURNS TABLE(surname character varying, id integer) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
	RETURN QUERY --RETURN QUERY appends the results of executing a query to the function's result set. RETURN NEXT and RETURN QUERY can be freely intermixed in a single set-returning function, in which case their results will be concatenated
	SELECT snam.surname, row_number() OVER ()::integer --The ROW_NUMBER() function is a window function that assigns a sequential integer to each row in a result set. The set of rows on which the ROW_NUMBER() function operates is called a window.
	FROM (SELECT "Surname".surname
		  FROM "Surname"
	      WHERE right("Surname".surname,2)='ΗΣ'
		  ORDER BY random() LIMIT n) as snam; --generates random numbers, one for each row, and then sorts by them. So it results in n rows being presented in a random order
END;
$BODY$;

ALTER FUNCTION public.random_surnames(integer)
    OWNER TO postgres;
------------------------------------------------------------------------------------------------------------------------------------------------------
-- FUNCTION: public.random_father_names()

-- DROP FUNCTION IF EXISTS public.random_father_names();

CREATE OR REPLACE FUNCTION public.random_father_names(
	)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
 
DECLARE
	fname character varying;
BEGIN
    
     SELECT nam.name FROM "Name" nam WHERE nam.sex='M' ORDER BY random()
 	INTO fname;
 	return fname;
END;
$BODY$;

ALTER FUNCTION public.random_father_names()
    OWNER TO postgres;
------------------------------------------------------------------------------------------------------------------------------------------------------
-- FUNCTION: public.random_lab_id()

-- DROP FUNCTION IF EXISTS public.random_lab_id();

CREATE OR REPLACE FUNCTION public.random_lab_id(
	)
    RETURNS integer
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
 
DECLARE
	lab_id integer;
BEGIN
    
     SELECT l.lab_code FROM "Lab" l ORDER BY random()
 	INTO lab_id;
 	return lab_id;
END;
$BODY$;

ALTER FUNCTION public.random_lab_id()
    OWNER TO postgres;
------------------------------------------------------------------------------------------------------------------------------------------------------

-- FUNCTION: public.adapt_surname(character varying, character)

-- DROP FUNCTION IF EXISTS public.adapt_surname(character varying, character);

CREATE OR REPLACE FUNCTION public.adapt_surname(
	surname character varying,
	sex character)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
DECLARE
result character varying;
BEGIN
	result = surname;
	IF right(surname,2)<>'ΗΣ' THEN
		RAISE NOTICE 'Cannot handle this surname';
		ELSIF sex='F' THEN
			result = left(surname,-1);
			ELSIF sex<>'M' THEN
				RAISE NOTICE 'Wrong sex parameter';
	END IF;
	RETURN result;
END;
$BODY$;

ALTER FUNCTION public.adapt_surname(character varying, character)
    OWNER TO postgres;
------------------------------------------------------------------------------------------------------------------------------------------------------

-- FUNCTION: public.convert_greek_to_latin(text)

-- DROP FUNCTION IF EXISTS public.convert_greek_to_latin(text);

CREATE OR REPLACE FUNCTION public.convert_greek_to_latin(
	greek_text text)
    RETURNS text
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
  latin_text TEXT := '';
BEGIN
  SELECT
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE
		(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE
		(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE
		(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
    greek_text,
    'Α', 'a'),
    'Β', 'b'),
    'Γ', 'g'),
    'Δ', 'd'),
    'Ε', 'e'),
    'Ζ', 'z'),
    'Η', 'i'),
    'Θ', 'th'),
    'Ι', 'i'),
    'Κ', 'k'),
    'Λ', 'l'),
    'Μ', 'm'),
    'Ν', 'n'),
    'Ξ', 'x'),
    'Ο', 'o'),
    'Π', 'p'),
    'Ρ', 'r'),
    'Σ', 's'),
    'Τ', 't'),
    'Υ', 'y'),
    'Φ', 'ph'),
    'Χ', 'ch'),
    'Ψ', 'ps'),
    'Ω', 'o'
  INTO latin_text;
  RETURN latin_text;
END;
$BODY$;

ALTER FUNCTION public.convert_greek_to_latin(text)
    OWNER TO postgres;

------------------------------------------------------------------------------------------------------------------------------------------------------

-- FUNCTION: public.create_am(integer)

-- DROP FUNCTION IF EXISTS public.create_am(integer);

CREATE OR REPLACE FUNCTION public.create_am(
	yr integer)
    RETURNS character
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
DECLARE
	cnt integer;
BEGIN

	SELECT COUNT(*) + 1 INTO cnt FROM "Student" WHERE am LIKE yr::text ||'%';
	 
	RETURN concat(yr::character(4), floor(RANDOM()*(2))::character(1),lpad(cnt::text, 5, '0')); --cast(expression as target_type) or ::. LPAD() function returns a string left-padded to length characters.
END;
$BODY$;

ALTER FUNCTION public.create_am(integer)
    OWNER TO postgres;

------------------------------------------------------------------------------------------------------------------------------------------------------
 -- FUNCTION: public.create_amka(integer)

-- DROP FUNCTION IF EXISTS public.create_amka(integer);

CREATE OR REPLACE FUNCTION public.create_amka(
	id integer)
    RETURNS character
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN

	RETURN concat( lpad(floor(RANDOM()*(28-1)+1)::character(2),2,'0'),lpad(floor(RANDOM()*(12-1)+1)::character(2),2,'0'),right(floor(RANDOM()*(2005-1960)+1960)::character(4),2),lpad(id::text,5,'0')); --cast(expression as target_type) or ::. LPAD() function returns a string left-padded to length characters.
END;
$BODY$;

ALTER FUNCTION public.create_amka(integer)
    OWNER TO postgres;

 

/*
=========================================================================================================================================================

--------------------------------------------------------------------------------2.2----------------------------------------------------------------------

=========================================================================================================================================================
 */

-- FUNCTION: public.grade_students(integer)
--DROP FUNCTION IF EXISTS public.grade_students(integer);

CREATE OR REPLACE FUNCTION public.grade_students(
	semester_id integer)
    RETURNS VOID
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE

AS $BODY$
BEGIN

	--temp tables
	CREATE TEMPORARY TABLE semester_courses AS 
	SELECT * 
	FROM FindAllSemesterCourses(semester_id); --find the courses
 
	UPDATE "Register" r
	SET exam_grade = random_grade()
	WHERE r.exam_grade IS NULL AND (r.course_code, r.serial_number) 
	IN (SELECT sc.course_code, sc.serial_number 
		FROM "semester_courses" sc);

	UPDATE "Register" r 
	SET lab_grade = random_grade()
	FROM "semester_courses" semester_courses
	WHERE r.lab_grade IS NULL AND (r.course_code, r.serial_number) 
	IN (SELECT sc.course_code, sc.serial_number 
		FROM "semester_courses" sc);
		
	UPDATE "Register" r 
	SET final_grade = calcFinal(r.lab_grade,r.exam_grade,cr.exam_percentage,cr.exam_min,cr.lab_min)
	FROM "semester_courses" semester_courses, "CourseRun" cr
	WHERE (r.course_code, r.serial_number ) 
	IN (SELECT sc.course_code, sc.serial_number 
		FROM "semester_courses" sc)
	AND cr.course_code=r.course_code 
	AND cr.serial_number=r.serial_number;
		
	
	
	DROP table semester_courses;

END;
$BODY$;

ALTER FUNCTION public.grade_students(integer)
    OWNER TO postgres;


------------------------------------------------------------------------------------------------------------------------------------------------------

-- FUNCTION: public.findallsemestercourses(integer)

-- DROP FUNCTION IF EXISTS public.findallsemestercourses(integer);

CREATE OR REPLACE FUNCTION public.findallsemestercourses(
	semester_id integer)
    RETURNS TABLE(course_code character, serial_number integer) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
    RETURN QUERY
    SELECT cr.course_code,cr.serial_number
	FROM "CourseRun" cr
	WHERE cr.semesterrunsin=semester_id;
END;
$BODY$;

ALTER FUNCTION public.findallsemestercourses(integer)
    OWNER TO postgres;
------------------------------------------------------------------------------------------------------------------------------------------------------

-- FUNCTION: public.random_grade()

-- DROP FUNCTION IF EXISTS public.random_grade();

CREATE OR REPLACE FUNCTION public.random_grade(
	)
    RETURNS integer
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	grade integer;
BEGIN
   grade := floor(random() * 10) + 1;
   RETURN grade;
END;
$BODY$;

ALTER FUNCTION public.random_grade()
    OWNER TO postgres;

------------------------------------------------------------------------------------------------------------------------------------------------------

--DROP FUNCTION IF EXISTS public.calcFinal(numeric,numeric,numeric,numeric,numeric);

CREATE OR REPLACE FUNCTION public.calcFinal(
	lab_grade numeric,
	exam_grade numeric,
	exam_percentage numeric,
	exam_min numeric,
	lab_min numeric)
    RETURNS numeric 
    LANGUAGE 'plpgsql'

AS $BODY$
BEGIN
	IF exam_grade < exam_min THEN
		RETURN 0;
	ELSIF exam_percentage = 0 THEN
		RETURN exam_grade;
	ELSIF lab_grade < lab_min THEN
		RETURN 0;
	ELSE
		RETURN ((exam_grade * exam_percentage)/100 + (lab_grade *(100 - exam_percentage)/100));
	END IF;	
END;
$BODY$;

ALTER FUNCTION public.calcFinal(numeric,numeric,numeric,numeric,numeric)
    OWNER TO postgres;


/*
======================================================================================================================================================

--------------------------------------------------------------------------------2.3-------------------------------------------------------------------

======================================================================================================================================================
 */


CREATE OR REPLACE FUNCTION public.insert_curicculum(
	program program_type,
	language character varying,
	season semester_season_type,
	start_year integer,
	duration integer,
	mincourses integer,
	mincredits integer,
	obligatory boolean,
	committeenum integer,
	diplomatype diploma_type)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
    max_start_year INTEGER;
    program_id INTEGER;
	numOfparts integer;
	apoplants integer;
	semester_id integer;
	unitid integer;
BEGIN
	SELECT COUNT(*) + 1 INTO unitid FROM "CustomUnits" ;
	numOfparts:= (RANDOM()*190 +10);
	apoplants:= (RANDOM()*(numOfparts-15)+5);
	
	SELECT MAX(pr."ProgramID") 
	INTO program_id
	FROM "Program" pr;
	
	program_id:=program_id+1;
	
	IF ($1='Normal') THEN 
   		SELECT MAX(pr."Year") INTO max_start_year 
		FROM "Program" pr 
		WHERE NOT EXISTS (SELECT 1
						  FROM "SeasonalProgram" sp,  "ForeignLanguageProgram" fp
						  WHERE sp."ProgramID" = pr."ProgramID" OR fp."ProgramID" = pr."ProgramID" );
 		
		IF start_year <= max_start_year THEN
        	RAISE EXCEPTION 'Start year must be after %', max_start_year;
			RETURN;
    	END IF;
		
		PERFORM insertProgram(program_id,duration,$6,$7,$8,$9,$10,numOfparts,start_year::character(4));
		
		INSERT INTO "Joins"("StudentAMKA","ProgramID")
		VALUES(
			programCandidates(start_year,numOfparts),
			program_id
		);
 		
		INSERT INTO "ProgramOffersCourse"("ProgramID","CourseCode")
		VALUES(
			 program_id, 
			returnCourseCodes(MinCourses)			
		);
 
 		
 	ELSIF ($1='ForeignLanguage') THEN 
		SELECT MAX(pr."Year") INTO max_start_year 
		FROM "Program" pr,"ForeignLanguageProgram" fp 
		WHERE fp."ProgramID" = pr."ProgramID";
		
		IF start_year <= max_start_year THEN
        	RAISE EXCEPTION 'Start year must be after %', max_start_year;
			RETURN;
    	END IF;
		
		PERFORM insertProgram(
        program_id, 
        duration,
       	$6,
		$7,
		$8,
		$9,
		$10,
		numOfparts,
		start_year::character(4));
		
		INSERT INTO "ForeignLanguageProgram"("ProgramID","Language")
		VALUES(
			program_id,
			$2
		);
		
		INSERT INTO "Joins"("StudentAMKA","ProgramID")
		VALUES(
			external_students(start_year,numOfparts,apoplants),
			program_id
		);
		
		INSERT INTO "Joins"("StudentAMKA","ProgramID")
		VALUES(
			(SELECT d."StudentAMKA" 
			FROM "Diploma" d 
			WHERE NOT EXISTS (SELECT d."ProgramID"
			FROM "SeasonalProgram" sp,  "ForeignLanguageProgram" fp
			WHERE sp."ProgramID" = d."ProgramID" OR fp."ProgramID"=d."ProgramID")
			LIMIT apoplants),
			program_id
		);
		
		INSERT INTO "ProgramOffersCourse"("ProgramID","CourseCode")
		VALUES(
			 program_id, 
			 return_course_codes_of_current_semester(MinCourses)			
		);
 		

		
	ELSE
		SELECT MAX(pr."Year") INTO max_start_year 
		FROM "Program" pr, "SeasonalProgram" sp 
		WHERE sp."ProgramID" = pr."ProgramID";
		
		IF start_year <= max_start_year THEN
        	RAISE EXCEPTION 'Start year must be after %', max_start_year;
			RETURN;
    	END IF;
		
		PERFORM insertProgram(
        program_id, 
        duration,
       	$6,
		$7,
		$8,
		$9,
		$10,
		numOfparts,
		start_year::character(4));
		
		INSERT INTO "SeasonalProgram"("ProgramID","Season")
		VALUES(
			program_id,
			$3
		);
		
		INSERT INTO "Joins"("StudentAMKA","ProgramID")
		VALUES(
			students_2_3(numOfParts),
			 program_id
		);
		
		SELECT s.semester_id 
		INTO semester_id
		FROM "Semester" s
		WHERE s.academic_year = start_year AND s.academic_season = $3;
		
		PERFORM insert_unit(
				program_id ,
				unitid,
				ARRAY(SELECT co."course_code"
				FROM "Course" co ORDER BY random() LIMIT (2*MinCourses))
		);
		
	
	END IF;
    
	
						 
END;
$BODY$;

-- FUNCTION: public.insertprogram(integer, integer, integer, integer, boolean, integer, diploma_type, integer, character)

-- DROP FUNCTION IF EXISTS public.insertprogram(integer, integer, integer, integer, boolean, integer, diploma_type, integer, character);

CREATE OR REPLACE FUNCTION public.insertprogram(
	programid integer,
	duration integer,
	mincourses integer,
	mincredits integer,
	obligatory boolean,
	committeenum integer,
	diplomatype diploma_type,
	numofparticipants integer,
	year character)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
 
BEGIN
	INSERT INTO "Program"(  
		"ProgramID" ,
		"Duration" , 
		"MinCourses" ,
		"MinCredits" ,
		"Obligatory" ,
		"CommitteeNum" ,
		"DiplomaType" ,
		"NumOfParticipants" ,
		"Year" 	
	) VALUES (
        $1, 
        $2,
       	$3,
		$4,
		$5,
		$6,
		$7,
		$8,
		$9
    );
						
END;
$BODY$;

ALTER FUNCTION public.insertprogram(integer, integer, integer, integer, boolean, integer, diploma_type, integer, character)
    OWNER TO postgres;

----------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.insert_unit(
	programid integer,
	unit_name integer,
	code character[])
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
 DECLARE
        semester_id INTEGER := 0;
		credits integer:=0;
		course character(7);
    BEGIN 
	   -- Get present semester id
        SELECT s.semester_id INTO semester_id
            FROM "Semester" s
                WHERE s.semester_status = 'present';
				
		INSERT INTO public."CustomUnits"(
		"CustomUnitID", "SeasonalProgramID", "Credits")
		VALUES (unit_name, programid, NULL);

		
		FOR course IN (SELECT unnest(code)) 
		LOOP
			INSERT INTO "RefersTo"("CustomUnitID", "SeasonalProgramID", "CourseRunCode", "CourseRunSerial")
				VALUES( unit_name,
						programid,
						course,
						(SELECT cr.serial_number FROM "CourseRun" cr 
						WHERE cr.course_code = course LIMIT 1)
					   );
		END LOOP;
		
		SELECT SUM(c.units)
		INTO credits
		FROM "Course" c
		WHERE c.course_code = ANY(code);
		
		UPDATE public."CustomUnits" cu
		SET "Credits" = credits
		WHERE cu."SeasonalProgramID" = programID;
END;
$BODY$;

ALTER FUNCTION public.insert_unit(integer, integer, character[])
    OWNER TO postgres;
	


------------------------------------------------------------------------------------------------------------------------------------------------------


--DROP FUNCTION IF EXISTS programCandidates(integer,integer); 
CREATE OR REPLACE FUNCTION programCandidates(start_year integer,numOfparts integer)
RETURNS TABLE(amka character(11)) AS
$$
BEGIN
	DELETE FROM "Joins" j 
	WHERE j."StudentAMKA" IN (
	SELECT s."amka" 
	FROM "Student" s
	WHERE NOT EXISTS (
		SELECT j."StudentAMKA" FROM "Joins" j,"SeasonalProgram" s 
		WHERE j."ProgramID" = s."ProgramID"
	)
	AND LEFT(s.am,4)::integer>=start_year LIMIT numOfParts);

	RETURN QUERY
	SELECT s.amka::character(11)
	FROM "Student" s
	WHERE LEFT(s.am,4)::integer>=start_year
			AND NOT EXISTS (SELECT j."StudentAMKA" FROM "Joins" j,"SeasonalProgram" s 
					 WHERE j."ProgramID" = s."ProgramID")
	LIMIT numOfParts;
    
END;
$$
LANGUAGE 'plpgsql' VOLATILE;--IMMUTABLE meaning that the output of the function can be expected to be the same if the inputs are the same.


--------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.returnCourseCodes(MinCourses integer
	)
    RETURNS TABLE(courseCode character(7))
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE

BEGIN
	RETURN QUERY
    SELECT co."course_code"
			FROM "Course" co ORDER BY random() LIMIT MinCourses;
END;
$BODY$;
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- FUNCTION: public.returncoursecodesofcurrentsemester(integer)

-- DROP FUNCTION IF EXISTS public.returncoursecodesofcurrentsemester(integer);

CREATE OR REPLACE FUNCTION public.return_course_codes_of_current_semester(
	mincourses integer)
    RETURNS TABLE(coursecode character) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
DECLARE

BEGIN
	RETURN QUERY
    SELECT co."course_code"
			FROM "Course" co 
			JOIN "CourseRun" cr ON co."course_code"= cr.course_code
			JOIN "Semester" s ON s.semester_id=cr.semesterrunsin
			WHERE s."semester_status"='present'
			ORDER BY random() LIMIT (2*MinCourses);
END;
$BODY$;

ALTER FUNCTION public.return_course_codes_of_current_semester(integer)
    OWNER TO postgres;

--------------------------------------------------------------------------------------------------------------------------------------------------------
--drop function external_students( integer, integer,  integer);
CREATE OR REPLACE FUNCTION public.external_students(start_year integer,numOfParts integer, apoplants integer
	)
    RETURNS TABLE(amka VARCHAR)
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE

BEGIN
	RETURN QUERY
    SELECT s.amka FROM "Student" s
			WHERE LEFT(s.am,5)=start_year||'1' LIMIT (numOfParts-apoplants);
END;
$BODY$;
------------------------------------------------------------------------------------------------------------------------------------------------------
 
CREATE OR REPLACE FUNCTION public.students_2_3( numOfParts integer 
	)
    RETURNS TABLE(amka VARCHAR)
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE

BEGIN
	RETURN QUERY
    SELECT s."amka" FROM "Student" s
			 LIMIT numOfParts;
END;
$BODY$; 

/*
======================================================================================================================================================

--------------------------------------------------------------------------------2.4-------------------------------------------------------------------

======================================================================================================================================================
*/

-- FUNCTION: public.insert_thesis(character, character varying, integer)

-- DROP FUNCTION IF EXISTS public.insert_thesis(character, character varying, integer);

CREATE OR REPLACE FUNCTION public.insert_thesis(
	student_am character,
	title character varying,
	program_id integer)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	obl boolean;
	thesis_id integer:=0;
	thesis_grade integer;
	diploma_num integer:=0;
	dipl_grade numeric;
	student_amka character(11);
	committee_num integer;
BEGIN
	
	SELECT s.amka INTO student_amka FROM "Student" s WHERE s.am=student_am;
	
	SELECT pr."Obligatory" INTO obl FROM "Program"pr WHERE pr."ProgramID"=program_id;
	
	IF obl THEN
		/*SELECT MAX("ThesisID") INTO thesis_id FROM "Thesis";
		IF thesis_id=NULL THEN
			thesis_id:=0;
		ELSE 
			thesis_id:=thesis_id+1;
		END IF;*/
		SELECT COALESCE(MAX("ThesisID"), 0) + 1 INTO thesis_id FROM "Thesis";
		RAISE Notice 'mpro';
		
		thesis_grade:=FLOOR(RANDOM() * 5) + 5;
		
			INSERT INTO public."Thesis"(
			"ThesisID", "Grade", "Title", "StudentAMKA", "ProgramID")
			VALUES (thesis_id, thesis_grade, title, student_amka, program_id);

			SELECT "CommitteeNum" INTO committee_num FROM "Program" pr WHERE pr."ProgramID" = program_id;

			--bres kathigites
			INSERT INTO public."Committee"(
			"ProfessorAMKA", "ThesisID", "Supervisor")
			SELECT p.amka, thesis_id, false
			FROM "Professor" p 
			JOIN "Teaches" t USING ("amka")
			JOIN "CourseRun" cr ON t.serial_number=cr.serial_number AND cr.course_code=t.course_code
			JOIN "ProgramOffersCourse" poc ON poc."CourseCode"=cr.course_code
			WHERE poc."ProgramID"=program_id LIMIT committee_num;
			
			UPDATE public."Committee" 
			SET "Supervisor"=true
			WHERE "ProfessorAMKA"=(SELECT c."ProfessorAMKA" FROM "Committee" c ORDER BY RANDOM() LIMIT 1 );
			
			IF typeOfProgram(program_id)='seasonal'
				THEN
				
				SELECT SUM(r.final_grade*calcMultiplier(c.units)) INTO dipl_grade
				FROM "Register" r 
				JOIN "CourseRun" cr ON r.serial_number = cr.serial_number AND cr.course_code = r.course_code
				JOIN "Course" c ON cr.course_code = c.course_code
				JOIN "RefersTo" rt ON rt."CourseRunCode" = cr.course_code
				JOIN "Program" p ON p."ProgramID" = rt."SeasonalProgramID";
				
				dipl_grade:=(dipl_grade*0.8)+(thesis_grade*0.2);
							
			ELSE 
					dipl_grade=gradeDiploma(student_am,program_id);
					dipl_grade:=(dipl_grade*0.8)+(thesis_grade*0.2);
			END IF;
 
			SELECT MAX("DiplomaNum") INTO diploma_num FROM "Diploma";
			diploma_num:=diploma_num+1;

			INSERT INTO "Diploma" ("DiplomaNum", "DiplomaGrade", "DiplomaTitle", "StudentAMKA", "ProgramID")
			VALUES( diploma_num, dipl_grade , title, student_amka, program_id); 

	ELSE
			IF typeOfProgram(program_id)='seasonal'
				THEN
				
				SELECT SUM(r.final_grade*calcMultiplier(c.units)) INTO dipl_grade
				FROM "Register" r 
				JOIN "CourseRun" cr ON r.serial_number = cr.serial_number AND cr.course_code = r.course_code
				JOIN "Course" c ON cr.course_code = c.course_code
				JOIN "RefersTo" rt ON rt."CourseRunCode" = cr.course_code
				JOIN "Program" p ON p."ProgramID" = rt."SeasonalProgramID";
				
				dipl_grade:=(dipl_grade*0.8)+(thesis_grade*0.2);
							
			ELSE
					dipl_grade=gradeDiploma(student_am,program_id);
					dipl_grade:=(dipl_grade*0.8)+(thesis_grade*0.2);
			END IF;
			  
			  
			SELECT MAX("DiplomaNum") INTO diploma_num FROM "Diploma";
			diploma_num:=diploma_num+1;

			INSERT INTO "Diploma" ("DiplomaNum", "DiplomaGrade", "DiplomaTitle", "StudentAMKA", "ProgramID")
			VALUES( diploma_num, dipl_grade , title, student_amka, program_id); 

	
	END IF;
	
	
END;
$BODY$;

ALTER FUNCTION public.insert_thesis(character, character varying, integer)
    OWNER TO postgres;


--------------------------------------------------------------

-- DROP FUNCTION IF EXISTS public.typeOfProgram(integer);

CREATE OR REPLACE FUNCTION public.typeOfProgram(
	programid integer)
    RETURNS text
    LANGUAGE 'plpgsql'
    COST 100
  

AS $BODY$
DECLARE
	ptype text;
BEGIN
	
     
	IF NOT EXISTS(SELECT 1 FROM "ProgramOffersCourse" p WHERE p."ProgramID"=programid
			 )THEN 
			 ptype='seasonal';
			 return ptype ;
	END IF;
	
	RETURN Null;
END;
$BODY$; 

-------------------------------------------------------------


-- DROP FUNCTION IF EXISTS public.gradeDiploma(integer);
CREATE OR REPLACE FUNCTION public.gradeDiploma(student_am character(10), programid integer)
    RETURNS integer
    LANGUAGE plpgsql
    COST 100
AS $BODY$
DECLARE
	student_amka character(11);
	grade_epiloghs numeric;
	grade numeric;
	finalG numeric;
	totalCourses integer;
	totalOblCourses integer;
	exist boolean;
BEGIN
	WITH am AS (
		SELECT * FROM readytograduate(programid) 
	)
	SELECT EXISTS (SELECT 1 FROM am WHERE am  = student_am) INTO exist;
	
	SELECT s.amka INTO student_amka FROM "Student" s WHERE s.am=student_am;
	
	IF exist THEN
		
		SELECT COUNT(*) , SUM(r.final_grade*calcMultiplier(c.units)) INTO totalOblCourses,grade
		FROM "Register" r
		JOIN "Course" c USING("course_code")
		JOIN "ProgramOffersCourse" poc ON poc."CourseCode" = c.course_code 
		JOIN "Program" p ON p."ProgramID" = poc."ProgramID"
		WHERE r.register_status='pass' AND c.obligatory = true AND r.amka = student_amka AND poc."ProgramID" = programid;
		
		SELECT SUM(r.final_grade*calcMultiplier(c.units)) , p."MinCourses" INTO grade_epiloghs, totalCourses
		FROM "Register" r 
		JOIN "Course" c USING("course_code")
		JOIN "ProgramOffersCourse" poc ON poc."CourseCode" = c.course_code 
		JOIN "Program" p ON p."ProgramID" = poc."ProgramID"
		WHERE r.register_status='pass' AND c.obligatory = false  AND r.amka = student_amka AND poc."ProgramID" = programid
		ORDER BY grade_epiloghs DESC
		LIMIT p.MinCourses - totalOblCourses;
		
		finalG:=FLOOR(grade+grade_epiloghs/totalCourses);
		
		RETURN finalG ;
	ELSE 
		RETURN NULL;
	END IF;

END;
$BODY$;

---------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.calcMultiplier(units integer)
    RETURNS numeric
    LANGUAGE plpgsql
    COST 100
AS $BODY$
BEGIN
	IF units = 5 THEN 
		RETURN 2;
	ELSIF units<5 AND units>2 THEN
		RETURN 1.5;
	ELSE
		RETURN 1;
	END IF;
END;
$BODY$;


/*
======================================================================================================================================================

-----------------------------------------------------------------------------3.1----------------------------------------------------------------------

----------------------------------------------Αναζήτηση προσωπικών στοιχείων φοιτητών με βάση τον αριθμό μητρώου--------------------------------------
======================================================================================================================================================
*/

-- FUNCTION: public.find_student(character)

-- DROP FUNCTION IF EXISTS public.find_student(character);

CREATE OR REPLACE FUNCTION public.find_student(
	g_am character)
    RETURNS TABLE(amka character varying, nam character varying, father_name character varying, surname character varying, email character, entry_date date) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
DECLARE
	v_amka character(11);
BEGIN
	
	RETURN QUERY
	SELECT pe.amka,pe.name,pe.father_name,pe.surname,CAST(pe.email AS character(30)),s.entry_date
	FROM "Person" pe,"Student" s WHERE s.am=g_am AND pe.amka=s.amka; 
	
END;
$BODY$;

ALTER FUNCTION public.find_student(character)
    OWNER TO postgres;

/*
======================================================================================================================================================

-----------------------------------------------------------------------------3.2----------------------------------------------------------------------

-------------------------------------------Ανάκτηση ονοματεπωνύμου και αριθμού μητρώου για τους φοιτητές που παρακολουθούν ένα------------------------
----------------------------------------------συγκεκριμένο μάθημα του τρέχοντος εξαμήνου για το οποίο δίνεται ο κωδικός του---------------------------
======================================================================================================================================================
 */

-- FUNCTION: public.find_student_by_course(character)

-- DROP FUNCTION IF EXISTS public.find_student_by_course(character);

CREATE OR REPLACE FUNCTION public.find_student_by_course(
	coursecode character)
    RETURNS TABLE(amka character varying, name character varying, surname character varying, am character) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
 
BEGIN
	
	RETURN QUERY
	SELECT r.amka,pe.name,pe.surname,s.am 
	FROM "Person" pe,"Student" s, "Register" r , "Semester" se, "CourseRun" cr
	WHERE pe.amka=s.amka AND r.amka=s.amka AND r.course_code=courseCode
	AND cr.course_code = r.course_code AND cr.serial_number = r.serial_number 
	AND se.semester_id = cr.semesterrunsin AND se.semester_status = 'present';
	
END;
$BODY$;

ALTER FUNCTION public.find_student_by_course(character)
    OWNER TO postgres;

/*
======================================================================================================================================================

-----------------------------------------------------------------------------3.3----------------------------------------------------------------------

------------------------------------------------Ανάκτηση του ονοματεπωνύμου όλων των προσώπων και χαρακτηρισμό τους-----------------------------------
-----------------------------------------------------(καθηγητές ή εργαστηριακό προσωπικό ή φοιτητές).-------------------------------------------------
----------------------------------------------Το αποτέλεσμα είναι πλειάδες της μορφής: επώνυμο, όνομα, χαρακτηρισμός.---------------------------------
======================================================================================================================================================
 */

CREATE OR REPLACE FUNCTION public.allPeople()
    RETURNS TABLE(surname varchar, name varchar, roles text) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
    
	RETURN QUERY
    SELECT pe.surname, pe.name, 'Student'
	FROM "Person" pe
	INNER JOIN "Student" s ON pe.amka = s.amka;
	
	RETURN QUERY
    SELECT pe.surname, pe.name, 'Professor'
	FROM "Person" pe
	INNER JOIN "Professor" pr ON pe.amka = pr.amka;
	
	RETURN QUERY
    SELECT pe.surname, pe.name, 'Lab Teacher'
	FROM "Person" pe
	INNER JOIN "LabTeacher" te ON pe.amka = te.amka;
	
END;
$BODY$;



/*
======================================================================================================================================================

-----------------------------------------------------------------------------3.4----------------------------------------------------------------------

------------------------------------------Ανάκτηση των υποχρεωτικών μαθημάτων που δεν έχει ακόμη παρακολουθήσει επιτυχώς ένας-------------------------
--------------------------------------------συγκεκριμένος φοιτητής για να μπορέσει να αποφοιτήσει από ένα συγκεκριμένο--------------------------------
-----------------------------------------------πρόγραμμα σπουδών. Ο κωδικός του προγράμματος θα δίνεται ως όρισμα.------------------------------------
======================================================================================================================================================
 */
-- FUNCTION: public.giaptyxio(integer, character varying)

-- DROP FUNCTION IF EXISTS public.giaptyxio(integer, character varying);

CREATE OR REPLACE FUNCTION public.giaptyxio(
	programid integer,
	amkaki character varying)
    RETURNS TABLE(course_code character, course_title character) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
    RETURN QUERY
	SELECT c.course_code, c.course_title
    FROM "Course" c JOIN "ProgramOffersCourse" o ON  c.course_code = o."CourseCode"
		AND o."ProgramID" = ProgramID 
    JOIN "Register" r ON  r.course_code = o."CourseCode" AND r.amka = amkaki
    WHERE c.obligatory = TRUE 
	AND r.register_status = 'fail'; 

END;
$BODY$;

ALTER FUNCTION public.giaptyxio(integer, character varying)
    OWNER TO postgres;


/*
======================================================================================================================================================

-----------------------------------------------------------------------------3.5----------------------------------------------------------------------

-----------------------------------------Εύρεση του τομέα ή των τομέων όπου εκπονήθηκαν οι περισσότερες εργασίες βάσει του---------------------------- 
-------------------------------------------τύπου τους (χρήση του πεδίου DiplomaType). Ο τομέας εκπόνησης προκύπτει από το-----------------------------
--------------------------------------------------εργαστήριο στο οποίο είναι ενταγμένος ο επιβλέπων καθηγητής.----------------------------------------
======================================================================================================================================================
 */
-- FUNCTION: public.findsectors()

-- DROP FUNCTION IF EXISTS public.findsectors();

CREATE OR REPLACE FUNCTION public.findsectors(
	)
    RETURNS TABLE(code integer, diplomatype diploma_type) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
 
BEGIN
	 RETURN QUERY
        SELECT s.sector_code,p."DiplomaType"
        FROM "Program" p
            JOIN "Thesis" t USING ("ProgramID")
            JOIN "Committee" c USING ("ThesisID")
            JOIN "Professor" prof ON c."ProfessorAMKA" = prof.amka
            JOIN "Lab" l ON prof.labjoins = l.lab_code
            JOIN "Sector" s USING (sector_code)
        WHERE c."Supervisor"
        GROUP BY s.sector_code,p."DiplomaType"
            HAVING 
                COUNT(s.sector_code) >= ALL (
                    SELECT COUNT(s.sector_code)
                    FROM "Program" p2
                        JOIN "Thesis" t2 USING ("ProgramID")
                        JOIN "Committee" c2 USING ("ThesisID")
                        JOIN "Professor" ON (c2."ProfessorAMKA" = "Professor".amka)
                        JOIN "Lab" ON ("Professor".labjoins = "Lab".lab_code)
                        JOIN "Sector" s USING (sector_code)
                    WHERE c2."Supervisor" AND p2."DiplomaType" = p."DiplomaType"
                    GROUP BY s.sector_code);

END;
$BODY$;

ALTER FUNCTION public.findsectors()
    OWNER TO postgres;


/*
======================================================================================================================================================

-----------------------------------------------------------------------------3.6----------------------------------------------------------------------

----------------------------------------Ανάκτηση του αριθμού μητρώου των φοιτητών που ικανοποιούν τις προϋποθέσεις αποφοίτησης------------------------
--------------------------------------και δεν έχουν ακόμη αποφοιτήσει για ένα συγκεκριμένο τυπικό ή ξενόγλωσσο πρόγραμμα σπουδών.---------------------
======================================================================================================================================================
 */

-- FUNCTION: public.readytograduate(integer)

-- DROP FUNCTION IF EXISTS public.readytograduate(integer);

CREATE OR REPLACE FUNCTION public.readytograduate(
	programid integer)
    RETURNS TABLE(am character) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
DECLARE
	min_courses integer;
	min_credits integer;
	obligatory boolean;
BEGIN
	SELECT pr."MinCourses",pr."MinCredits",pr."Obligatory"
	INTO min_courses,min_credits,obligatory
	FROM "Program" pr
	WHERE pr."ProgramID" = ProgramID;
	
    RETURN QUERY
	SELECT DISTINCT s.am
	FROM "Student" s
	JOIN "Register" r USING("amka")
    JOIN "Joins" j ON r.amka = j."StudentAMKA"
	JOIN "ProgramOffersCourse" oc ON oc."ProgramID" = j."ProgramID" AND oc."ProgramID" = ProgramID
    WHERE NOT EXISTS (SELECT 1
    FROM "Diploma" d 
    WHERE d."StudentAMKA" =  s."amka" ) 
	AND (SELECT COUNT(*) FROM "Register" r
		 WHERE r.register_status='pass')>=min_courses
	AND r.amka IN (SELECT t."StudentAMKA" FROM "Thesis" t
				  WHERE t."ProgramID"=ProgramID AND obligatory=true AND t."Grade">5)
	AND (SELECT SUM(c.units) FROM "Register" r, "Course" c
		 WHERE r.register_status='pass' AND c.course_code=r.course_code)>=min_credits; 

END;
$BODY$;

ALTER FUNCTION public.readytograduate(integer)
    OWNER TO postgres;



/*
======================================================================================================================================================

-----------------------------------------------------------------------------3.7----------------------------------------------------------------------

----------------------------------------Εύρεση του φόρτου όλου του εργαστηριακού προσωπικού το τρέχον εξάμηνο.---------------------------------------- 
-------------Ο φόρτος υπολογίζεται ως το άθροισμα των ωρών εργαστηρίου για τα μαθήματα που υποστηρίζει κάθε μέλος του εργαστηριακού προσωπικού.------- 
--------------------------------------Το αποτέλεσμα είναι πλειάδες της μορφής: ΑΜΚΑ,επώνυμο, όνομα, άθροισμα ωρών.------------------------------------
------------------------------------Κάθε πλειάδα του αποτελέσματος αντιστοιχεί σε ένα μέλος εργαστηριακού προσωπικού.--------------------------------- 
----------------------Στο αποτέλεσμα να εμφανίζονται όλα τα μέλη εργαστηριακού προσωπικού, ακόμη και αν έχουν μηδενικό φόρτο.-------------------------
======================================================================================================================================================
 */

--DROP FUNCTION IF EXISTS labHours( integer);
CREATE OR REPLACE FUNCTION labHours(SemasterID integer)
RETURNS TABLE(amka VARCHAR, name VARCHAR, surname VARCHAR, lab_hours bigint ) 
AS $$ 
BEGIN
	RETURN QUERY
	SELECT pr.amka, pr.name, pr.surname, SUM(c.lab_hours) 
	FROM "Person" pr
	JOIN "LabTeacher" lt ON pr.amka=lt.amka
	JOIN "Lab" l ON l.lab_code=lt.labworks
	JOIN "CourseRun" cr ON cr.labuses=l.lab_code
	JOIN "Course" c ON c.course_code = cr.course_code 
	JOIN "Semester" s ON cr.semesterrunsin=s.semester_id AND s.semester_id = SemasterID
	GROUP BY pr.amka, pr.name, pr.surname;
END;
$$ LANGUAGE plpgsql;


/*
======================================================================================================================================================

-----------------------------------------------------------------------------3.8----------------------------------------------------------------------

----------------------------------Ανάκτηση όλων των μαθημάτων που είναι προαπαιτούμενα ή συνιστώμενα, άμεσα ή έμμεσα,---------------------------------
------------------------------------------για ένα συγκεκριμένο μάθημα του οποίου δίνεται ο κωδικός.--------------------------------------------------- 
------------------------------------Το αποτέλεσμα είναι πλειάδες της μορφής: κωδικός μαθήματος, τίτλος μαθήματος--------------------------------------
======================================================================================================================================================
 */

CREATE OR REPLACE FUNCTION findChains(lesson character(7))
RETURNS TABLE(code character(7), title character(100) ) 
AS $$ 
BEGIN
	RETURN QUERY
	SELECT cd.dependent,c.course_title
	FROM "Course" c, "Course_depends" cd
	WHERE cd.main = lesson AND c.course_code = cd.dependent;


END;
$$ LANGUAGE plpgsql;



/*
======================================================================================================================================================

-----------------------------------------------------------------------------3.9----------------------------------------------------------------------

---------------------------------Ανάκτηση των ονομάτων όλων των καθηγητών που συμμετέχουν σε όλους τους τύπους προγραμμάτων σπουδών-------------------
======================================================================================================================================================
 */

-- DROP FUNCTION IF EXISTS public.find_all_professors();

CREATE OR REPLACE FUNCTION public.find_all_professors(
	)
    RETURNS TABLE(amka VARCHAR,name character varying, surname character varying ,pid integer) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN 	 

 return query
	WITH 
	typicalANDforeign AS(
		SELECT pr.amka,pr.name,pr.surname,poc."ProgramID"
		FROM "Person" pr
		JOIN "Professor" prof ON prof.amka = pr.amka
		JOIN "Teaches" te ON te."amka"=prof.amka
		JOIN "CourseRun" cr ON cr.course_code = te.course_code AND cr.serial_number = te.serial_number
		JOIN "ProgramOffersCourse" poc ON poc."CourseCode" = cr.course_code
		JOIN "ForeignLanguageProgram" fp ON fp."ProgramID"=poc."ProgramID"	
	),
	seasonal AS(
		SELECT pr.amka,pr.name,pr.surname,cu."SeasonalProgramID"
		FROM "Person" pr
		JOIN "Professor" prof ON prof.amka = pr.amka
		JOIN "Teaches" te ON te."amka"=prof.amka
		JOIN "CourseRun" cr ON cr.course_code = te.course_code AND cr.serial_number = te.serial_number
		JOIN "RefersTo" rt ON cr."course_code"=rt."CourseRunCode" AND cr."serial_number" = rt."CourseRunSerial"
		JOIN "CustomUnits" cu ON rt."SeasonalProgramID"=cu."SeasonalProgramID"
	)
   

	SELECT * FROM seasonal 	  
	WHERE EXISTS(select 1 from typicalANDforeign);


END;
$BODY$;

ALTER FUNCTION public.find_all_professors()
    OWNER TO postgres;



/*
======================================================================================================================================================

------------------------------------------------------------------------4.1.1 TRIGGERS----------------------------------------------------------------

----------------------------------------------------Kατά την εισαγωγή νέου μελλοντικού εξαμήνου (κατάσταση «future»)---------------------------------- 
------------------------------------------θα γίνεται έλεγχος ορθότητας με βάση τις ημερομηνίες έναρξης και λήξης έτσι ώστε να μην---------------------
---------------------------------------επικαλύπτεται με κανένα άλλο καταχωρημένο εξάμηνο και να ακολουθεί χρονικά το τρέχον εξάμηνο-------------------
======================================================================================================================================================
 */

-- Table: public.semester_audit

-- DROP TABLE IF EXISTS public.semester_audit;

CREATE TABLE IF NOT EXISTS public.semester_audit
(
    op character varying COLLATE pg_catalog."default",
    ts timestamp without time zone NOT NULL,
    start_date date,
    end_date date,
    semester_status semester_status_type NOT NULL
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.semester_audit
    OWNER to postgres;

---------------------------------------------------------------------------

-- FUNCTION: public.check_future_semester()

-- DROP FUNCTION IF EXISTS public.check_future_semester();

-- FUNCTION: public.check_future_semester()

-- DROP FUNCTION IF EXISTS public.check_future_semester();

CREATE OR REPLACE FUNCTION public.check_future_semester()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
   current_semester "Semester"%ROWTYPE;
BEGIN
    SELECT * INTO current_semester FROM "Semester" WHERE semester_status = 'present';

    IF (NEW.semester_status = 'future' AND EXISTS (SELECT 1 FROM "Semester"
        WHERE 
		 (NEW.start_date, NEW.end_date) OVERLAPS (start_date, end_date))
    ) THEN
        RAISE EXCEPTION 'New semester overlaps with existing semesters';
        RETURN NULL; 
    ELSIF NEW.semester_status = 'future' AND (
        current_semester.end_date >= NEW.start_date
    ) THEN
        RAISE EXCEPTION 'New semester does not follow current semester in time';
        RETURN NULL; 
	ELSIF NEW.semester_status = 'future' AND (
         NEW.end_date <= NEW.start_date  
    ) THEN
		 RAISE EXCEPTION 'Ooops we dont have a time machine!';
        RETURN NULL;
    END IF;
    RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.check_future_semester()
    OWNER TO postgres;

---------------------------------------------------------------------------------------
-- Trigger: trigger_semestcheck

-- DROP TRIGGER IF EXISTS trigger_semestcheck ON public."Semester";

CREATE TRIGGER tr_semester_check
    BEFORE INSERT
    ON public."Semester"
    FOR EACH ROW
    WHEN (new.semester_status = 'future'::semester_status_type)
    EXECUTE FUNCTION public.check_future_semester();

/*
======================================================================================================================================================

------------------------------------------------------------------------4.1.2 TRIGGERS-----------------------------------------------------------------

---------------------------------κατά την μεταβολή ενός μελλοντικού εξαμήνου σε τρέχον (ενημέρωση από future σε 
----------------------------------present) θα γίνεται αυτόματη ενημέρωση του προηγούμενου τρέχοντος σε κατάσταση 
-----------------------------------«past». Θα λαμβάνουν χώρα όλοι οι απαιτούμενοι έλεγχοι συνέπειας ως προς τις 
---------------------------------ημερομηνίες έναρξης και λήξης εξαμήνων έτσι ώστε να υπάρχει σωστή χρονική ακολουθία.
======================================================================================================================================================
 */

-- FUNCTION: public.update_previous_semester_status()

-- DROP FUNCTION IF EXISTS public.update_previous_semester_status();

CREATE OR REPLACE FUNCTION public.update_previous_semester_status()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
  current_semester "Semester"%ROWTYPE;
BEGIN
	-- Find the current semester
	SELECT * INTO current_semester FROM "Semester" WHERE semester_status = 'present';

	IF (OLD.semester_status = 'future' AND NEW.semester_status = 'present' 
		AND EXISTS (SELECT 1 FROM "Semester"
					WHERE  semester_status <> 'future' 
					AND (NEW.start_date, NEW.end_date) OVERLAPS (start_date, end_date))
	) THEN
		RAISE EXCEPTION 'New semester overlaps with existing semesters';
		RETURN OLD;
	ELSIF NEW.semester_status = 'future' AND (
        current_semester.end_date >= NEW.start_date
    ) THEN
        RAISE EXCEPTION 'New semester does not follow current semester in time';
        RETURN OLD; 
	ELSIF NEW.semester_status = 'future' AND (
         NEW.end_date <= NEW.start_date  
    ) THEN
		 RAISE EXCEPTION 'Ooops we dont have a time machine!';
        RETURN OLD;
	ELSE -- Update the previous current semester to past
		UPDATE "Semester" s SET semester_status = 'past'
		WHERE semester_status = 'present';
	END IF; 
		
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.update_previous_semester_status()
    OWNER TO postgres;

---------------------------------------------------------------
CREATE TRIGGER tr_update_future 
BEFORE UPDATE ON "Semester"
FOR EACH ROW 
WHEN (OLD.semester_status = 'future' AND NEW.semester_status ='present')
EXECUTE FUNCTION  update_previous_semester_status();

/*
======================================================================================================================================================

------------------------------------------------------------------------4.1.3 TRIGGERS----------------------------------------------------------------

---------------------------------κατά την μεταβολή ενός μελλοντικού εξαμήνου σε τρέχον (ενημέρωση από future σε present)------------------------------ 
--------------------θα γίνεται αυτόματη δημιουργία προτεινόμενων εγγραφών φοιτητών σε εξαμηνιαία μαθήματα του τρέχοντος εξαμήνου.---------------------
----------------------------------Δεν επιτρέπεται δύο ή περισσότερα εξάμηνα να είναι ταυτόχρονα σε κατάσταση «present».-------------------------------
======================================================================================================================================================
 */

-- FUNCTION: public.propose_students()

-- DROP FUNCTION IF EXISTS public.propose_students();

CREATE OR REPLACE FUNCTION public.propose_students()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
BEGIN
    IF OLD.semester_status = 'future' AND NEW.semester_status = 'present' 
	
	THEN
			IF (SELECT COUNT(*) FROM "Semester" sem WHERE sem.semester_status = 'present') > 1
			THEN
				RAISE NOTICE 'There are more than two semesters with semester_status: present';
				RETURN OLD;
			END IF;
		
		WITH ta AS(
			SELECT cr.serial_number AS sn, c.course_code AS cc
			FROM "CourseRun" cr
			 JOIN "Course" c ON cr.course_code=c.course_code
			 WHERE cr.semesterrunsin = NEW.semester_id
			 AND c.typical_season = NEW.academic_season LIMIT 30
		)
		
		INSERT INTO "Register"(amka, serial_number, course_code, exam_grade, final_grade, lab_grade, register_status)
			(SELECT st.amka,ta.sn,ta.cc, NULL, NULL ,NULL,'proposed' FROM "Student" st,ta LIMIT 30)
		;
		
		
		
	END IF;

    RETURN NULL;
END;
$BODY$;

ALTER FUNCTION public.propose_students()
    OWNER TO postgres;

CREATE TRIGGER tr_propose
AFTER UPDATE ON "Semester"
FOR EACH ROW EXECUTE FUNCTION propose_students();



/*
======================================================================================================================================================

------------------------------------------------------------------------4.1.4 TRIGGERS-----------------------------------------------------------------

---------------------------------κατά την μεταβολή ενός μελλοντικού εξαμήνου σε τρέχον (ενημέρωση από future σε 
----------------------------------present) θα γίνεται αυτόματη ενημέρωση του προηγούμενου τρέχοντος σε κατάσταση 
-----------------------------------«past». Θα λαμβάνουν χώρα όλοι οι απαιτούμενοι έλεγχοι συνέπειας ως προς τις 
--------------------------------ημερομηνίες έναρξης και λήξης εξαμήνων έτσι ώστε να υπάρχει σωστή χρονική ακολουθία.
======================================================================================================================================================
 */


CREATE OR REPLACE FUNCTION update_semester_status_trigger()
RETURNS TRIGGER 
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    IF (NEW.semester_status = 'past' AND OLD.semester_status = 'present') THEN
        PERFORM grade_students(NEW.semester_id);
        PERFORM insertRegisterStatus(NEW.semester_id);
        RETURN NEW;
    ELSE 
        RETURN NULL;
    END IF;
END;
$BODY$;

CREATE TRIGGER semester_status_trigger
AFTER UPDATE ON "Semester"
FOR EACH ROW
EXECUTE FUNCTION update_semester_status_trigger();
-------------------------------------------------------
 
--DROP FUNCTION IF EXISTS public.calcStatus(numeric);

CREATE OR REPLACE FUNCTION public.calcStatus(
    exam_grade numeric)
    RETURNS register_status_type
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN
    IF final_grade >=5 THEN
        RETURN 'pass';
    ELSE
        RETURN 'fail';
    END IF;
END;
$BODY$;

ALTER FUNCTION public.calcStatus(numeric)
    OWNER TO postgres;

----------------------------------------------------------------
DROP FUNCTION IF EXISTS public.insertRegisterStatus(integer);
CREATE OR REPLACE FUNCTION public.insertRegisterStatus(
    semester_id integer)
    RETURNS VOID
    LANGUAGE 'plpgsql'
AS $BODY$
BEGIN

    WITH semester_courses AS( 
        SELECT * 
        FROM FindAllSemesterCourses(semester_id)) --find the courses
 
    UPDATE "Register" r
    SET register_status = calcStatus(r.exam_grade)
    WHERE r.exam_grade IS NOT NULL AND (r.course_code, r.serial_number) 
    IN (SELECT sc.course_code, sc.serial_number 
        FROM "semester_courses" sc);

END;
$BODY$;

ALTER FUNCTION public.insertRegisterStatus(integer)
    OWNER TO postgres;
------------------------------------------------------------



/*
======================================================================================================================================================

-------------------------------------------------------------------------4.2 TRIGGERS-----------------------------------------------------------------

---------------------------------Δεν θα επιτρέπεται η εισαγωγή προγράμματος σπουδών με έτος έναρξης παλαιότερο από τον πιο πρόσφατο ανά τύπο,---------
---------------------------------------ενώ θα πρέπει να υπάρχει αυτόματος έλεγχος μέγιστου επιτρεπόμενου (από το πρόγραμμα) αριθμού μελών------------- 
----------------------------------------------------------κατά την εισαγωγή μελών επιτροπής διατριβής.------------------------------------------------
======================================================================================================================================================
 */

-- FUNCTION: public.check_program_year_trigger()

-- DROP FUNCTION IF EXISTS public.check_program_year_trigger();

CREATE OR REPLACE FUNCTION public.check_program_year_trigger()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
   latest_year integer;
BEGIN
    IF NEW."ProgramID" IN (SELECT sp."ProgramID" from "SeasonalProgram" sp) THEN --seasonal
        SELECT MAX(pr."Year"::integer)
        INTO latest_year
        FROM "Program" pr
        JOIN "SeasonalProgram" sp ON sp."ProgramID" = pr."ProgramID";

    ELSIF NEW."ProgramID" IN (SELECT fp."ProgramID" from "ForeignLanguageProgram" fp) THEN --foreign language
        SELECT MAX(pr."Year"::integer)
        INTO latest_year
        FROM "Program" pr
        JOIN "ForeignLanguageProgram" fp ON fp."ProgramID" = pr."ProgramID";

    ELSE --typical
        SELECT MAX(pr."Year"::integer)
        INTO latest_year
        FROM "Program" pr
        LEFT JOIN "SeasonalProgram" sp ON sp."ProgramID" = pr."ProgramID"
        LEFT JOIN "ForeignLanguageProgram" fp ON fp."ProgramID" = pr."ProgramID"
        WHERE sp."ProgramID" IS NULL AND fp."ProgramID" IS NULL;

    END IF;

    IF NEW."Year"::integer <= latest_year THEN
        RAISE NOTICE 'Should not insert';
        RETURN NULL;
    ELSE
        RAISE NOTICE 'INSERTING';
        RETURN NEW;
    END IF;


END;
$BODY$;

ALTER FUNCTION public.check_program_year_trigger()
    OWNER TO postgres;




/*
======================================================================================================================================================

-------------------------------------------------------------------------4.3 TRIGGERS-----------------------------------------------------------------

-----------Αυτόματος έλεγχος εγκυρότητας εγγραφής φοιτητή σε εξαμηνιαίο μάθημα ώστε να ικανοποιούνται οι περιορισμοί προ-απαιτούμενων μαθημάτων------- 
--------------------------------και οι συνολικές πιστωτικές μονάδες που θα παρακολουθήσει ο φοιτητής μαζί με το εν λόγω μάθημα------------------------
--------------------------------------------------------να μην υπερβαίνουν τις 50 πιστωτικές μονάδες.-------------------------------------------------
-------------------------Ενεργοποιείται όταν η κατάσταση εγγραφής «register_status» ενημερωθεί από «proposed» ή «requested» σε «approved».------------ 
-------------------------------------------------Αν ο έλεγχος αποτύχει τότε η κατάσταση γίνεται «rejected»--------------------------------------------
======================================================================================================================================================
 */

-- FUNCTION: public.registerstudent()

-- DROP FUNCTION IF EXISTS public.registerstudent();

CREATE OR REPLACE FUNCTION public.registerstudent()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	chainC character(7);
	status register_status_type;
BEGIN
    IF ((new.register_status = 'approved' AND old.register_status = 'proposed') OR (new.register_status = 'approved' AND old.register_status = 'requested') ) THEN
    --   WITH chains AS (
		SELECT * INTO chainC FROM alysidesGiaNaSpas(old.course_code);
	--   )
	   
	   IF chainC <> NULL THEN
	   	SELECT r.register_status INTO status  FROM "Register" r WHERE r.course_code=chainC;
	   ELSE
	   	status:='pass';
	   END IF;
	   IF status='pass'  THEN 
	   		IF countCredits(old.amka,old.course_code)>50 THEN
				UPDATE public."Register" r
				SET  register_status='rejected'
				WHERE r.amka=old.amka AND r.course_code=old.course_code;
				RETURN NULL;
			ELSE
        		RETURN NEW;
			END IF;
		ELSE
			RAISE NOTICE 'Not eligible';
			
			UPDATE public."Register" r
			SET  register_status='rejected'
			WHERE r.amka=old.amka AND r.course_code=old.course_code;
			RETURN NULL;
		END IF;
		
    ELSE 
        RETURN NULL;
    END IF;
END;
$BODY$;

ALTER FUNCTION public.registerstudent()
    OWNER TO postgres;

----------------------------------------
CREATE TRIGGER tr_studentChains
AFTER UPDATE ON "Register"
FOR EACH ROW
 WHEN( (new.register_status = 'approved'::register_status_type AND old.register_status = 'proposed'::register_status_type )
	   OR (new.register_status='approved'::register_status_type AND old.register_status = 'requested'::register_status_type ) )
EXECUTE FUNCTION registerStudent();
---------------------------------------

 
CREATE OR REPLACE FUNCTION public.alysidesGiaNaSpas(
	lesson character)
    RETURNS  character(7) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE

AS $BODY$
DECLARE 
	code character(7);
BEGIN
	  
			WITH RECURSIVE Req(main, chain) AS (
			SELECT dependent as des, main as anc
			FROM "Course_depends"
			WHERE mode='required' and dependent = lesson
			)
	
	SELECT Req.chain INTO code FROM Req   ;
	RETURN
	code;
	--select * from Req;
END;
$BODY$;
 
----------------------------------------------------------------

 
CREATE OR REPLACE FUNCTION public.countCredits(
	s_amka VARCHAR)
    RETURNS  integer
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE

AS $BODY$
DECLARE 
	total integer;
BEGIN

		SELECT SUM(c.units) INTO total
		FROM "Register" r
		JOIN "Course" c ON c.course_code= r.course_code
		WHERE  r.register_status='approved' and r.amka=s_amka;
			
	RETURN total;
END;
$BODY$;
 


/*
======================================================================================================================================================

------------------------------------------------------------------------5.1 VIEWS---------------------------------------------------------------------

----------------------Παρουσίαση κωδικού μαθήματος, τίτλου μαθήματος και ονοματεπωνύμων διδασκόντωνκαθηγητών (διαχωρισμένα με κόμμα)------------------ 
--------------------------------------------για όλα τα εξαμηνιαία μαθήματα του τρέχοντος εξαμήνου.---------------------------------------------------- 
======================================================================================================================================================
 */
 
-- View: public.my_view

-- DROP VIEW public.my_view;

CREATE OR REPLACE VIEW public.my_view
 AS
 SELECT c.course_code||', '::text || c.course_title||', '::text ||(p.name::text || ', '::text) || p.surname::text AS professor
   FROM "Person" p
     JOIN "Teaches" t USING (amka)
     JOIN "CourseRun" cr USING (course_code)
     JOIN "Course" c USING (course_code)
     JOIN "Semester" s ON cr.semesterrunsin = s.semester_id
  WHERE s.semester_status = 'present'::semester_status_type;

ALTER TABLE public.my_view
    OWNER TO postgres;


/*
======================================================================================================================================================

------------------------------------------------------------------------5.2 VIEWS---------------------------------------------------------------------
1.2. (*) Παρουσίαση του ετήσιου βαθμού των φοιτητών και του έτους φοίτησης. Για κάθε φοιτητή 
εμφανίζεται: ο αριθμός μητρώου, το ονοματεπώνυμο, ο ετήσιος βαθμός και το έτος σπουδών. 
Ο ετήσιος βαθμός ενός φοιτητή είναι ο μέσος όρος των βαθμών των μαθημάτων που έχει 
ολοκληρώσει επιτυχώς στο προηγούμενο ακαδημαϊκό έτος. Ο ετήσιος βαθμός υπολογίζεται 
μόνο για τους φοιτητές που έχουν ολοκληρώσει με επιτυχία όλα τα μαθήματα του 
προγράμματος σπουδών των εξαμήνων του προηγούμενου ακαδημαϊκού έτους. Ο 
υπολογισμός είναι ανάλογος με αυτόν για το βαθμό διπλώματος (πολλαπλασιασμός κάθε 
βαθμού με το συντελεστή βαρύτητας του μαθήματος, άθροιση των επιμέρους γινομένων και 
διαίρεση με το άθροισμα των συντελεστών), ωστόσο συμμετέχουν μόνο τα υποχρεωτικά και 
τα κατ’ επιλογήν υποχρεωτικά μαθήματα του προγράμματος σπουδών του προηγούμενου 
έτους, ενώ δεν συμμετέχουν τα επιπλέον μαθήματα που τυχόν ολοκλήρωσε ο φοιτητής.
======================================================================================================================================================
 */
-- View: public.view_5_2

-- DROP VIEW public.view_5_2;

CREATE OR REPLACE VIEW public.view_5_2
 AS
 SELECT s.am AS Am,
    p.name AS NAME,
    p.surname AS SURNAME,
    c.typical_year AS YEAR,
    floor(sum(r.final_grade * calcmultiplier(c.units::integer)) / sum(c.units)::numeric) AS GRADE
   FROM "Person" p
     JOIN "Student" s USING (amka)
     JOIN "Register" r USING (amka)
     JOIN "CourseRun" cr ON cr.course_code = r.course_code AND cr.serial_number = r.serial_number
     JOIN "Semester" sem ON sem.semester_id = cr.semesterrunsin
     JOIN "Course" c ON cr.course_code = c.course_code
     JOIN "ProgramOffersCourse" poc ON poc."CourseCode" = c.course_code
     JOIN "Program" pr ON pr."ProgramID" = poc."ProgramID"
  WHERE r.register_status = 'pass'::register_status_type AND sem.academic_year = ((( SELECT sem_1.academic_year
           FROM "Semester" sem_1
          WHERE sem_1.semester_status = 'present'::semester_status_type)) - 1)
  GROUP BY s.am, p.name, p.surname, c.typical_year;

ALTER TABLE public.view_5_2
    OWNER TO postgres;






