USE [CSRMAR_DataMart_CI]
GO
IF OBJECT_ID('tempdb..#usp_TablesComparer') IS NOT NULL DROP PROC #usp_TablesComparer;
IF OBJECT_ID('tempdb..#TestResult') IS NOT NULL DROP TABLE #TestResult;
IF OBJECT_ID('tempdb..#HierMemberExtendedEXPECTED') IS NOT NULL DROP TABLE #HierMemberExtendedEXPECTED;

IF EXISTS(SELECT * FROM sys.objects O WHERE O.object_id = OBJECT_ID('Hier.ufn_MemberID_2_XML')) 
	DROP FUNCTION Hier.ufn_MemberID_2_XML;
GO
CREATE FUNCTION Hier.ufn_MemberID_2_XML (@HierMemberID sys.hierarchyid)
	RETURNS XML
	BEGIN
		DECLARE
			 @start INT = 1
			,@end INT
			,@delimiter varchar(max) = '/'
			,@HierMemberIDstr varchar(max)
			,@Name varchar(max) = '.'
			,@Level INT = 1
			,@XML xml
		SET @HierMemberIDstr = SUBSTRING(@HierMemberID.ToString(), 2, len(@HierMemberID.ToString()) - 2)
		SET @end = CHARINDEX(@delimiter, @HierMemberIDstr)
		WHILE @start < LEN(@HierMemberIDstr) + 1
		BEGIN
			IF @end = 0
				SET @end = LEN(@HierMemberIDstr) + 1
				SET @Name = @Name + SUBSTRING(@HierMemberIDstr, @start, @end - @start) + '.'
				IF @Level = 1
					SET @XML = (SELECT @Name [@Name], @Level [@Level] FOR XML PATH('M'), TYPE)
				IF @Level > 1
					SET @XML = (SELECT @Name [@Name], @Level [@Level], @XML FOR XML PATH('M'), TYPE)
				SET @start = @end + 1
				SET @end = CHARINDEX(@delimiter, @HierMemberIDstr, @start)
				SET @Level = @Level + 1
		END
		RETURN @XML
	END
GO
CREATE PROC #usp_TablesComparer @t1 varchar(max), @t2 varchar(max), @col varchar(max), @rows INT OUTPUT AS
-- Example:
-- EXEC #usp_TablesComparer @t1 = 'HierMember', @t2 = '#HierMember', @col = 'HierID, HierMemberID, @rows = @DiffRows OUTPUT
-- tables should have this columns with the same data types
-- @t1 - Actual
-- @t2 - Expected
DECLARE @sql nvarchar(max) = ''--, @rows int
	SET @sql = '
				SELECT ' + @col + ', ''Expected'' AS ExtraRowIn FROM ' + @t2 + '
				EXCEPT
				SELECT ' + @col + ', ''Expected'' AS ExtraRowIn FROM ' + @t1 + ' WHERE HierID = 1 AND HierMemberID.IsDescendantOf(''/11/'') = 1
				UNION
				SELECT ' + @col + ', ''Actual'' AS ExtraRowIn FROM ' + @t1 + ' WHERE HierID = 1 AND HierMemberID.IsDescendantOf(''/11/'') = 1
				EXCEPT
				SELECT ' + @col + ', ''Actual'' AS ExtraRowIn FROM ' + @t2
-- Uncommend the line below if need details
--	EXEC sp_executesql @sql
-- ****************************************
	SET @sql = 'SET @rows = (SELECT COUNT(1) FROM (' + @sql + ') AS tbl)'
	EXEC sp_executesql @sql, N'@rows int OUTPUT', @rows = @rows OUTPUT
GO

BEGIN --Creating temp tables 
	CREATE TABLE #TestResult (TestNumber sysname, TestSuccessful bit, TestMessage nvarchar(2000));	
	CREATE TABLE #HierMemberExtendedEXPECTED (HierID tinyint, HierMemberID hierarchyid, Name0 varchar(128), Name1 varchar(128), Name2 varchar(128), Name3 varchar(128), Name4 varchar(128), Name5 varchar(128), SName0 varchar(128), SName1 varchar(128), SName2 varchar(128), SName3 varchar(128), SName4 varchar(128), SName5 varchar(128));
END;

