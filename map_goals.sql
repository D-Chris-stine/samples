/*Dashboard View for Typical & Tiered Growth Goal Metrics on MAP Growth Assessments */
ALTER VIEW [dashboards].[vw_map_goals_2022]
AS
WITH
/* MAP Student Demographic Data */
d AS (
SELECT DISTINCT
	 stu.local_student_id AS "student_id"
	,sch.end_date
	,stu.student_id AS "illuminate_student_id"
	,CONCAT(stu.last_name,', ',stu.first_name) AS "student_name"
	,sch.site_name "school_name"
	,mr.homeroom AS "homeroom"
	,sch.[start_date] AS "entry_date"
	,sch.end_date AS "exit_date"
	,CASE
    		WHEN sta.grade_level_id = 1 THEN 'K'
    		WHEN sta.grade_level_id = 2 THEN '1st'
    		WHEN sta.grade_level_id = 3 THEN '2nd'
    		WHEN sta.grade_level_id = 4 THEN '3rd'
    		WHEN sta.grade_level_id = 5 THEN '4th'
    		WHEN sta.grade_level_id = 6 THEN '5th'
    		WHEN sta.grade_level_id = 7 THEN '6th'
    		WHEN sta.grade_level_id = 8 THEN '7th'
    		WHEN sta.grade_level_id = 9 THEN '8th'
    		ELSE NULL END AS "grade_level"     
	,'2022' AS "school_year"
FROM [illuminate].[public_students] stu
	INNER JOIN [custom].[vw_illuminate_student_site_aff] sch ON sch.student_id = stu.student_id
	INNER JOIN [illuminate].[matviews_student_term_aff] sta ON sch.student_id=sta.student_id
		AND sta.entry_date=sch.start_date
	  	AND sta.leave_date IS NULL
	INNER JOIN [google].[master_roster_2022] mr on mr.student_id=stu.local_student_id
WHERE 1=1
	AND sch.start_date > '2021-07-31' -- SY21-22
	AND sch.end_date ='2022-06-30'
	AND sch.site_id != 5901 --Exclude High School Students who don't take MAP.
	),

/* Fall Scores */
f AS (
SELECT DISTINCT
	 stu.local_student_id AS "student_id"
	,map_2022.[nwea_2022_Discipline] AS "subject"
	,map_2022.[nwea_2022_TestPercentile] AS "fall_percentile"
	,map_2022.[nwea_2022_TestRITScore] AS "fall_rit"
	,RANK() OVER(		
		PARTITION BY map_2022.nwea_2022_localstudentid, map_2022.[nwea_2022_TermName], map_2022.[nwea_2022_Discipline]
		ORDER BY map_2022.[nwea_2022_TestStandardError] DESC) best_test
FROM [illuminate].[public_students] stu
	INNER JOIN [custom].[vw_illuminate_student_site_aff] sch ON sch.student_id = stu.student_id
	INNER JOIN [illuminate].[matviews_student_term_aff] sta ON sch.student_id=sta.student_id
		AND sta.entry_date=sch.start_date
		AND sta.leave_date IS NULL
	LEFT JOIN [illuminate].[national_assessments_nwea_2022] map_2022 on map_2022.[student_id] = stu.student_id
WHERE 1=1
	AND sch.start_date > '2021-07-01' -- UPDATE TO REFLECT THE CURRENT SCHOOL YEAR
	AND sch.end_date < '2022-06-30'
	AND map_2022.[nwea_2022_TermName] = 'Fall 2021-2022'
	AND map_2022.[nwea_2022_Discipline] NOT IN ('Math K-12','Science K-12')
	AND CASE
		WHEN sta.grade_level_id IN (1,2)
			AND map_2022.[nwea_2022_TestName] IN ('Growth: Math K-2 FL 2014', 'Growth: Reading K-2 FL 2014')
		THEN 1
		WHEN  sta.grade_level_id IN (3,4,5,6) 
			AND map_2022.[nwea_2022_TestName] IN ('Growth: Math 2-5 FL 2014', 'Growth: Reading 2-5 FL 2014 V2')
		THEN 1
		WHEN  sta.grade_level_id IN (7,8,9) 
			AND map_2022.[nwea_2022_TestName] IN ('Growth: Math 6+ FL 2014', 'Growth: Reading 6+ FL 2014 V2')
		THEN 1
		WHEN  sta.grade_level_id IN (4,5,6) 
			AND map_2022.[nwea_2022_TestName] = 'Growth: Science 3-5 FL 2008'
			THEN 1
		WHEN  sta.grade_level_id IN (7,8,9) 
			AND map_2022.[nwea_2022_TestName] = 'Growth: Science 6-8 FL 2008'
		THEN 1
		ELSE 0 END = 1
		),

