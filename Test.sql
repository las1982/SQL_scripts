USE CSRMAR_DataMart_CI
GO
SET NOCOUNT, ANSI_NULLS, QUOTED_IDENTIFIER ON
	IF OBJECT_ID('tempdb..#usp_Test') IS NOT NULL DROP PROC #usp_Test;
	IF OBJECT_ID('tempdb..#ExpResMap') IS NOT NULL DROP TABLE #ExpResMap;
	IF OBJECT_ID('Test.HierMember') IS NOT NULL DROP TABLE Test.HierMember;
	IF OBJECT_ID('Test.HierMemberVersion') IS NOT NULL DROP TABLE Test.HierMemberVersion;
	IF OBJECT_ID('Test.HierMemberVersionInp') IS NOT NULL DROP TABLE Test.HierMemberVersionInp;
	IF OBJECT_ID('Test.HierMemberVersionRes') IS NOT NULL DROP TABLE Test.HierMemberVersionRes;
	IF OBJECT_ID('Test.TestResult') IS NOT NULL DROP TABLE Test.TestResult;
	IF EXISTS(SELECT * FROM sys.schemas WHERE name = 'Test') DROP SCHEMA Test;
GO
GO
CREATE SCHEMA Test AUTHORIZATION dbo
GO
create table #ExpResMap	(SrcHierId tinyint, DstHierId tinyint, SrcHierMemberId sys.hierarchyid, DstHierMemberId sys.hierarchyid, StartDate date, EndDate date);
create table Test.TestResult (TestNumber sysname, TestSuccessful bit, TestMessage nvarchar(2000) NULL);
GO
IF EXISTS(SELECT * FROM sys.objects O WHERE O.object_id = OBJECT_ID('Test.ufn_General_Interval2DateSet')) 
	DROP FUNCTION Test.ufn_General_Interval2DateSet;
GO
CREATE FUNCTION Test.ufn_General_Interval2DateSet (@StartDate date, @EndDate date)
	RETURNS TABLE RETURN
		WITH NaturalNumbers(Number) AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM sys.all_columns)
		SELECT DATEADD(day, Number - 1, @StartDate) [Date]
			FROM NaturalNumbers
			WHERE Number <= DATEDIFF(DAY, @StartDate, @EndDate) + 1;
GO
CREATE PROC #usp_Test AS
	IF OBJECT_ID('tempdb..#ExpResMap') IS NULL
		create table #ExpResMap	(SrcHierId tinyint, DstHierId tinyint, SrcHierMemberId sys.hierarchyid, DstHierMemberId sys.hierarchyid, StartDate date, EndDate date);
	with --comparing two tables: #EfMapFromDB and #ExpResMap
		ExpResMap (SrcHierId, SrcHierMemberId, SrcMemLifeDate, DstHierId, DstHierMemberId) as (
			select E.SrcHierId, E.SrcHierMemberId, D.[Date], E.DstHierId, E.DstHierMemberId 
				from 
					#ExpResMap E
					CROSS APPLY Test.ufn_General_Interval2DateSet (E.StartDate, E.EndDate) D
				WHERE
					(E.SrcHierId = 1 AND (E.SrcHierMemberId.IsDescendantOf('/11/') = 1 OR E.SrcHierMemberId.IsDescendantOf('/12/') = 1 OR E.SrcHierMemberId = '/')) OR
					(E.DstHierId = 1 AND (E.DstHierMemberId.IsDescendantOf('/11/') = 1 OR E.DstHierMemberId.IsDescendantOf('/12/') = 1 OR E.DstHierMemberId = '/'))),
		EfMapFromDB (SrcHierId, SrcHierMemberId, SrcMemLifeDate, DstHierId, DstHierMemberId) as (
			select E.SrcHierId, E.SrcHierMemberId, D.[Date], E.DstHierId, E.DstHierMemberId
				from 
					Hier.HierMemberMapping_Effective E
					CROSS APPLY Test.ufn_General_Interval2DateSet (E.StartDate, E.EndDate) D
				WHERE
					(E.SrcHierId = 1 AND (E.SrcHierMemberId.IsDescendantOf('/11/') = 1 OR E.SrcHierMemberId.IsDescendantOf('/12/') = 1 OR E.SrcHierMemberId = '/')) OR
					(E.DstHierId = 1 AND (E.DstHierMemberId.IsDescendantOf('/11/') = 1 OR E.DstHierMemberId.IsDescendantOf('/12/') = 1 OR E.DstHierMemberId = '/'))),
		Diff (SrcHierId, SrcHierMemberId, SrcMemLifeDate, DstHierId, DstHierMemberId, ExtraRowIn) AS (
			select *, 'Expected' from ExpResMap
			except
			select *, 'Expected' from EfMapFromDB
			union
			select *, 'Actual' from EfMapFromDB
			except
			select *, 'Actual' from ExpResMap)
	SELECT SrcHierId, SrcHierMemberId.ToString() SrcHierMemberId, SrcMemLifeDate, DstHierId, DstHierMemberId.ToString() DstHierMemberId, ExtraRowIn FROM Diff
	order by 1, 2, 3, 4, 5
