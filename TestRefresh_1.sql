USE [CSRMAR_DataMart_CI]
GO

IF OBJECT_ID('tempdb..#usp_TablesComparer') IS NOT NULL DROP PROC #usp_TablesComparer;
IF OBJECT_ID('tempdb..#TestHierMember') IS NOT NULL DROP TABLE #TestHierMember;
IF OBJECT_ID('tempdb..#TestHierMemberUPD') IS NOT NULL DROP TABLE #TestHierMemberUPD;
IF OBJECT_ID('tempdb..#TestHierMemberVersion') IS NOT NULL DROP TABLE #TestHierMemberVersion;
IF OBJECT_ID('tempdb..#TestHierMemberVersionUPD') IS NOT NULL DROP TABLE #TestHierMemberVersionUPD;
IF OBJECT_ID('tempdb..#SnapshotOfHierMembers') IS NOT NULL DROP TABLE #SnapshotOfHierMembers;
IF OBJECT_ID('tempdb..#TestResult') IS NOT NULL DROP TABLE #TestResult;
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

BEGIN --Initial clean up 
	DELETE FROM Hier.HierMemberVersion 
		WHERE HierId = 1 AND HierMemberId.IsDescendantOf('/11/') = 1;
	DELETE FROM Hier.HierMemberMapping 
		WHERE SrcHierId = 1 AND SrcHierMemberId.IsDescendantOf('/11/') = 1;
	DELETE FROM Hier.HierMember 
		WHERE HierId = 1 AND HierMemberId.IsDescendantOf('/11/') = 1;
END;