/* Winter Scores */
w AS (
SELECT DISTINCT
	 stu.local_student_id AS "student_id"
	,map_2022.[nwea_2022_Discipline] AS "subject"
	,map_2022.[nwea_2022_TestPercentile] AS "winter_percentile"
	,map_2022.[nwea_2022_TestRITScore] AS "winter_rit"
	,RANK() OVER(		
		PARTITION BY map_2022.nwea_2022_localstudentid, map_2022.[nwea_2022_TermName], map_2022.[nwea_2022_Discipline]
		ORDER BY map_2022.[nwea_2022_TestStandardError] DESC) best_test
FROM [illuminate].[public_students] stu
	INNER JOIN [custom].[vw_illuminate_student_site_aff] sch ON sch.student_id = stu.student_id
	INNER JOIN [illuminate].[matviews_student_term_aff] sta ON sch.student_id=sta.student_id
		AND sta.entry_date=sch.start_date
		AND sta.leave_date IS NULL
	LEFT JOIN [illuminate].[national_assessments_nwea_2022] map_2022 on map_2022.[student_id] = stu.student_id
WHERE 1=1
	AND sch.start_date > '2021-07-01' -- UPDATE TO REFLECT THE CURRENT SCHOOL YEAR
	AND sch.end_date < '2022-06-30'
	AND map_2022.[nwea_2022_TermName] = 'Winter 2021-2022'
	AND map_2022.[nwea_2022_Discipline] NOT IN ('Math K-12','Science K-12')
	AND CASE
			WHEN sta.grade_level_id IN (1,2) 
			AND map_2022.[nwea_2022_TestName] IN ('Growth: Math K-2 FL 2014', 'Growth: Reading K-2 FL 2014')
				THEN 1
			WHEN  sta.grade_level_id IN (3,4,5,6) 
			AND map_2022.[nwea_2022_TestName] IN ('Growth: Math 2-5 FL 2014', 'Growth: Reading 2-5 FL 2014 V2')
				THEN 1
			WHEN  sta.grade_level_id IN (7,8,9) 
			AND map_2022.[nwea_2022_TestName] IN ('Growth: Math 6+ FL 2014', 'Growth: Reading 6+ FL 2014 V2')
				THEN 1
			WHEN  sta.grade_level_id IN (4,5,6) 
			AND map_2022.[nwea_2022_TestName] IN ('Growth: Science 3-5 FL 2008')
				THEN 1
			WHEN  sta.grade_level_id IN (7,8,9) 
			AND map_2022.[nwea_2022_TestName] IN ('Growth: Science 6-8 FL 2008')
				THEN 1
			ELSE 0 END = 1
		),

/*spring scores*/
s AS (
SELECT DISTINCT
	 stu.local_student_id AS "student_id"
	,map_2022.[nwea_2022_Discipline] AS "subject"
	,map_2022.[nwea_2022_TestPercentile] AS "spring_percentile"
	,map_2022.[nwea_2022_TestRITScore] AS "spring_rit"
	,RANK() OVER(		
		PARTITION BY map_2022.nwea_2022_localstudentid, map_2022.[nwea_2022_TermName], map_2022.[nwea_2022_Discipline]
		ORDER BY map_2022.[nwea_2022_TestStandardError] DESC) best_test
FROM [illuminate].[public_students] stu
	INNER JOIN [custom].[vw_illuminate_student_site_aff] sch ON sch.student_id = stu.student_id
	INNER JOIN [illuminate].[matviews_student_term_aff] sta ON sch.student_id=sta.student_id
	  AND sta.entry_date=sch.start_date
	  AND sta.leave_date IS NULL
	LEFT JOIN [illuminate].[national_assessments_nwea_2022] map_2022 on map_2022.[student_id] = stu.student_id
WHERE 1=1
	AND sch.start_date > '2021-07-01' -- UPDATE TO REFLECT THE CURRENT SCHOOL YEAR
	AND sch.end_date < '2022-06-30'
	AND map_2022.[nwea_2022_TermName] = 'Spring 2021-2022'
	AND map_2022.[nwea_2022_Discipline] NOT IN ('Math K-12','Science K-12')
	AND CASE
			WHEN sta.grade_level_id IN (1,2) 
			AND map_2022.[nwea_2022_TestName] IN ('Growth: Math K-2 FL 2014', 'Growth: Reading K-2 FL 2014')
				THEN 1
			WHEN  sta.grade_level_id IN (3,4,5,6) 
			AND map_2022.[nwea_2022_TestName] IN ('Growth: Math 2-5 FL 2014', 'Growth: Reading 2-5 FL 2014 V2')
				THEN 1
			WHEN  sta.grade_level_id IN (7,8,9) 
			AND map_2022.[nwea_2022_TestName] IN ('Growth: Math 6+ FL 2014', 'Growth: Reading 6+ FL 2014 V2')
				THEN 1
			WHEN  sta.grade_level_id IN (4,5,6) 
			AND map_2022.[nwea_2022_TestName] = 'Growth: Science 3-5 FL 2008'
				THEN 1
			WHEN  sta.grade_level_id IN (7,8,9) 
			AND map_2022.[nwea_2022_TestName] = 'Growth: Science 6-8 FL 2008'
				THEN 1
			ELSE 0 END = 1
		),