BEGIN --Initial clean up 
	DELETE FROM Hier.HierMemberVersion 
		WHERE HierId = 1 AND HierMemberId.IsDescendantOf('/11/') = 1;
	DELETE FROM Hier.HierMemberMapping 
		WHERE SrcHierId = 1 AND SrcHierMemberId.IsDescendantOf('/11/') = 1;
	DELETE FROM Hier.HierMember 
		WHERE HierId = 1 AND HierMemberId.IsDescendantOf('/11/') = 1;
END;

DECLARE --necessary variables for tests 
	 @TestNumber sysname
	,@DiffRows int;

BEGIN --Test 1: INSERT memebers into HierMember (Acronim table is EMPTY) - HierMemberExtended is filled automatically 
	SET @TestNumber = '1'
	PRINT 'Test ' + @TestNumber + ' has started';
	BEGIN TRAN;
	INSERT INTO Hier.HierMember (HierId, HierMemberId, Name, FullName)
		SELECT t1.HierId, t1.HierMemberId, REPLACE(t1.HierMemberId, '/', '.') AS Name, Hier.ufn_MemberID_2_XML(t1.HierMemberId) AS FullName FROM
			(VALUES
				(1,'/11/'),
				(1,'/11/1/'),
				(1,'/11/1/1/')
			) t1(HierId, HierMemberId);
	INSERT INTO #HierMemberExtendedEXPECTED (HierID, HierMemberID, Name0, Name1, Name2, Name3, Name4, Name5, SName0, SName1, SName2, SName3, SName4, SName5)
		SELECT * FROM
			(VALUES
				(1,'/11/',		'All','.11.',	NULL,		NULL,		NULL,		NULL,		NULL,		NULL,		NULL,		NULL,		NULL,		NULL),
				(1,'/11/1/',	'All','.11.',	'.11.1.',	NULL,		NULL,		NULL,		NULL,		NULL,		NULL,		NULL,		NULL,		NULL),
				(1,'/11/1/1/',	'All','.11.',	'.11.1.',	'.11.1.1.',	NULL,		NULL,		NULL,		NULL,		NULL,		NULL,		NULL,		NULL)			) t1(HierID, HierMemberID, Name0, Name1, Name2, Name3, Name4, Name5, SName0, SName1, SName2, SName3, SName4, SName5);

		--select * from Hier.HierMember where HierID = 1 and HierMemberID.IsDescendantOf('/11/') = 1
		--select * from [Hier].[HierMemberExtended] where HierID = 1 and HierMemberID.IsDescendantOf('/11/') = 1
		--select * from #HierMemberExtendedEXPECTED where HierID = 1 and HierMemberID.IsDescendantOf('/11/') = 1

		EXEC #usp_TablesComparer @t1 = 'Hier.HierMemberExtended', @t2 = '#HierMemberExtendedEXPECTED', @col = 'HierID, HierMemberID, Name0, Name1, Name2, Name3, Name4, Name5, SName0, SName1, SName2, SName3, SName4, SName5', @rows = @DiffRows OUTPUT

	ROLLBACK TRAN;

	INSERT INTO #TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, IIF(@DiffRows > 0, 0, 1), 'Number of differences: ' + CAST(@DiffRows AS varchar(10)));

END;