BEGIN --Creating and filling temp tables 
	CREATE TABLE #TestResult (TestNumber sysname, TestSuccessful bit, TestMessage nvarchar(2000) NULL);	
	CREATE TABLE #TestHierMember (HierId tinyint, HierMemberId sys.hierarchyid, Name varchar(128), FullName XML);
	CREATE TABLE #TestHierMemberUPD (HierId tinyint, HierMemberId sys.hierarchyid, Name varchar(128), FullName XML);
	CREATE TABLE #TestHierMemberVersion (HierId tinyint, HierMemberId sys.hierarchyid, StartDate date, EndDate date, IsCurrent bit, Attributes XML);
	CREATE TABLE #TestHierMemberVersionUPD (HierId tinyint, HierMemberId sys.hierarchyid, StartDate date, EndDate date, IsCurrent bit, Attributes XML);
	CREATE TABLE #SnapshotOfHierMembers (FullName XML, Attributes XML);
	INSERT INTO #TestHierMember (HierId, HierMemberId, Name, FullName)
	SELECT t1.HierId, t1.HierMemberId, REPLACE(t1.HierMemberId, '/', '.') AS Name, Hier.ufn_MemberID_2_XML(t1.HierMemberId) AS FullName FROM
		(VALUES
			(1,'/11/'),
			(1,'/11/1/'),
			(1,'/11/1/1/'),
			(1,'/11/1/2/'),
			(1,'/11/1/2/3/'),
			(1,'/11/2/'),
			(1,'/11/2/2/'),
			(1,'/11/2/2/4/'),
			(1,'/11/4/'),
			(1,'/11/4/4/'),
			(1,'/11/4/4/5/'),
			(1,'/11/4/5/'),
			(1,'/11/4/5/5/')
		) t1(HierId, HierMemberId);
	INSERT INTO #TestHierMemberVersion(HierId, HierMemberId, StartDate, EndDate, IsCurrent, Attributes)
		VALUES
			(1, '/11/',			'20150101', '20150117', 0, '<Attributes/>'),
			(1, '/11/',			'20150120', '20150204', 0, '<Attributes/>'),
			(1, '/11/',			'20150209', '99990101', 1, '<Attributes/>'),
			(1, '/11/1/',		'20150102', '20150114', 0, '<Attributes/>'),
			(1, '/11/1/',		'20150120', '20150203', 0, '<Attributes/>'),
			(1, '/11/1/',		'20150209', '20150226', 0, '<Attributes/>'),
			(1, '/11/1/1/',		'20150102', '20150106', 0, '<Attributes/>'),
			(1, '/11/1/1/',		'20150108', '20150114', 0, '<Attributes/>'),
			(1, '/11/1/1/',		'20150120', '20150203', 0, '<Attributes/>'),
			(1, '/11/1/1/',		'20150209', '20150223', 0, '<Attributes/>'),
			(1, '/11/1/2/',		'20150102', '20150113', 0, '<Attributes/>'),
			(1, '/11/1/2/',		'20150120', '20150125', 0, '<Attributes/>'),
			(1, '/11/1/2/',		'20150127', '20150202', 0, '<Attributes/>'),
			(1, '/11/1/2/',		'20150209', '20150209', 0, '<Attributes/>'),
			(1, '/11/1/2/',		'20150211', '20150213', 0, '<Attributes/>'),
			(1, '/11/1/2/',		'20150215', '20150220', 0, '<Attributes/>'),
			(1, '/11/1/2/3/',	'20150102', '20150104', 0, '<Attributes/>'),
			(1, '/11/1/2/3/',	'20150106', '20150110', 0, '<Attributes/>'),
			(1, '/11/1/2/3/',	'20150121', '20150121', 0, '<Attributes/>'),
			(1, '/11/1/2/3/',	'20150128', '20150129', 0, '<Attributes/>'),
			(1, '/11/1/2/3/',	'20150212', '20150212', 0, '<Attributes/>'),
			(1, '/11/1/2/3/',	'20150216', '20150219', 0, '<Attributes/>'),
			(1, '/11/2/',		'20150101', '20150109', 0, '<Attributes/>'),
			(1, '/11/2/',		'20150113', '20150114', 0, '<Attributes/>'),
			(1, '/11/2/',		'20150120', '20150124', 0, '<Attributes/>'),
			(1, '/11/2/',		'20150126', '20150201', 0, '<Attributes/>'),
			(1, '/11/2/',		'20150209', '99990101', 1, '<Attributes/>'),
			(1, '/11/2/2/',		'20150102', '20150109', 0, '<Attributes/>'),
			(1, '/11/2/2/',		'20150113', '20150113', 0, '<Attributes/>'),
			(1, '/11/2/2/',		'20150120', '20150121', 0, '<Attributes/>'),
			(1, '/11/2/2/',		'20150126', '20150129', 0, '<Attributes/>'),
			(1, '/11/2/2/',		'20150210', '20150214', 0, '<Attributes/>'),
			(1, '/11/2/2/',		'20150216', '20150223', 0, '<Attributes/>'),
			(1, '/11/2/2/',		'20150225', '99990101', 1, '<Attributes/>'),
			(1, '/11/2/2/4/',	'20150103', '20150107', 0, '<Attributes/>'),
			(1, '/11/2/2/4/',	'20150120', '20150120', 0, '<Attributes/>'),
			(1, '/11/2/2/4/',	'20150127', '20150129', 0, '<Attributes/>'),
			(1, '/11/2/2/4/',	'20150211', '20150211', 0, '<Attributes/>'),
			(1, '/11/2/2/4/',	'20150213', '20150213', 0, '<Attributes/>'),
			(1, '/11/2/2/4/',	'20150216', '20150216', 0, '<Attributes/>'),
			(1, '/11/2/2/4/',	'20150218', '20150220', 0, '<Attributes/>'),
			(1, '/11/2/2/4/',	'20150226', '99990101', 1, '<Attributes/>'),
			(1, '/11/4/',		'20150101', '20150107', 0, '<Attributes/>'),
			(1, '/11/4/',		'20150109', '20150115', 0, '<Attributes/>'),
			(1, '/11/4/',		'20150120', '20150130', 0, '<Attributes/>'),
			(1, '/11/4/',		'20150203', '20150203', 0, '<Attributes/>'),
			(1, '/11/4/',		'20150211', '20150217', 0, '<Attributes/>'),
			(1, '/11/4/',		'20150222', '20150225', 0, '<Attributes/>'),
			(1, '/11/4/4/',		'20150102', '20150105', 0, '<Attributes/>'),
			(1, '/11/4/4/',		'20150110', '20150114', 0, '<Attributes/>'),
			(1, '/11/4/4/',		'20150123', '20150126', 0, '<Attributes/>'),
			(1, '/11/4/4/',		'20150212', '20150217', 0, '<Attributes/>'),
			(1, '/11/4/4/5/',	'20150103', '20150105', 0, '<Attributes/>'),
			(1, '/11/4/4/5/',	'20150110', '20150110', 0, '<Attributes/>'),
			(1, '/11/4/4/5/',	'20150126', '20150126', 0, '<Attributes/>'),
			(1, '/11/4/4/5/',	'20150213', '20150217', 0, '<Attributes/>'),
			(1, '/11/4/5/',		'20150101', '20150105', 0, '<Attributes/>'),
			(1, '/11/4/5/',		'20150109', '20150110', 0, '<Attributes/>'),
			(1, '/11/4/5/',		'20150125', '20150128', 0, '<Attributes/>'),
			(1, '/11/4/5/',		'20150213', '20150217', 0, '<Attributes/>'),
			(1, '/11/4/5/',		'20150223', '20150224', 0, '<Attributes/>'),
			(1, '/11/4/5/5/',	'20150102', '20150105', 0, '<Attributes/>'),
			(1, '/11/4/5/5/',	'20150126', '20150126', 0, '<Attributes/>'),
			(1, '/11/4/5/5/',	'20150213', '20150217', 0, '<Attributes/>'),
			(1, '/11/4/5/5/',	'20150224', '20150224', 0, '<Attributes/>')
