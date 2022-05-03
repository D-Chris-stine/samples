ALTER VIEW [custom].[vw_student_demographics_2021]
AS 
SELECT
fr.[student id] AS "SystemStudentID"
,NULL as "StateStudentID"
,fr.[last] AS "LastName"
,NULL as "MiddleName"
,fr.[first] AS "FirstName"
,fr.gender AS "Gender"
,fr.birthdate AS "DateOfBirth"
,NULL as "BirthplaceCountry"
,NULL as "FirstUSASchoolDate"
,fr.[Ethnicity: Hispanic or Latino] as "IsHispanic"
,CASE 
  WHEN fr.[Ethnicity: Hispanic or Latino] = 'Yes' THEN 'Hispanic or Latino' 
  WHEN fr.[Race: American Indian or Alaska Native]= 'Yes' THEN 'American Indian or Alaskan Native'
  WHEN fr.[Race: Asian] = 'Yes' THEN 'Asian' 
  WHEN fr.[Race: Black or African American]= 'Yes' THEN 'Black or African American' 
  WHEN fr.[Race: Native Hawaiian or Other Pacific Islander] = 'Yes' THEN 'Native Hawaiian or Other Pacific Islander' 
  WHEN fr.[Race: White] = 'Yes' THEN 'White' END AS "PrimaryEthnicity"
,CASE
  WHEN fr.[English Language Learner]= '[LY] LEP in LEP classes' THEN 'LEP'
  WHEN fr.[English Language Learner]= '[ZZ] Not Applicable' THEN 'Not LEP'
  WHEN fr.[English Language Learner]= '[LZ] Exited after 2-yr followup/& McKay Schrshp' THEN 'Former LEP' END AS "LanguageFluency"
,fr.[Most Frequently Spoken Language Student] AS "PrimaryLanguage"
,NULL AS "ParentEducationLevel"
,NULL AS "LunchStatus"
,fr.[Primary ESE] AS "PrimaryDisability"
,NULL AS "DistrictEntryGradeLevel"
,NULL AS "Address"
,NULL AS "City"
,NULL AS "State"
,NULL AS "Zip"
,NULL AS "Latitude"
,NULL AS "Longitude"
,NULL AS "HomeDistrict"
,NULL AS "ClassOf"
,NULL AS "Cohort"
,NULL AS "StudentEmail"
,CASE
	WHEN fr.grade='KG' THEN 0
	ELSE fr.grade
	END
	AS "GradeLevel_Numeric"
,fr.[Year] AS "SchoolYear4Digit"

FROM  [dbo].[foundation_report_2021]fr
