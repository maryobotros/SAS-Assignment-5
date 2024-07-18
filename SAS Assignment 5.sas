***DRAFT - CONFIDENTIAL ATTORNEY WORK PRODUCT***;
/*footnote "DRAFT-CONFIDENTIAL ATTORNEY WORK PRODUCT";*/

/*SAS Assignment 5*/
/*Author: Maryo Botros*/

/*------------------------ Question #1 ------------------------*/
/*Read the Student Grades file in using INFILE*/
/*Read in "Sample Data.csv*/
data student_grades;
	format
		studentID 12.
		semester $char10.
		assignment $char12.
		score 12.;

	informat 
		studentID 12.
		semester $char10.
		assignment $char12.
		score 12.;
	infile "/mount/resdata/2. SAS Assignments & Training Data/Analyst Training Folders/Maryo Botros/Assignment 5/Student Grades.csv"
		lrecl=32767
		firstobs=2
		termstr=crlf
		dlm=','
		missover
		dsd;

	input 
		studentID
		semester
		assignment
		score;
run;


/*------------------------ Question #2 ------------------------*/
/*Collapse the file into one record per student, per semester
and for each student 
	x Determine total number of points earned during each semester excluding extra credit
	x Include a flag variable (0/1) that shows whether the student completed the 
	  extra credit for the Fall semester
	x Should be done in one data step with no proc means or data merges and should
	  have 10 records in the end
	x Drop variables that are no longer relevant 
*/

/*This code doesn't drop the lowest quiz score*/
data student_grades1;
	set student_grades;
	
	/*Determine total points*/
	by studentID semester;
	/*If it's the first semester then set the total_points = score*/
	if first.semester then total_points = score;
	/*Otherwise, add the score to the total_points as long as assignment isn't ec*/
	else if assignment ne 'EXTRA CREDIT' then total_points + score;

	/*Include a flag to determine if they did the ec*/
	if assignment='EXTRA CREDIT' then ec = 1;
	
	/*Drop irrelevant variables*/
/*	drop assignment score;*/
run;


/*This code works but for the whole data set, not for semesters*/
data student_grades2;
	set student_grades;

	/*	if first.semester*/
	if findw(assignment, 'QUIZ') then quiz_score = score;

	retain lowest_score;
	if _n_=1 then lowest_score = 20;
	if quiz_score and quiz_score < lowest_score then lowest_score = quiz_score;
run;


data student_grades2;
	set student_grades;
	by studentid semester;
	retain lowest_score;

	
	/*	if first.semester*/
	if findw(assignment, 'QUIZ') then quiz_score = score;

	

	if first.semester then do;
		lowest_score = 20;

		if quiz_score and quiz_score < lowest_score then lowest_score = quiz_score;
	end;
run;


/************** Final code for question 2 ******************/
data student_grades2;
	set student_grades;
	by studentid semester;
	retain total_excl_ec lowest_quiz_score total_excl_lowest ec;

	/*Initialize some variables for each new semester*/
	if first.semester then do;
		total_excl_ec = 0;
		lowest_quiz_score = 9999;
		total_excl_lowest = 0;
		ec = 0;
	end;

	/*Add up the scores into a total score and exclude the ec*/
	if assignment ne 'EXTRA CREDIT' then do;
		total_excl_ec + score;

		/*If the assignment includes 'QUIZ'*/
		if find(ASSIGNMENT, 'QUIZ') then do;
			/* if the score is less than the lowest_quiz_score*/
			if score < lowest_quiz_score 
			/*set the lowest score equal to the new score*/
				then lowest_quiz_score = score;
		end;
	end;

	/*On the last record for a semester*/
	if last.semester then do;
		/*If total_excl_ec isn't null or 0*/
		if total_excl_ec 
			/*Remove the lowest quiz score from total_excl_ec*/
			then total_excl_lowest = total_excl_ec - lowest_quiz_score;
		/*Otherwise, if total_excl_ec is 0 or null*/
		else total_excl_lowest = total_excl_ec;
	end;

	/*Put a flag for completion of extra credit*/
	if semester = 'FALL' and assignment = 'EXTRA CREDIT' then ec = 1;

	/*Remove the unecessary variables */
	keep studentid semester total_excl_ec total_excl_lowest ec;

	/*Delete any rows withoit a total excluding the lowest*/
	if total_excl_lowest = 0 then delete;
run;


/*------------------------ Question #3 ------------------------*/
/***** Rough code ******/
data student_grades3;
	set student_grades1;
	
	/*Retain the fall_semester and spring_semester by studentid*/
	by studentid;
	retain fall_semester_raw fall_semester_adj spring_semester_raw spring_semester_adj;

	if first.studentid then do;
		fall_semester_raw = 0;
		spring_semester_raw = 0;
		fall_semester_adj = 0;
		spring_semester_adj = 0;
	end;

	if find(semester, 'FALL') then do;
		fall_semester_raw + score;

	end;

	if find(semester, 'SPRING') then do;
		spring_semester_raw + score;
	end;

	if last.studentID;

	fall_semester_raw = fall_semester_raw / 100;
	format fall_semester_raw percent10.;


	keep studentID fall_semester_raw spring_semester_raw;

run;

/************** Final code for question 3 ******************/
data student_grades3;
	set student_grades2;

	/*Retain the fall_semester and spring_semester by studentid*/
	by studentid;
	retain fall_semester_raw fall_semester_adj spring_semester_raw spring_semester_adj;

	/*Initialize and reset variables for each new student*/
	if first.studentid then do;
		fall_semester_raw = 0;
		spring_semester_raw = 0;
		fall_semester_adj = 0;
		spring_semester_adj = 0;
	end;

	/*For the fall semester*/
	if semester = 'FALL' then do;
		fall_semester_raw = total_excl_ec + (3 * ec);
		fall_semester_raw = fall_semester_raw/100;
		format fall_semester_raw percent10.;

		fall_semester_adj = total_excl_lowest + (3 * ec);
		fall_semester_adj = fall_semester_adj/90;
		format fall_semester_adj percent10.2;
	end;
	
	/*For the spring semester*/
	if semester = 'SPRING' then do;
		spring_semester_raw = total_excl_ec;
		spring_semester_raw = spring_semester_raw/100;
		format spring_semester_raw percent10.;

		spring_semester_adj = total_excl_lowest;
		spring_semester_adj = spring_semester_adj/90;
		format spring_semester_adj percent10.2;
	end;

	/*Keep only the last record for each student*/
	if last.studentID;

	/*Only keep relevant variables*/
	keep studentID fall_semester_raw fall_semester_adj spring_semester_raw spring_semester_adj;

run;

/*------------------------ Question #4 ------------------------*/
/*Expand the data */
data student_grades4;
	set student_grades3;
	
	/*For each studentID do the following loop*/
	by studentID;	
	do _n_ = 1 to 4;
		if _n_=1 then do;
			score = fall_semester_raw;
			semester = 'Fall';
			type = 'Raw';
		end;

		if _n_=2 then do;
			score = fall_semester_adj;
			semester = 'Fall';
			type = 'Adjusted';
		end;

		if _n_=3 then do;
			score = spring_semester_raw;
			semester = 'Spring';
			type = 'Raw';
		end;

		if _n_=4 then do;
			score = spring_semester_adj;
			semester = 'Spring';
			type = 'Adjusted';
		end;
	output;
	end;

	/*Format the score to have to percents with two decimal places*/
	format score  percent10.2;

	/*Only keep relevant variables*/
	keep studentID score semester type;

run;