GO
DECLARE @TestNumber sysname;
BEGIN --Initial clean up
	DELETE FROM Hier.HierMemberVersion 
		WHERE HierId IN (1, 6) AND (HierMemberId.IsDescendantOf('/11/') = 1 OR HierMemberId.IsDescendantOf('/12/') = 1);
	DELETE FROM Hier.HierMemberMapping 
		WHERE SrcHierId = 1 AND (SrcHierMemberId.IsDescendantOf('/') = 1 OR SrcHierMemberId.IsDescendantOf('/11/') = 1 OR SrcHierMemberId.IsDescendantOf('/12/') = 1);
	DELETE FROM Hier.HierMember 
		WHERE HierId IN (1, 6) AND (HierMemberId.IsDescendantOf('/11/') = 1 OR HierMemberId.IsDescendantOf('/12/') = 1);
END;
BEGIN --Test 1.1: General
	SET @TestNumber = '1.1'
	PRINT 'Test ' + @TestNumber + ' has started';
	INSERT INTO #ExpResMap (SrcHierId, DstHierId, SrcHierMemberId, DstHierMemberId, StartDate, EndDate)
		VALUES
		(1,	6,	'/11/1/1/',		'/12/1/',		'20150103',		'20150105'),
		(1,	6,	'/11/1/1/',		'/12/2/',		'20150109',		'20150109'),
		(1,	6,	'/11/1/1/',		'/12/4/',		'20150110',		'20150113'),
		(1,	6,	'/11/1/1/',		'/12/5/',		'20150114',		'20150117'),
		(1,	6,	'/11/1/1/',		'/12/6/',		'20150118',		'20150119'),
		(1,	6,	'/11/1/1/',		'/12/7/',		'20150120',		'20150126'),
		(1,	6,	'/11/1/1/',		'/12/8/',		'20150127',		'20150128'),
		(1,	6,	'/11/1/1/',		'/12/10/',		'20150131',		'20150201'),
		(1,	6,	'/11/1/1/',		'/12/9/',		'20150202',		'20150203'),
		(1,	6,	'/11/1/1/',		'/12/14/',		'20150204',		'20150204'),
		(1,	6,	'/11/1/',		'/12/1/',		'20150103',		'20150107'),
		(1,	6,	'/11/1/',		'/12/2/',		'20150108',		'20150115'),
		(1,	6,	'/11/1/',		'/12/6/',		'20150116',		'20150122'),
		(1,	6,	'/11/1/',		'/12/8/',		'20150123',		'20150128'),
		(1,	6,	'/11/1/',		'/12/9/',		'20150130',		'20150203'),
		(1,	6,	'/11/1/',		'/12/14/',		'20150204',		'20150205'),
		(1,	6,	'/11/',			'/12/3/',		'20150106',		'20150117'),
		(1,	6,	'/11/',			'/12/8/',		'20150118',		'20150131'),
		(1,	6,	'/11/',			'/12/14/',		'20150203',		'20150207'),
		(1,	6,	'/12/',			'/12/1/',		'20150104',		'20150106'),
		(1,	6,	'/12/',			'/12/2/',		'20150110',		'20150111'),
		(1,	6,	'/12/',			'/12/2/',		'20150115',		'20150115'),
		(1,	6,	'/12/',			'/12/6/',		'20150118',		'20150122'),
		(1,	6,	'/12/',			'/12/9/',		'20150131',		'20150203');
	INSERT INTO Hier.HierMember (HierId, HierMemberId, Name, FullName)
		VALUES
			(1,	'/11/',		'.11.',		'<M Name=".11."		Level="1"/>'),
			(1,	'/11/1/',	'.11.1.',	'<M Name=".11.1."	Level="2">	<M Name=".11."	Level="1"/></M>'),
			(1,	'/11/1/1/',	'.11.1.1.', '<M Name=".11.1.1."	Level="3">	<M Name=".11.1." Level="2">	<M Name=".11." Level="1" /></M></M>'),
			(1,	'/12/',		'.12.',		'<M Name=".12."		Level="1"/>'),
			(6,	'/12/',		'.12.',		'<M Name=".12."		Level="1"/>'),
			(6,	'/12/1/',	'.12.1.',	'<M Name=".12.1."	Level="2">	<M Name=".12."	Level="1"/></M>'),
			(6,	'/12/2/',	'.12.2.',	'<M Name=".12.2."	Level="2">	<M Name=".12."	Level="1"/></M>'),
			(6,	'/12/3/',	'.12.3.',	'<M Name=".12.3."	Level="2">	<M Name=".12."	Level="1"/></M>'),
			(6,	'/12/4/',	'.12.4.',	'<M Name=".12.4."	Level="2">	<M Name=".12."	Level="1"/></M>'),
			(6,	'/12/5/',	'.12.5.',	'<M Name=".12.5."	Level="2">	<M Name=".12."	Level="1"/></M>'),
			(6,	'/12/6/',	'.12.6.',	'<M Name=".12.6."	Level="2">	<M Name=".12."	Level="1"/></M>'),
			(6,	'/12/7/',	'.12.7.',	'<M Name=".12.7."	Level="2">	<M Name=".12."	Level="1"/></M>'),
			(6,	'/12/8/',	'.12.8.',	'<M Name=".12.8."	Level="2">	<M Name=".12."	Level="1"/></M>'),
			(6,	'/12/9/',	'.12.9.',	'<M Name=".12.9."	Level="2">	<M Name=".12."	Level="1"/></M>'),
			(6,	'/12/10/',	'.12.10.',	'<M Name=".12.10."	Level="2">	<M Name=".12."	Level="1"/></M>'),
			(6,	'/12/14/',	'.12.14.',	'<M Name=".12.14."	Level="2">	<M Name=".12."	Level="1"/></M>');
	INSERT INTO Hier.HierMemberVersion(HierId, HierMemberId, StartDate, EndDate, IsCurrent, Attributes)
		VALUES
			(1,	'/11/',		'20150101',	'20150211',	0,	NULL),
			(1,	'/11/1/',	'20150102',	'20150128',	0,	NULL),
			(1,	'/11/1/',	'20150130',	'20150205',	0,	NULL),
			(1,	'/11/1/1/',	'20150102',	'20150105',	0,	NULL),
			(1,	'/11/1/1/',	'20150109',	'20150128',	0,	NULL),
			(1,	'/11/1/1/',	'20150131',	'20150204',	0,	NULL),
			(1,	'/12/',		'20150101',	'20150111',	0,	NULL),
			(1,	'/12/',		'20150115',	'20150115',	0,	NULL),
			(1,	'/12/',		'20150118',	'20150123',	0,	NULL),
			(1,	'/12/',		'20150129',	'20150207',	0,	NULL),
			(1,	'/12/',		'20150209',	'20150212',	0,	NULL),
			(6,	'/12/',		'20150101',	'20150228',	0,	NULL),
			(6,	'/12/1/',	'20150103',	'20150113',	0,	NULL),
			(6,	'/12/2/',	'20150104',	'20150116',	0,	NULL),
			(6,	'/12/2/',	'20150121',	'20150204',	0,	NULL),
			(6,	'/12/3/',	'20150104',	'20150119',	0,	NULL),
			(6,	'/12/4/',	'20150110',	'20150121',	0,	NULL),
			(6,	'/12/5/',	'20150114',	'20150117',	0,	NULL),
			(6,	'/12/6/',	'20150116',	'20150122',	0,	NULL),
			(6,	'/12/6/',	'20150128',	'20150202',	0,	NULL),
			(6,	'/12/7/',	'20150118',	'20150126',	0,	NULL),
			(6,	'/12/8/',	'20150116',	'20150131',	0,	NULL),
			(6,	'/12/9/',	'20150109',	'20150120',	0,	NULL),
			(6,	'/12/9/',	'20150126',	'20150203',	0,	NULL),
			(6,	'/12/10/',	'20150123',	'20150201',	0,	NULL),
			(6,	'/12/14/',	'20150127',	'20150131',	0,	NULL),
			(6,	'/12/14/',	'20150203',	'20150207',	0,	NULL);
	INSERT INTO Hier.HierMemberMapping(StartDate, EndDate, IsCurrent, SrcHierId, SrcHierMemberId, DstHierId, DstHierMemberId)
		VALUES
			('20150106',	'20150117',	0,	1,	'/11/',		6,	'/12/3/'),
			('20150118',	'20150201',	0,	1,	'/11/',		6,	'/12/8/'),
			('20150202',	'20150211',	0,	1,	'/11/',		6,	'/12/14/'),
			('20150101',	'20150107',	0,	1,	'/11/1/',	6,	'/12/1/'),
			('20150108',	'20150115',	0,	1,	'/11/1/',	6,	'/12/2/'),
			('20150116',	'20150125',	0,	1,	'/11/1/',	6,	'/12/6/'),
			('20150129',	'20150205',	0,	1,	'/11/1/',	6,	'/12/9/'),
			('20150106',	'20150113',	0,	1,	'/11/1/1/',	6,	'/12/4/'),
			('20150114',	'20150119',	0,	1,	'/11/1/1/',	6,	'/12/5/'),
			('20150120',	'20150130',	0,	1,	'/11/1/1/',	6,	'/12/7/'),
			('20150131',	'20150203',	0,	1,	'/11/1/1/',	6,	'/12/10/'),
			('20150104',	'20150106',	0,	1,	'/12/',		6,	'/12/1/'),
			('20150110',	'20150115',	0,	1,	'/12/',		6,	'/12/2/'),
			('20150116',	'20150125',	0,	1,	'/12/',		6,	'/12/6/'),
			('20150131',	'20150205',	0,	1,	'/12/',		6,	'/12/9/');
	EXEC #usp_Test;
	INSERT INTO Test.TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, IIF(@@ROWCOUNT > 0, 0, 1), 'Number of differences: ' + CAST(@@ROWCOUNT AS varchar(10)));