END;

BEGIN --Inserting test data into DB tables 
	INSERT INTO Hier.HierMember (HierId, HierMemberId, Name, FullName) SELECT * FROM #TestHierMember;
	INSERT INTO Hier.HierMemberVersion(HierId, HierMemberId, StartDate, EndDate, IsCurrent, Attributes) SELECT * FROM #TestHierMemberVersion;
END;

DECLARE --necessary variables for tests 
	 @TestNumber sysname
	,@SnapshotOfHierMembers Hier.udt_HierMember
	,@HierID tinyint = 1
	,@Today date = '20150228'
	,@DiffRows int;

BEGIN --Test 1: Send a snapshot with an element, witch exists in DB - no rows changed 
	SET @TestNumber = '1'
	PRINT 'Test ' + @TestNumber + ' has started';

	DELETE FROM @SnapshotOfHierMembers
	INSERT INTO @SnapshotOfHierMembers (FullName, Attributes) SELECT Hier.ufn_MemberID_2_XML(t1.HierMemberId) AS FullName, cast('<Attributes/>' as XML) AS Attributes FROM
		(VALUES
				('/11/2/2/4/')
		) t1(HierMemberId);
	EXEC Hier.usp_HierMembers_Refresh @HierId = @HierId, @SnapshotOfHierMembers = @SnapshotOfHierMembers, @Today = @Today;
	DELETE FROM #TestHierMemberVersionUPD;
	INSERT INTO #TestHierMemberVersionUPD SELECT * FROM #TestHierMemberVersion;
	
	EXEC #usp_TablesComparer @t1 = 'Hier.HierMemberVersion', @t2 = '#TestHierMemberVersionUPD', @col = 'HierID, HierMemberId.ToString() AS HierMemberId, StartDate, EndDate, IsCurrent, CAST(Attributes AS varchar(max)) AS Attributes', @rows = @DiffRows OUTPUT
	INSERT INTO #TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, IIF(@DiffRows > 0, 0, 1), 'Number of differences: ' + CAST(@DiffRows AS varchar(10)));
END;