BEGIN --Test 2: INSERT memebers into HierMember, then UPDATE memeber (Acronim table is EMPTY) - HierMemberExtended is filled automatically and updated 
	SET @TestNumber = '2'
	PRINT 'Test ' + @TestNumber + ' has started';
	BEGIN TRAN;
	INSERT INTO Hier.HierMember (HierId, HierMemberId, Name, FullName)
		SELECT t1.HierId, t1.HierMemberId, REPLACE(t1.HierMemberId, '/', '.') AS Name, Hier.ufn_MemberID_2_XML(t1.HierMemberId) AS FullName FROM
			(VALUES
				(1,'/11/'),
				(1,'/11/1/'),
				(1,'/11/1/1/')
			) t1(HierId, HierMemberId);
	UPDATE Hier.HierMember SET Name = '.12.', [FullName] = '<M Name=".12." Level="1" />' WHERE HierId = 1 AND HierMemberId = '/11/'
	INSERT INTO #HierMemberExtendedEXPECTED (HierID, HierMemberID, Name0, Name1, Name2, Name3, Name4, Name5, SName0, SName1, SName2, SName3, SName4, SName5)
		SELECT * FROM
			(VALUES
				(1,'/11/',		'All','.12.',	NULL,		NULL,		NULL,		NULL,		NULL,		NULL,		NULL,		NULL,		NULL,		NULL),
				(1,'/11/1/',	'All','.12.',	'.11.1.',	NULL,		NULL,		NULL,		NULL,		NULL,		NULL,		NULL,		NULL,		NULL),
				(1,'/11/1/1/',	'All','.12.',	'.11.1.',	'.11.1.1.',	NULL,		NULL,		NULL,		NULL,		NULL,		NULL,		NULL,		NULL)			) t1(HierID, HierMemberID, Name0, Name1, Name2, Name3, Name4, Name5, SName0, SName1, SName2, SName3, SName4, SName5);

		--select * from Hier.HierMember where HierID = 1 and HierMemberID.IsDescendantOf('/11/') = 1
		--select * from [Hier].[HierMemberExtended] where HierID = 1 and HierMemberID.IsDescendantOf('/11/') = 1
		--select * from #HierMemberExtendedEXPECTED where HierID = 1 and HierMemberID.IsDescendantOf('/11/') = 1

		EXEC #usp_TablesComparer @t1 = 'Hier.HierMemberExtended', @t2 = '#HierMemberExtendedEXPECTED', @col = 'HierID, HierMemberID, Name0, Name1, Name2, Name3, Name4, Name5, SName0, SName1, SName2, SName3, SName4, SName5', @rows = @DiffRows OUTPUT

	ROLLBACK TRAN;

	INSERT INTO #TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, IIF(@DiffRows > 0, 0, 1), 'Number of differences: ' + CAST(@DiffRows AS varchar(10)));

END;

BEGIN --Test 3: INSERT memebers into HierMember (Acronim table is FILLED) - HierMemberExtended is filled automatically 
	SET @TestNumber = '3'
	PRINT 'Test ' + @TestNumber + ' has started';
	BEGIN TRAN;
	INSERT INTO Hier.HierMemberNameAcronym (HierId, HierMemberName, Acronym)
		SELECT t1.HierId, t1.HierMemberName, Acronym FROM
			(VALUES
				(1,'.11.',		'.11. - acr'),
				(1,'.11.1.1.',	'.11.1.1. - acr')
			) t1(HierId, HierMemberName, Acronym);
	INSERT INTO Hier.HierMember (HierId, HierMemberId, Name, FullName)
		SELECT t1.HierId, t1.HierMemberId, REPLACE(t1.HierMemberId, '/', '.') AS Name, Hier.ufn_MemberID_2_XML(t1.HierMemberId) AS FullName FROM
			(VALUES
				(1,'/11/'),
				(1,'/11/1/'),
				(1,'/11/1/1/')
			) t1(HierId, HierMemberId);

	INSERT INTO #HierMemberExtendedEXPECTED (HierID, HierMemberID, Name0, Name1, Name2, Name3, Name4, Name5, SName0, SName1, SName2, SName3, SName4, SName5)
		SELECT * FROM
			(VALUES
				(1,'/11/',		'All','.11.',	NULL,		NULL,		NULL,		NULL,		NULL,		'.11. - acr',		NULL,		NULL,		NULL,		NULL),
				(1,'/11/1/',	'All','.11.',	'.11.1.',	NULL,		NULL,		NULL,		NULL,		'.11. - acr',		NULL,		NULL,		NULL,		NULL),
				(1,'/11/1/1/',	'All','.11.',	'.11.1.',	'.11.1.1.',	NULL,		NULL,		NULL,		'.11. - acr',		NULL,		'.11.1.1. - acr',		NULL,		NULL)
				) t1(HierID, HierMemberID, Name0, Name1, Name2, Name3, Name4, Name5, SName0, SName1, SName2, SName3, SName4, SName5);

		--select * from Hier.HierMember where HierID = 1 and HierMemberID.IsDescendantOf('/11/') = 1
		--select * from [Hier].[HierMemberExtended] where HierID = 1 and HierMemberID.IsDescendantOf('/11/') = 1
		--select * from #HierMemberExtendedEXPECTED where HierID = 1 and HierMemberID.IsDescendantOf('/11/') = 1

		EXEC #usp_TablesComparer @t1 = 'Hier.HierMemberExtended', @t2 = '#HierMemberExtendedEXPECTED', @col = 'HierID, HierMemberID, Name0, Name1, Name2, Name3, Name4, Name5, SName0, SName1, SName2, SName3, SName4, SName5', @rows = @DiffRows OUTPUT

	ROLLBACK TRAN;

	INSERT INTO #TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, IIF(@DiffRows > 0, 0, 1), 'Number of differences: ' + CAST(@DiffRows AS varchar(10)));