END;
BEGIN --Test 1.2: Orphaned child
	SET @TestNumber = '1.2'
	BEGIN TRY
		PRINT 'Test ' + @TestNumber + ' has started';
		BEGIN TRAN;
		UPDATE Hier.HierMemberVersion SET StartDate = '20150103'
			WHERE HierId = 1 AND HierMemberId = '/11/1/' AND StartDate = '20150102' AND EndDate = '20150128';
		ROLLBACK TRAN;
		INSERT INTO Test.TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, 0, NULL);
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRAN;
		INSERT INTO Test.TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, IIF(ERROR_NUMBER() = 50003, 1, 0), FORMATMESSAGE('Error %d: %s', ERROR_NUMBER(), ERROR_MESSAGE()));
	END CATCH;
END;
BEGIN --Test 1.3.1: Mapping's destination member is a group. Failed inserts
	BEGIN TRY
		SET @TestNumber = '1.3.1'
		PRINT 'Test ' + @TestNumber + ' has started';
		BEGIN TRAN;
		INSERT INTO Hier.HierMember (HierId, HierMemberId, Name, FullName)
			VALUES
				(6,	'/12/1/1/',	'.12.1.1.',	'<M Name=".12.1.1."	Level="3">	<M Name=".12.1."	Level="2">	<M Name=".12."	Level="1"/></M></M>'),
				(6,	'/12/2/1/',	'.12.2.1.',	'<M Name=".12.2.1."	Level="3">	<M Name=".12.2."	Level="2">	<M Name=".12."	Level="1"/></M></M>'),
				(6,	'/12/6/1/',	'.12.6.1.',	'<M Name=".12.6.1."	Level="3">	<M Name=".12.6."	Level="2">	<M Name=".12."	Level="1"/></M></M>'),
				(6,	'/12/9/1/',	'.12.9.1.',	'<M Name=".12.9.1."	Level="3">	<M Name=".12.9."	Level="2">	<M Name=".12."	Level="1"/></M></M>');
		INSERT INTO Hier.HierMemberVersion(HierId, HierMemberId, StartDate, EndDate, IsCurrent, Attributes)
			VALUES
				(6,	'/12/1/1/',	'20150107',	'20150107',	0,	NULL),
				(6,	'/12/2/1/',	'20150122',	'20150203',	0,	NULL),
				(6,	'/12/6/1/',	'20150121',	'20150122',	0,	NULL),
				(6,	'/12/6/1/',	'20150128',	'20150202',	0,	NULL),
				(6,	'/12/9/1/',	'20150112',	'20150115',	0,	NULL),
				(6,	'/12/9/1/',	'20150126',	'20150128',	0,	NULL);
		ROLLBACK TRAN;
		INSERT INTO Test.TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, 0, NULL);
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRAN;
		INSERT INTO Test.TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, IIF(ERROR_NUMBER() = 50001, 1, 0), FORMATMESSAGE('Error %d: %s', ERROR_NUMBER(), ERROR_MESSAGE()));
	END CATCH;