BEGIN --Test 2: Send an empty snapshot - all versions are stopped if @Today date is in the version 
	SET @TestNumber = '2'
	PRINT 'Test ' + @TestNumber + ' has started';

	DELETE FROM #TestHierMemberVersionUPD;
	INSERT INTO #TestHierMemberVersionUPD SELECT * FROM #TestHierMemberVersion;
	UPDATE #TestHierMemberVersionUPD SET EndDate = DATEADD(day, -1, @Today), IsCurrent = 0
	WHERE HierId = @HierId AND @Today BETWEEN StartDate AND EndDate;

	DELETE FROM @SnapshotOfHierMembers
	BEGIN TRAN;
		EXEC Hier.usp_HierMembers_Refresh @HierId = @HierId, @SnapshotOfHierMembers = @SnapshotOfHierMembers, @Today = @Today;
		EXEC #usp_TablesComparer @t1 = 'Hier.HierMemberVersion', @t2 = '#TestHierMemberVersionUPD', @col = 'HierID, HierMemberId.ToString() AS HierMemberId, StartDate, EndDate, IsCurrent, CAST(Attributes AS varchar(max)) AS Attributes', @rows = @DiffRows OUTPUT
		print @DiffRows
	ROLLBACK TRAN;
	INSERT INTO #TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, IIF(@DiffRows > 0, 0, 1), 'Number of differences: ' + CAST(@DiffRows AS varchar(10)));
END;

BEGIN --Test 3: Send a snapshot with a new element (element and parents didn't and don't exist) - the new element and his version was created (for parents too) 
	SET @TestNumber = '3'
	PRINT 'Test ' + @TestNumber + ' has started';

	DELETE FROM @SnapshotOfHierMembers
	INSERT INTO @SnapshotOfHierMembers (FullName, Attributes) SELECT Hier.ufn_MemberID_2_XML(t1.HierMemberId) AS FullName, cast('<Attributes/>' as XML) AS Attributes FROM
		(VALUES
				('/11/2/2/4/'),
				('/11/5/1/')
		) t1(HierMemberId);

	DELETE FROM #TestHierMemberUPD;
	INSERT INTO #TestHierMemberUPD (HierId, HierMemberId, Name, FullName) SELECT * FROM #TestHierMember;
	INSERT INTO #TestHierMemberUPD (HierId, HierMemberId, Name, FullName)
		SELECT t1.HierId, t1.HierMemberId, REPLACE(t1.HierMemberId, '/', '.') AS Name, Hier.ufn_MemberID_2_XML(t1.HierMemberId) AS FullName FROM
			(VALUES
				(1,'/11/5/1/'),
				(1,'/11/5/')
			) t1(HierId, HierMemberId);

	DELETE FROM #TestHierMemberVersionUPD;
	INSERT INTO #TestHierMemberVersionUPD SELECT * FROM #TestHierMemberVersion;
	INSERT INTO #TestHierMemberVersionUPD(HierId, HierMemberId, StartDate, EndDate, IsCurrent, Attributes)
		VALUES
			(1, '/11/5/1/', '20150228', '99990101', 1, '<Attributes/>'),
			(1, '/11/5/',	'20150228', '99990101', 1, '<Attributes/>');
	
	BEGIN TRAN;
		EXEC Hier.usp_HierMembers_Refresh @HierId = @HierId, @SnapshotOfHierMembers = @SnapshotOfHierMembers, @Today = @Today;
		EXEC #usp_TablesComparer @t1 = 'Hier.HierMemberVersion', @t2 = '#TestHierMemberVersionUPD', @col = 'HierID, HierMemberId.ToString() AS HierMemberId, StartDate, EndDate, IsCurrent, CAST(Attributes AS varchar(max)) AS Attributes', @rows = @DiffRows OUTPUT
	ROLLBACK TRAN;
	INSERT INTO #TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, IIF(@DiffRows > 0, 0, 1), 'Number of differences: ' + CAST(@DiffRows AS varchar(10)));

	BEGIN TRAN;
		EXEC Hier.usp_HierMembers_Refresh @HierId = @HierId, @SnapshotOfHierMembers = @SnapshotOfHierMembers, @Today = @Today;
		EXEC #usp_TablesComparer @t1 = 'Hier.HierMember', @t2 = '#TestHierMemberUPD', @col = 'HierID, HierMemberId.ToString() AS HierMemberId', @rows = @DiffRows OUTPUT
	ROLLBACK TRAN;
	INSERT INTO #TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, IIF(@DiffRows > 0, 0, 1), 'Number of differences: ' + CAST(@DiffRows AS varchar(10)));