/*MAP typical & tiered growth goal calculations*/
g AS (
SELECT DISTINCT
	 stu.local_student_id "student_id"
	,sta.grade_level_id
	,map_2022.[nwea_2022_Discipline] "subject"
	,map_2022.[nwea_2022_TestRITScore] + map_2022.[nwea_2022_TypicalFallToWinterGrowth] AS "fw_typical_growth_goal"
	,CASE 
		WHEN sta.grade_level_id IN (1,2,3,4)	AND map_2022.[nwea_2022_TestPercentile] BETWEEN 1 AND 50
			THEN ROUND(((map_2022.[nwea_2022_TypicalFallToWinterGrowth]*1.5)+map_2022.[nwea_2022_TestRITScore]),0)
		WHEN sta.grade_level_id IN (1,2,3,4)	AND map_2022.[nwea_2022_TestPercentile] BETWEEN 51 AND 75
			THEN ROUND(((map_2022.[nwea_2022_TypicalFallToWinterGrowth]*1.25)+map_2022.nwea_2022_TestRITScore),0)
		WHEN sta.grade_level_id IN (1,2,3,4)	AND map_2022.[nwea_2022_TestPercentile] BETWEEN 76 AND 100
			THEN ROUND(((map_2022.[nwea_2022_TypicalFallToWinterGrowth]*1)+map_2022.[nwea_2022_TestRITScore]),0)
		WHEN sta.grade_level_id IN (5,6,7,8,9)	AND map_2022.[nwea_2022_TestPercentile] BETWEEN 1 AND 25
			THEN ROUND(((map_2022.[nwea_2022_TypicalFallToWinterGrowth]*2)+map_2022.[nwea_2022_TestRITScore]),0)
		WHEN sta.grade_level_id IN (5,6,7,8,9)	AND map_2022.[nwea_2022_TestPercentile] BETWEEN 26 AND 50
			THEN ROUND(((map_2022.[nwea_2022_TypicalFallToWinterGrowth]*1.75)+map_2022.[nwea_2022_TestRITScore]),0)
		WHEN sta.grade_level_id IN (5,6,7,8,9)	AND map_2022.[nwea_2022_TestPercentile] BETWEEN 51 AND 75 
			THEN ROUND(((map_2022.[nwea_2022_TypicalFallToWinterGrowth]*1.5)+map_2022.[nwea_2022_TestRITScore]),0)
		WHEN sta.grade_level_id IN (5,6,7,8,9)	AND map_2022.[nwea_2022_TestPercentile] BETWEEN 76 AND 100  
			THEN ROUND(((map_2022.[nwea_2022_TypicalFallToWinterGrowth]*1)+map_2022.[nwea_2022_TestRITScore]),0)
		ELSE NULL END AS "fw_tiered_growth_goal"
	,map_2022.[nwea_2022_TestRITScore] + map_2022.[nwea_2022_TypicalFallToSpringGrowth] AS  "fs_typical_growth_goal"
	,CASE 
		WHEN sta.grade_level_id IN (1,2,3,4)	AND map_2022.[nwea_2022_TestPercentile] BETWEEN 1 AND 50
			THEN ROUND(((map_2022.[nwea_2022_TypicalFallToSpringGrowth]*1.5)+map_2022.[nwea_2022_TestRITScore]),0)
		WHEN sta.grade_level_id IN (1,2,3,4)	AND map_2022.[nwea_2022_TestPercentile] BETWEEN 51 AND 75
			THEN ROUND(((map_2022.[nwea_2022_TypicalFallToSpringGrowth]*1.25)+map_2022.nwea_2022_TestRITScore),0)
		WHEN sta.grade_level_id IN (1,2,3,4)	AND map_2022.[nwea_2022_TestPercentile] BETWEEN 76 AND 100
			THEN ROUND(((map_2022.[nwea_2022_TypicalFallToSpringGrowth]*1)+map_2022.[nwea_2022_TestRITScore]),0)
		WHEN sta.grade_level_id IN (5,6,7,8,9)	AND map_2022.[nwea_2022_TestPercentile] BETWEEN 1 AND 25
			THEN ROUND(((map_2022.[nwea_2022_TypicalFallToSpringGrowth]*2)+map_2022.[nwea_2022_TestRITScore]),0)
		WHEN sta.grade_level_id IN (5,6,7,8,9)	AND map_2022.[nwea_2022_TestPercentile] BETWEEN 26 AND 50
			THEN ROUND(((map_2022.[nwea_2022_TypicalFallToSpringGrowth]*1.75)+map_2022.[nwea_2022_TestRITScore]),0)
		WHEN sta.grade_level_id IN (5,6,7,8,9)	AND map_2022.[nwea_2022_TestPercentile] BETWEEN 51 AND 75 
			THEN ROUND(((map_2022.[nwea_2022_TypicalFallToSpringGrowth]*1.5)+map_2022.[nwea_2022_TestRITScore]),0)
		WHEN sta.grade_level_id IN (5,6,7,8,9)	AND map_2022.[nwea_2022_TestPercentile] BETWEEN 76 AND 100  
			THEN ROUND(((map_2022.[nwea_2022_TypicalFallToSpringGrowth]*1)+map_2022.[nwea_2022_TestRITScore]),0)
		ELSE NULL END AS "fs_tiered_growth_goal"
	,RANK() OVER(		
		PARTITION BY map_2022.nwea_2022_localstudentid, map_2022.[nwea_2022_TermName], map_2022.[nwea_2022_Discipline]
		ORDER BY map_2022.[nwea_2022_TestStandardError] DESC) best_test
FROM [illuminate].[public_students] stu
	INNER JOIN [custom].[vw_illuminate_student_site_aff] sch ON sch.student_id = stu.student_id
	INNER JOIN [illuminate].[matviews_student_term_aff] sta ON sch.student_id=sta.student_id
		AND sta.entry_date=sch.start_date
		AND sta.leave_date IS NULL
	LEFT JOIN [illuminate].[national_assessments_nwea_2022] map_2022 on map_2022.[student_id] = stu.student_id
WHERE 1=1
	AND sch.start_date > '2021-07-01' -- UPDATE TO REFLECT THE CURRENT SCHOOL YEAR
	AND sch.end_date < '2022-06-30'
	AND map_2022.[nwea_2022_TermName] = 'Fall 2021-2022'
	AND map_2022.[nwea_2022_Discipline] NOT IN ('Math K-12','Science K-12')
	AND CASE
			WHEN sta.grade_level_id IN (1,2) 
			AND map_2022.[nwea_2022_TestName] IN ('Growth: Math K-2 FL 2014', 'Growth: Reading K-2 FL 2014')
				THEN 1
			WHEN  sta.grade_level_id IN (3,4,5,6) 
			AND map_2022.[nwea_2022_TestName] IN ('Growth: Math 2-5 FL 2014', 'Growth: Reading 2-5 FL 2014 V2')
				THEN 1
			WHEN  sta.grade_level_id IN (7,8,9) 
			AND map_2022.[nwea_2022_TestName] IN ('Growth: Math 6+ FL 2014', 'Growth: Reading 6+ FL 2014 V2')
				THEN 1
			WHEN  sta.grade_level_id IN (4,5,6) 
			AND map_2022.[nwea_2022_TestName] = 'Growth: Science 3-5 FL 2008'
				THEN 1
			WHEN  sta.grade_level_id IN (7,8,9) 
			AND map_2022.[nwea_2022_TestName] = 'Growth: Science 6-8 FL 2008'
				THEN 1
			ELSE 0 END = 1
		)

SELECT 
 d.[student_id]		AS "Student ID"
,d.[student_name]	AS "Student"
,d.[school_name]	AS "School"
,d.homeroom		AS "Homeroom"
,d.[grade_level]	AS "Grade"
,f.subject		AS "Subject"
,f.fall_percentile	AS "Fall Percentile"
,w.winter_percentile	AS "Winter Percentile"
,s.spring_percentile	AS "Spring Percentile"
,f.fall_rit		AS "Fall RIT Score"
,w.winter_rit				AS "Winter RIT Score"
,s.spring_rit				AS "Spring RIT Score"
,g.fw_typical_growth_goal	AS "FW Typical Goal"
,g.fw_tiered_growth_goal	AS "FW Tiered Goal"	
,g.fs_typical_growth_goal	AS "FS Typical Goal"
,g.fs_tiered_growth_goal	AS "FS Tiered Goal"
FROM d
	LEFT JOIN f on d.[student_id] = f.[student_id]
	LEFT JOIN w on d.[student_id] = w.[student_id] AND f.subject = w.subject
	LEFT JOIN s on d.[student_id] = s.[student_id] AND w.subject = s.subject
	LEFT JOIN g on d.[student_id] = g.[student_id] AND f.subject = g.subject

GO