END;
BEGIN --Test 1.3.2: Mapping's destination member is a group. Successful inserts
	BEGIN TRY
		SET @TestNumber = '1.3.2'
        PRINT 'Test ' + @TestNumber + ' has started';
		BEGIN TRAN;
		INSERT INTO Hier.HierMember (HierId, HierMemberId, Name, FullName)
			VALUES
				(6,	'/12/1/1/',	'.12.1.1.',	'<M Name=".12.1.1."	Level="3">	<M Name=".12.1."	Level="2">	<M Name=".12."	Level="1"/></M></M>'),
				(6,	'/12/2/1/',	'.12.2.1.',	'<M Name=".12.2.1."	Level="3">	<M Name=".12.2."	Level="2">	<M Name=".12."	Level="1"/></M></M>'),
				(6,	'/12/6/1/',	'.12.6.1.',	'<M Name=".12.6.1."	Level="3">	<M Name=".12.6."	Level="2">	<M Name=".12."	Level="1"/></M></M>'),
				(6,	'/12/9/1/',	'.12.9.1.',	'<M Name=".12.9.1."	Level="3">	<M Name=".12.9."	Level="2">	<M Name=".12."	Level="1"/></M></M>');
		INSERT INTO Hier.HierMemberVersion(HierId, HierMemberId, StartDate, EndDate, IsCurrent, Attributes)
			VALUES
				(6,	'/12/1/1/',	'20150108',	'20150108',	0,	NULL),
				(6,	'/12/2/1/',	'20150122',	'20150203',	0,	NULL),
				(6,	'/12/6/1/',	'20150128',	'20150202',	0,	NULL),
				(6,	'/12/9/1/',	'20150112',	'20150115',	0,	NULL),
				(6,	'/12/9/1/',	'20150126',	'20150128',	0,	NULL);
		ROLLBACK TRAN;
		INSERT INTO Test.TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, 1, NULL);
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRAN;
		INSERT INTO Test.TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, 0, FORMATMESSAGE('Error %d: %s', ERROR_NUMBER(), ERROR_MESSAGE()));
	END CATCH;