END;

BEGIN --Test 4: Add an element which existed before - a new version is appeared (for parents too if they don't exist) 
	SET @TestNumber = '4'
	PRINT 'Test ' + @TestNumber + ' has started';

	DELETE FROM @SnapshotOfHierMembers
	INSERT INTO @SnapshotOfHierMembers (FullName, Attributes) SELECT Hier.ufn_MemberID_2_XML(t1.HierMemberId) AS FullName, cast('<Attributes/>' as XML) AS Attributes FROM
		(VALUES
				('/11/1/2/3/'),
				('/11/2/2/4/')
		) t1(HierMemberId);

	DELETE FROM #TestHierMemberVersionUPD;
	INSERT INTO #TestHierMemberVersionUPD SELECT * FROM #TestHierMemberVersion;
	INSERT INTO #TestHierMemberVersionUPD(HierId, HierMemberId, StartDate, EndDate, IsCurrent, Attributes)
		VALUES
			(1, '/11/1/',		'20150228', '99990101', 1, '<Attributes/>'),
			(1, '/11/1/2/',		'20150228', '99990101', 1, '<Attributes/>'),
			(1, '/11/1/2/3/',	'20150228', '99990101', 1, '<Attributes/>');
	
	BEGIN TRAN;
		EXEC Hier.usp_HierMembers_Refresh @HierId = @HierId, @SnapshotOfHierMembers = @SnapshotOfHierMembers, @Today = @Today;
		EXEC #usp_TablesComparer @t1 = 'Hier.HierMemberVersion', @t2 = '#TestHierMemberVersionUPD', @col = 'HierID, HierMemberId.ToString() AS HierMemberId, StartDate, EndDate, IsCurrent, CAST(Attributes AS varchar(max)) AS Attributes', @rows = @DiffRows OUTPUT
	ROLLBACK TRAN;
	INSERT INTO #TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, IIF(@DiffRows > 0, 0, 1), 'Number of differences: ' + CAST(@DiffRows AS varchar(10)));
END;

BEGIN -- !!!! Test 5: Send a snapshot with a new element, but there is parent's version with EndDate in nearest future (<> 99990101) - Error Message 50000...This is an interesting case for discussing later 
	SET @TestNumber = '5'
	PRINT 'Test ' + @TestNumber + ' has started';

	DELETE FROM @SnapshotOfHierMembers
	INSERT INTO @SnapshotOfHierMembers (FullName, Attributes) SELECT Hier.ufn_MemberID_2_XML(t1.HierMemberId) AS FullName, cast('<Attributes/>' as XML) AS Attributes FROM
		(VALUES
				('/11/2/2/4/'),
				('/11/2/2/5/')
		) t1(HierMemberId);

	BEGIN TRY;
		BEGIN TRAN;
			UPDATE Hier.HierMemberVersion SET EndDate = '20151231'
			WHERE HierId = @HierId AND HierMemberId in ('/11/2/2/4/', '/11/2/2/') AND EndDate = '99990101';
			EXEC Hier.usp_HierMembers_Refresh @HierId = @HierId, @SnapshotOfHierMembers = @SnapshotOfHierMembers, @Today = @Today;
			EXEC #usp_TablesComparer @t1 = 'Hier.HierMemberVersion', @t2 = '#TestHierMemberVersionUPD', @col = 'HierID, HierMemberId.ToString() AS HierMemberId, StartDate, EndDate, IsCurrent, CAST(Attributes AS varchar(max)) AS Attributes', @rows = @DiffRows OUTPUT
		ROLLBACK TRAN;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRAN;
		INSERT INTO #TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, IIF(ERROR_NUMBER() in(50000, 50003), 1, 0), FORMATMESSAGE('Error %d: %s', ERROR_NUMBER(), ERROR_MESSAGE()));
	END CATCH;
END;

SELECT * FROM #TestResult ORDER BY 2, 1;
IF EXISTS(SELECT * FROM sys.objects O WHERE O.object_id = OBJECT_ID('Hier.ufn_MemberID_2_XML'))
	DROP FUNCTION Hier.ufn_MemberID_2_XML;