END;

BEGIN --Test 4: INSERT memebers into HierMember, then UPDATE memeber (Acronim table is FILLED) - HierMemberExtended is filled automatically 
	SET @TestNumber = '4'
	PRINT 'Test ' + @TestNumber + ' has started';
	BEGIN TRAN;
	INSERT INTO Hier.HierMemberNameAcronym (HierId, HierMemberName, Acronym)
		SELECT t1.HierId, t1.HierMemberName, Acronym FROM
			(VALUES
				(1,'.11.',		'.11. - acr'),
				(1,'.11.1.1.',	'.11.1.1. - acr')
			) t1(HierId, HierMemberName, Acronym);
	INSERT INTO Hier.HierMember (HierId, HierMemberId, Name, FullName)
		SELECT t1.HierId, t1.HierMemberId, REPLACE(t1.HierMemberId, '/', '.') AS Name, Hier.ufn_MemberID_2_XML(t1.HierMemberId) AS FullName FROM
			(VALUES
				(1,'/11/'),
				(1,'/11/1/'),
				(1,'/11/1/1/')
			) t1(HierId, HierMemberId);

	UPDATE Hier.HierMember SET Name = '.12.', [FullName] = '<M Name=".12." Level="1" />' WHERE HierId = 1 AND HierMemberId = '/11/'

	INSERT INTO #HierMemberExtendedEXPECTED (HierID, HierMemberID, Name0, Name1, Name2, Name3, Name4, Name5, SName0, SName1, SName2, SName3, SName4, SName5)
		SELECT * FROM
			(VALUES
				(1,'/11/',		'All','.12.',	NULL,		NULL,		NULL,		NULL,		NULL,		NULL,		NULL,		NULL,		NULL,		NULL),
				(1,'/11/1/',	'All','.12.',	'.11.1.',	NULL,		NULL,		NULL,		NULL,		NULL,		NULL,		NULL,		NULL,		NULL),
				(1,'/11/1/1/',	'All','.12.',	'.11.1.',	'.11.1.1.',	NULL,		NULL,		NULL,		NULL,		NULL,		'.11.1.1. - acr',		NULL,		NULL)
				) t1(HierID, HierMemberID, Name0, Name1, Name2, Name3, Name4, Name5, SName0, SName1, SName2, SName3, SName4, SName5);

		EXEC #usp_TablesComparer @t1 = 'Hier.HierMemberExtended', @t2 = '#HierMemberExtendedEXPECTED', @col = 'HierID, HierMemberID, Name0, Name1, Name2, Name3, Name4, Name5, SName0, SName1, SName2, SName3, SName4, SName5', @rows = @DiffRows OUTPUT

	ROLLBACK TRAN;

	INSERT INTO #TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, IIF(@DiffRows > 0, 0, 1), 'Number of differences: ' + CAST(@DiffRows AS varchar(10)));

END;