END;
BEGIN --Test 1.3.3: Mapping's destination member is a group: UPDATE member version which extends existing interval (as a result, there is mapping to a group) 
       BEGIN TRY
		SET @TestNumber = '1.3.3'
              PRINT 'Test ' + @TestNumber + ' has started';
              BEGIN TRAN;
              INSERT INTO Hier.HierMember (HierId, HierMemberId, Name, FullName)
                     VALUES
                           (6,    '/12/1/1/',   '.12.1.1.',   '<M Name=".12.1.1."  Level="3">    <M Name=".12.1." Level="2">    <M Name=".12."       Level="1"/></M></M>'),
                           (6,    '/12/2/1/',   '.12.2.1.',   '<M Name=".12.2.1."  Level="3">    <M Name=".12.2." Level="2">    <M Name=".12."       Level="1"/></M></M>'),
                           (6,    '/12/6/1/',   '.12.6.1.',   '<M Name=".12.6.1."  Level="3">    <M Name=".12.6." Level="2">    <M Name=".12."       Level="1"/></M></M>'),
                           (6,    '/12/9/1/',   '.12.9.1.',   '<M Name=".12.9.1."  Level="3">    <M Name=".12.9." Level="2">    <M Name=".12."       Level="1"/></M></M>');
              INSERT INTO Hier.HierMemberVersion(HierId, HierMemberId, StartDate, EndDate, IsCurrent, Attributes)
                     VALUES
                           (6,    '/12/1/1/',   '20150108',   '20150108',   0,     NULL),
                           (6,    '/12/2/1/',   '20150122',   '20150203',   0,     NULL),
                           (6,    '/12/6/1/',   '20150128',   '20150202',   0,     NULL),
                           (6,    '/12/9/1/',   '20150112',   '20150115',   0,     NULL),
                           (6,    '/12/9/1/',   '20150126',   '20150128',   0,     NULL);
                     UPDATE Hier.HierMemberVersion SET StartDate = '20150107'
                           WHERE HierId = 6 AND HierMemberId = '/12/1/1/' AND StartDate = '20150108' AND EndDate = '20150108';
              ROLLBACK TRAN;
              INSERT INTO Test.TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, 0, NULL);
       END TRY
       BEGIN CATCH
              IF @@TRANCOUNT > 0 ROLLBACK TRAN;
              INSERT INTO Test.TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, IIF(ERROR_NUMBER() = 50001, 1, 0), FORMATMESSAGE('Error %d: %s', ERROR_NUMBER(), ERROR_MESSAGE()));
       END CATCH;
