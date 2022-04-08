USE [students]
GO

/****** Object:  View [dashboards].[vw_map_goals_2022]    Script Date: 4/8/2022 3:19:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



ALTER VIEW [dashboards].[vw_map_goals_2022]
AS
/* MAP SUB Queries */
WITH
/* MAP Demographics */
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
    ELSE NULL END "grade_level"     
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
	AND sch.site_id != 5901
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
	AND sch.start_date > '2021-07-01' -- SY21-22
	AND sch.end_date < '2022-07-01'
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
	AND sch.start_date > '2021-07-01' -- SY21-22
	AND sch.end_date < '2022-07-01'
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
	AND sch.start_date > '2021-07-01' -- SY21-22
	--AND sch.end_date < '2022-07-01'
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
	/****
	The following fields can be removed entirely or retained for easy quality assurance check on the data & calculation
	 -fall_percentile
	 -fall_rit
	 -fw_typical_growth
	 -fw_tiered_growth
	****/
	--,map_2022.[nwea_2022_TestPercentile] "fall_percentile"
	--,map_2022.[nwea_2022_TestRITScore] "fall_rit"
	--,map_2022.[nwea_2022_TypicalFallToWinterGrowth] "fw_typical_growth"
	--,CASE 
	--	WHEN sta.grade_level_id IN (1,2,3,4)	AND map_2022.[nwea_2022_TestPercentile] BETWEEN 1 AND 50
	--		THEN ROUND((map_2022.[nwea_2022_TypicalFallToWinterGrowth]*1.5),0)
	--	WHEN sta.grade_level_id IN (1,2,3,4)	AND map_2022.[nwea_2022_TestPercentile] BETWEEN 51 AND 75
	--		THEN ROUND((map_2022.[nwea_2022_TypicalFallToWinterGrowth]*1.25),0)
	--	WHEN sta.grade_level_id IN (1,2,3,4)	AND map_2022.[nwea_2022_TestPercentile] BETWEEN 76 AND 100
	--		THEN ROUND((map_2022.[nwea_2022_TypicalFallToWinterGrowth]*1),0)
	--	WHEN sta.grade_level_id IN (5,6,7,8,9)	AND map_2022.[nwea_2022_TestPercentile] BETWEEN 1 AND 25
	--		THEN ROUND((map_2022.[nwea_2022_TypicalFallToWinterGrowth]*2),0)
	--	WHEN sta.grade_level_id IN (5,6,7,8,9)	AND map_2022.[nwea_2022_TestPercentile] BETWEEN 26 AND 50
	--		THEN ROUND((map_2022.[nwea_2022_TypicalFallToWinterGrowth]*1.75),0)
	--	WHEN sta.grade_level_id IN (5,6,7,8,9)	AND map_2022.[nwea_2022_TestPercentile] BETWEEN 51 AND 75 
	--		THEN ROUND((map_2022.[nwea_2022_TypicalFallToWinterGrowth]*1.5),0)
	--	WHEN sta.grade_level_id IN (5,6,7,8,9)	AND map_2022.[nwea_2022_TestPercentile] BETWEEN 76 AND 100  
	--		THEN ROUND((map_2022.[nwea_2022_TypicalFallToWinterGrowth]*1),0)
	--	ELSE NULL END AS "fw_tiered_growth"
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
	/****
	The following fields can be removed entirely or retained for easy quality assurance check on the data & calculation
	 -fs_typical_growth
	 -fs_tiered_growth
	****/
	--,map_2022.[nwea_2022_TypicalFallToSpringGrowth] AS "fs_typical_growth"
	--,CASE 
	--	WHEN sta.grade_level_id IN (1,2,3,4)	AND map_2022.[nwea_2022_TestPercentile] BETWEEN 1 AND 50
	--		THEN ROUND((map_2022.[nwea_2022_TypicalFallToSpringGrowth]*1.5),0)
	--	WHEN sta.grade_level_id IN (1,2,3,4)	AND map_2022.[nwea_2022_TestPercentile] BETWEEN 51 AND 75
	--		THEN ROUND((map_2022.[nwea_2022_TypicalFallToSpringGrowth]*1.25),0)
	--	WHEN sta.grade_level_id IN (1,2,3,4)	AND map_2022.[nwea_2022_TestPercentile] BETWEEN 76 AND 100
	--		THEN ROUND((map_2022.[nwea_2022_TypicalFallToSpringGrowth]*1),0)
	--	WHEN sta.grade_level_id IN (5,6,7,8,9)	AND map_2022.[nwea_2022_TestPercentile] BETWEEN 1 AND 25
	--		THEN ROUND((map_2022.[nwea_2022_TypicalFallToSpringGrowth]*2),0)
	--	WHEN sta.grade_level_id IN (5,6,7,8,9)	AND map_2022.[nwea_2022_TestPercentile] BETWEEN 26 AND 50
	--		THEN ROUND((map_2022.[nwea_2022_TypicalFallToSpringGrowth]*1.75),0)
	--	WHEN sta.grade_level_id IN (5,6,7,8,9)	AND map_2022.[nwea_2022_TestPercentile] BETWEEN 51 AND 75 
	--		THEN ROUND((map_2022.[nwea_2022_TypicalFallToSpringGrowth]*1.5),0)
	--	WHEN sta.grade_level_id IN (5,6,7,8,9)	AND map_2022.[nwea_2022_TestPercentile] BETWEEN 76 AND 100  
	--		THEN ROUND((map_2022.[nwea_2022_TypicalFallToSpringGrowth]*1),0)
	--	ELSE NULL END AS "fs_tiered_growth"
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
	AND sch.start_date > '2021-07-01' -- SY21-22
	AND sch.end_date < '2022-07-01'
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
 d.[student_id]				AS "Student ID"
,d.[student_name]			AS "Student"
,d.[school_name]			AS "School"
,d.homeroom					AS "Homeroom"
,d.[grade_level]			AS "Grade"
,f.subject					AS "Subject"
,f.fall_percentile			AS "Fall Percentile"
,w.winter_percentile		AS "Winter Percentile"
,s.spring_percentile		AS "Spring Percentile"
,f.fall_rit					AS "Fall RIT"
,w.winter_rit				AS "Winter RIT"
,s.spring_rit				AS "Spring RIT"
,g.fw_typical_growth_goal	AS "FW Typical Goal"
,g.fw_tiered_growth_goal	AS "FW Tiered Goal"	
,g.fs_typical_growth_goal	AS "FS Typical Goal"
,g.fs_tiered_growth_goal	AS "FS Tiered Goal"
FROM d
LEFT JOIN f on d.[student_id] = f.[student_id]
LEFT JOIN w on d.[student_id] = w.[student_id] AND f.subject = w.subject
LEFT JOIN s on d.[student_id] = s.[student_id] AND w.subject = s.subject
LEFT JOIN g on d.[student_id] = g.[student_id] AND f.subject = g.subject
--WHERE d.student_id = 10744209
GO