BEGIN --Test 5: INSERT memebers into HierMember (Acronim table is FILLED), then INSERT into Acronim table - HierMemberExtended is filled and then updated automatically 
	SET @TestNumber = '5'
	PRINT 'Test ' + @TestNumber + ' has started';
	BEGIN TRAN;
	INSERT INTO Hier.HierMemberNameAcronym (HierId, HierMemberName, Acronym)
		SELECT t1.HierId, t1.HierMemberName, Acronym FROM
			(VALUES
				(1,'.11.',		'.11. - acr'),
				(1,'.11.1.1.',	'.11.1.1. - acr')
			) t1(HierId, HierMemberName, Acronym);
	INSERT INTO Hier.HierMember (HierId, HierMemberId, Name, FullName)
		SELECT t1.HierId, t1.HierMemberId, REPLACE(t1.HierMemberId, '/', '.') AS Name, Hier.ufn_MemberID_2_XML(t1.HierMemberId) AS FullName FROM
			(VALUES
				(1,'/11/'),
				(1,'/11/1/'),
				(1,'/11/1/1/')
			) t1(HierId, HierMemberId);
	INSERT INTO Hier.HierMemberNameAcronym (HierId, HierMemberName, Acronym)
		SELECT t1.HierId, t1.HierMemberName, Acronym FROM
			(VALUES
				(1,'.11.1.',		'.11.1. - acr')
			) t1(HierId, HierMemberName, Acronym);
	INSERT INTO #HierMemberExtendedEXPECTED (HierID, HierMemberID, Name0, Name1, Name2, Name3, Name4, Name5, SName0, SName1, SName2, SName3, SName4, SName5)
		SELECT * FROM
			(VALUES
				(1,'/11/',		'All','.11.',	NULL,		NULL,		NULL,		NULL,		NULL,		'.11. - acr',		NULL,		NULL,		NULL,		NULL),
				(1,'/11/1/',	'All','.11.',	'.11.1.',	NULL,		NULL,		NULL,		NULL,		'.11. - acr',		'.11.1. - acr',		NULL,		NULL,		NULL),
				(1,'/11/1/1/',	'All','.11.',	'.11.1.',	'.11.1.1.',	NULL,		NULL,		NULL,		'.11. - acr',		'.11.1. - acr',		'.11.1.1. - acr',		NULL,		NULL)
				) t1(HierID, HierMemberID, Name0, Name1, Name2, Name3, Name4, Name5, SName0, SName1, SName2, SName3, SName4, SName5);

		--select * from Hier.HierMember where HierID = 1 and HierMemberID.IsDescendantOf('/11/') = 1
		--select * from [Hier].[HierMemberExtended] where HierID = 1 and HierMemberID.IsDescendantOf('/11/') = 1
		--select * from #HierMemberExtendedEXPECTED where HierID = 1 and HierMemberID.IsDescendantOf('/11/') = 1

		EXEC #usp_TablesComparer @t1 = 'Hier.HierMemberExtended', @t2 = '#HierMemberExtendedEXPECTED', @col = 'HierID, HierMemberID, Name0, Name1, Name2, Name3, Name4, Name5, SName0, SName1, SName2, SName3, SName4, SName5', @rows = @DiffRows OUTPUT

	ROLLBACK TRAN;

	INSERT INTO #TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, IIF(@DiffRows > 0, 0, 1), 'Number of differences: ' + CAST(@DiffRows AS varchar(10)));

END;

BEGIN --Test 6: INSERT memebers into HierMember (Acronim table is FILLED), then UPDATE Acronim table - HierMemberExtended is filled and then updated automatically 
	SET @TestNumber = '6'
	PRINT 'Test ' + @TestNumber + ' has started';
	BEGIN TRAN;
	INSERT INTO Hier.HierMemberNameAcronym (HierId, HierMemberName, Acronym)
		SELECT t1.HierId, t1.HierMemberName, Acronym FROM
			(VALUES
				(1,'.11.',		'.11. - acr'),
				(1,'.11.1.',	'.11.1. - acr'),
				(1,'.11.1.1.',	'.11.1.1. - acr')
			) t1(HierId, HierMemberName, Acronym);
	INSERT INTO Hier.HierMember (HierId, HierMemberId, Name, FullName)
		SELECT t1.HierId, t1.HierMemberId, REPLACE(t1.HierMemberId, '/', '.') AS Name, Hier.ufn_MemberID_2_XML(t1.HierMemberId) AS FullName FROM
			(VALUES
				(1,'/11/'),
				(1,'/11/1/'),
				(1,'/11/1/1/')
			) t1(HierId, HierMemberId);
	UPDATE Hier.HierMemberNameAcronym SET Acronym = CONCAT(Acronym, ' - UPD') WHERE HierMemberName = '.11.1.'
	INSERT INTO #HierMemberExtendedEXPECTED (HierID, HierMemberID, Name0, Name1, Name2, Name3, Name4, Name5, SName0, SName1, SName2, SName3, SName4, SName5)
		SELECT * FROM
			(VALUES
				(1,'/11/',		'All','.11.',	NULL,		NULL,		NULL,		NULL,		NULL,		'.11. - acr',		NULL,									NULL,		NULL,		NULL),
				(1,'/11/1/',	'All','.11.',	'.11.1.',	NULL,		NULL,		NULL,		NULL,		'.11. - acr',		'.11.1. - acr - UPD',					NULL,		NULL,		NULL),
				(1,'/11/1/1/',	'All','.11.',	'.11.1.',	'.11.1.1.',	NULL,		NULL,		NULL,		'.11. - acr',		'.11.1. - acr - UPD',		'.11.1.1. - acr',		NULL,		NULL)
				) t1(HierID, HierMemberID, Name0, Name1, Name2, Name3, Name4, Name5, SName0, SName1, SName2, SName3, SName4, SName5);

		--select * from Hier.HierMember where HierID = 1 and HierMemberID.IsDescendantOf('/11/') = 1
		--select * from [Hier].[HierMemberExtended] where HierID = 1 and HierMemberID.IsDescendantOf('/11/') = 1
		--select * from #HierMemberExtendedEXPECTED where HierID = 1 and HierMemberID.IsDescendantOf('/11/') = 1

		EXEC #usp_TablesComparer @t1 = 'Hier.HierMemberExtended', @t2 = '#HierMemberExtendedEXPECTED', @col = 'HierID, HierMemberID, Name0, Name1, Name2, Name3, Name4, Name5, SName0, SName1, SName2, SName3, SName4, SName5', @rows = @DiffRows OUTPUT

	ROLLBACK TRAN;

	INSERT INTO #TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, IIF(@DiffRows > 0, 0, 1), 'Number of differences: ' + CAST(@DiffRows AS varchar(10)));