END;
BEGIN --Test 1.3.4: Mapping's destination member is a group: UPDATE member version which extends existing interval 
       BEGIN TRY
			SET @TestNumber = '1.3.4'
              PRINT 'Test ' + @TestNumber + ' has started';
              BEGIN TRAN;
              INSERT INTO Hier.HierMember (HierId, HierMemberId, Name, FullName)
                     VALUES
                           (6,    '/12/1/1/',   '.12.1.1.',   '<M Name=".12.1.1."  Level="3">    <M Name=".12.1." Level="2">    <M Name=".12."       Level="1"/></M></M>'),
                           (6,    '/12/2/1/',   '.12.2.1.',   '<M Name=".12.2.1."  Level="3">    <M Name=".12.2." Level="2">    <M Name=".12."       Level="1"/></M></M>'),
                           (6,    '/12/6/1/',   '.12.6.1.',   '<M Name=".12.6.1."  Level="3">    <M Name=".12.6." Level="2">    <M Name=".12."       Level="1"/></M></M>'),
                           (6,    '/12/9/1/',   '.12.9.1.',   '<M Name=".12.9.1."  Level="3">    <M Name=".12.9." Level="2">    <M Name=".12."       Level="1"/></M></M>');
              INSERT INTO Hier.HierMemberVersion(HierId, HierMemberId, StartDate, EndDate, IsCurrent, Attributes)
                     VALUES
                           (6,    '/12/1/1/',   '20150108',   '20150108',   0,     NULL),
                           (6,    '/12/2/1/',   '20150122',   '20150203',   0,     NULL),
                           (6,    '/12/6/1/',   '20150128',   '20150202',   0,     NULL),
                           (6,    '/12/9/1/',   '20150112',   '20150115',   0,     NULL),
                           (6,    '/12/9/1/',   '20150126',   '20150128',   0,     NULL);
                     UPDATE Hier.HierMemberVersion SET StartDate = '20150121'
                           WHERE HierId = 6 AND HierMemberId = '/12/6/1/' AND StartDate = '20150128' AND EndDate = '20150202';
              ROLLBACK TRAN;
              INSERT INTO Test.TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, 0, NULL);
       END TRY
       BEGIN CATCH
              IF @@TRANCOUNT > 0 ROLLBACK TRAN;
			  INSERT INTO Test.TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, IIF(ERROR_NUMBER() = 50003, 1, 0), FORMATMESSAGE('Error %d: %s', ERROR_NUMBER(), ERROR_MESSAGE()));
       END CATCH;
