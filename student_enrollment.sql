CREATE VIEW [custom].[vw_student_enrollments_2021]
AS
SELECT
fr.[Student ID] AS "SystemStudentID"
,fr.last AS "LastName"
,fr.first AS "FirstName"
,fr.counselor AS "SystemSchoolID"
,fr.[Enrollment Start Date] AS "EntryDate"
,fr.[Drop Date] AS "ExitDate"
,LEFT(fr.[Enrollment Code], 5) as "EntryCode"
,fr.[Enrollment Code] AS "EntryDescription"
,LEFT(wd.wd_category, 2) as "ExitCode"
,wd.wd_category AS "ExitDescription"
,wd.detailed_reason AS "ExitComment"
,CASE
	WHEN fr.grade='KG' THEN 0
	ELSE fr.grade
	END
	AS "GradeLevel"
,fr.[Year] AS "SchoolYear4Digit" --Update to current 4 digit school year
FROM [dbo].[foundation_report_2021] fr
LEFT JOIN google.entrywithdrawal_withdrawn_2021 wd on wd.student_id=fr.[Student ID] --Table w/ KF Exit Codes