END;

BEGIN --Test 7: INSERT memebers into HierMember (Acronim table is FILLED), then DELETE from Acronim table - HierMemberExtended is filled and then updated automatically 
	SET @TestNumber = '7'
	PRINT 'Test ' + @TestNumber + ' has started';
	BEGIN TRAN;
	INSERT INTO Hier.HierMemberNameAcronym (HierId, HierMemberName, Acronym)
		SELECT t1.HierId, t1.HierMemberName, Acronym FROM
			(VALUES
				(1,'.11.',		'.11. - acr'),
				(1,'.11.1.',	'.11.1. - acr'),
				(1,'.11.1.1.',	'.11.1.1. - acr')
			) t1(HierId, HierMemberName, Acronym);
	INSERT INTO Hier.HierMember (HierId, HierMemberId, Name, FullName)
		SELECT t1.HierId, t1.HierMemberId, REPLACE(t1.HierMemberId, '/', '.') AS Name, Hier.ufn_MemberID_2_XML(t1.HierMemberId) AS FullName FROM
			(VALUES
				(1,'/11/'),
				(1,'/11/1/'),
				(1,'/11/1/1/')
			) t1(HierId, HierMemberId);
	DELETE FROM Hier.HierMemberNameAcronym WHERE HierMemberName = '.11.1.'
	INSERT INTO #HierMemberExtendedEXPECTED (HierID, HierMemberID, Name0, Name1, Name2, Name3, Name4, Name5, SName0, SName1, SName2, SName3, SName4, SName5)
		SELECT * FROM
			(VALUES
				(1,'/11/',		'All','.11.',	NULL,		NULL,		NULL,		NULL,		NULL,		'.11. - acr',		NULL,									NULL,		NULL,		NULL),
				(1,'/11/1/',	'All','.11.',	'.11.1.',	NULL,		NULL,		NULL,		NULL,		'.11. - acr',		NULL,					NULL,		NULL,		NULL),
				(1,'/11/1/1/',	'All','.11.',	'.11.1.',	'.11.1.1.',	NULL,		NULL,		NULL,		'.11. - acr',		NULL,		'.11.1.1. - acr',		NULL,		NULL)
				) t1(HierID, HierMemberID, Name0, Name1, Name2, Name3, Name4, Name5, SName0, SName1, SName2, SName3, SName4, SName5);

		--select * from Hier.HierMember where HierID = 1 and HierMemberID.IsDescendantOf('/11/') = 1
		--select * from [Hier].[HierMemberExtended] where HierID = 1 and HierMemberID.IsDescendantOf('/11/') = 1
		--select * from #HierMemberExtendedEXPECTED where HierID = 1 and HierMemberID.IsDescendantOf('/11/') = 1

		EXEC #usp_TablesComparer @t1 = 'Hier.HierMemberExtended', @t2 = '#HierMemberExtendedEXPECTED', @col = 'HierID, HierMemberID, Name0, Name1, Name2, Name3, Name4, Name5, SName0, SName1, SName2, SName3, SName4, SName5', @rows = @DiffRows OUTPUT

	ROLLBACK TRAN;

	INSERT INTO #TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, IIF(@DiffRows > 0, 0, 1), 'Number of differences: ' + CAST(@DiffRows AS varchar(10)));

END;

SELECT * FROM #TestResult ORDER BY 2, 1;
IF EXISTS(SELECT * FROM sys.objects O WHERE O.object_id = OBJECT_ID('Hier.ufn_MemberID_2_XML'))
	DROP FUNCTION Hier.ufn_MemberID_2_XML;