END;
BEGIN --Test 1.4: UPDATE MappingVersion (trying to overlap MappingVersions for one member): UPDATE is forbidden 
	BEGIN TRY
		SET @TestNumber = '1.4'
		PRINT 'Test ' + @TestNumber + ' has started';
		BEGIN TRAN;
		UPDATE Hier.HierMemberMapping SET EndDate = '20150110'
			WHERE SrcHierId = 1 AND DstHierId = 6 AND SrcHierMemberId = '/11/1/' AND DstHierMemberId = '/12/1/' AND StartDate = '20150101' AND EndDate = '20150107';
		ROLLBACK TRAN;
		INSERT INTO Test.TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, 0, NULL);
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRAN;
		INSERT INTO Test.TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, IIF(ERROR_NUMBER() = 50005, 1, 0), FORMATMESSAGE('Error %d: %s', ERROR_NUMBER(), ERROR_MESSAGE()));
	END CATCH;
END;
BEGIN --Test 1.4.1: INSERT MappingVersion (trying to overlap MappingVersions for one member): INSERT is forbidden 
	BEGIN TRY
		SET @TestNumber = '1.4.1'
		PRINT 'Test ' + @TestNumber + ' has started';
		BEGIN TRAN;
		INSERT INTO Hier.HierMemberMapping(StartDate, EndDate, IsCurrent, SrcHierId, SrcHierMemberId, DstHierId, DstHierMemberId)
			VALUES
				('20150103',	'20150105',	0,	1,	'/11/1/',	6,	'/12/1/');
		ROLLBACK TRAN;
		INSERT INTO Test.TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, 0, NULL);
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRAN;
		INSERT INTO Test.TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, IIF(ERROR_NUMBER() = 50005, 1, 0), FORMATMESSAGE('Error %d: %s', ERROR_NUMBER(), ERROR_MESSAGE()));
	END CATCH;
END;
BEGIN --Test 1.5: UPDATE MemberVersion (trying to overlap MemberVersions for one member): UPDATE is forbidden 
	BEGIN TRY
		SET @TestNumber = '1.5'
		PRINT 'Test ' + @TestNumber + ' has started';
		BEGIN TRAN;
		UPDATE Hier.HierMemberVersion SET EndDate = '20150110'
			WHERE HierId = 1 AND HierMemberId = '/11/1/1/' AND StartDate = '20150102' AND EndDate = '20150105';
		ROLLBACK TRAN;
		INSERT INTO Test.TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, 0, NULL);
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRAN;
		INSERT INTO Test.TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, IIF(ERROR_NUMBER() = 50004, 1, 0), FORMATMESSAGE('Error %d: %s', ERROR_NUMBER(), ERROR_MESSAGE()));
	END CATCH;
END;
BEGIN --Test 1.5.1: INSERT MemberVersion (trying to overlap MemberVersions for one member): INSERT is forbidden 
	BEGIN TRY
		SET @TestNumber = '1.5.1'
		PRINT 'Test ' + @TestNumber + ' has started';
		BEGIN TRAN;
		INSERT INTO Hier.HierMemberVersion(HierId, HierMemberId, StartDate, EndDate, IsCurrent, Attributes)
			VALUES
				(1,	'/11/',		'20150105',	'20150215',	0,	NULL);
		ROLLBACK TRAN;
		INSERT INTO Test.TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, 0, NULL);
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRAN;
		INSERT INTO Test.TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, IIF(ERROR_NUMBER() = 50004, 1, 0), FORMATMESSAGE('Error %d: %s', ERROR_NUMBER(), ERROR_MESSAGE()));
	END CATCH;
END;
BEGIN --Test 1.5.2: DELETE MemberVersion (trying to delete parent version, but it has child in this version): DELETE is forbidden 
	BEGIN TRY
		SET @TestNumber = '1.5.2'
		PRINT 'Test ' + @TestNumber + ' has started';
		BEGIN TRAN;
		DELETE FROM Hier.HierMemberVersion WHERE
			HierId = 1 AND HierMemberId = '/11/1/' AND StartDate = '20150130' AND EndDate = '20150205';
		ROLLBACK TRAN;
		INSERT INTO Test.TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, 0, NULL);
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRAN;
		INSERT INTO Test.TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, IIF(ERROR_NUMBER() = 50003, 1, 0), FORMATMESSAGE('Error %d: %s', ERROR_NUMBER(), ERROR_MESSAGE()));
	END CATCH;
END;
BEGIN --Test 1.6: INSERT Member (child), but there is no parent for him: INSERT is forbidden 
	BEGIN TRY
		SET @TestNumber = '1.6'
		PRINT 'Test ' + @TestNumber + ' has started';
		BEGIN TRAN;
		INSERT INTO Hier.HierMember (HierId, HierMemberId, Name, FullName)
			VALUES
--				(1,	'/13/',		'.13.',		'<M Name=".13."		Level="1"/>'),
				(1,	'/13/1/',	'.13.1.',	'<M Name=".13.1."	Level="2">	<M Name=".13."	Level="1"/></M>');
		ROLLBACK TRAN;
		INSERT INTO Test.TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, 0, NULL);
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRAN;
		INSERT INTO Test.TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, IIF(ERROR_NUMBER() = 547, 1, 0), FORMATMESSAGE('Error %d: %s', ERROR_NUMBER(), ERROR_MESSAGE()));
	END CATCH;
END;
BEGIN --Test 1.7: DELETE Member (parent) witch has child: DELETE is forbidden 
	BEGIN TRY
		SET @TestNumber = '1.7'
		PRINT 'Test ' + @TestNumber + ' has started';
		BEGIN TRAN;
		INSERT INTO Hier.HierMember (HierId, HierMemberId, Name, FullName)
			VALUES
				(1,	'/13/',		'.13.',		'<M Name=".13."		Level="1"/>'),
				(1,	'/13/1/',	'.13.1.',	'<M Name=".13.1."	Level="2">	<M Name=".13."	Level="1"/></M>');
			DELETE FROM Hier.HierMember WHERE
			HierId = 1 AND HierMemberId = '/13/'
--			HierId = 1 AND HierMemberId = '/13/1/';
		ROLLBACK TRAN;
		INSERT INTO Test.TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, 0, NULL);
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRAN;
		INSERT INTO Test.TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, IIF(ERROR_NUMBER() = 547, 1, 0), FORMATMESSAGE('Error %d: %s', ERROR_NUMBER(), ERROR_MESSAGE()));
	END CATCH;
END;
BEGIN --Test 1.8: UPDATE Member: in any case - forbidden 
	BEGIN TRY
	set @TestNumber = '1.8'
		PRINT 'Test ' + @TestNumber + ' has started';
		BEGIN TRAN;
		INSERT INTO Hier.HierMember (HierId, HierMemberId, Name, FullName)
			VALUES
				(1,	'/13/',		'.13.',		'<M Name=".13."		Level="1"/>'),
				(1,	'/13/1/',	'.13.1.',	'<M Name=".13.1."	Level="2">	<M Name=".13."	Level="1"/></M>');
			UPDATE Hier.HierMember SET HierMemberId = '/14/1/' WHERE
			HierId = 1 AND HierMemberId = '/13/';
--			HierId = 1 AND HierMemberId = '/13/1/'
		ROLLBACK TRAN;
		INSERT INTO Test.TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, 0, NULL);
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRAN;
		INSERT INTO Test.TestResult (TestNumber, TestSuccessful, TestMessage) VALUES (@TestNumber, IIF(ERROR_NUMBER() = 50000, 1, 0), FORMATMESSAGE('Error %d: %s', ERROR_NUMBER(), ERROR_MESSAGE()));
	END CATCH;
END;


SELECT * FROM Test.TestResult ORDER BY TestSuccessful, TestNumber;
GO
IF EXISTS(SELECT * FROM sys.objects O WHERE O.object_id = OBJECT_ID('Test.ufn_General_Interval2DateSet')) 
	DROP FUNCTION Test.ufn_General_Interval2DateSet;