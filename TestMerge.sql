SET NOCOUNT ON;
GO
DECLARE @Tests TABLE(TestId tinyint, TestName sysname, Success bit NULL);
DECLARE @TestUnmatchedRows TABLE(TestId tinyint, HierMemberId varchar(128) NULL, StartDate date NULL, EndDate date NULL, Attributes xml NULL, ExtraRowIn char(8) NULL);
DECLARE 
	@CurrTestId tinyint,
	@HierMemberSet Hier.udt_HierMember2,
	@HierMemberVersionSet Hier.udt_HierMemberVersion1,
	@CurrTestResult bit;
INSERT INTO @Tests (TestId, TestName) 
	VALUES
		--(1, 'Test1'),
		--(2, 'Test2'),
		(3, 'Test3')
		--(4, 'Test4'),
		--(5, 'Test5'),
		--(6, 'Test6'),
		--(7, 'Test7');
DECLARE Tests CURSOR FOR SELECT TestId FROM @Tests ORDER BY TestId;
OPEN Tests;  
WHILE 1 = 1
	BEGIN  
		FETCH NEXT FROM Tests INTO @CurrTestId;
		IF @@FETCH_STATUS <> 0 BREAK;
		DELETE FROM @HierMemberSet;
		DELETE FROM @HierMemberVersionSet;
		BEGIN; --Cleans up the hierarchy
			DELETE FROM Hier.HierMemberVersion WHERE HierId = 255;
			DELETE FROM Hier.HierMember WHERE HierId = 255;
			DELETE FROM Hier.Hier WHERE HierId = 255;
		END;
		BEGIN; --Creates the standard members
			DECLARE @Hier TABLE (
				HierId tinyint NOT NULL PRIMARY KEY,
				Name varchar(128) NOT NULL UNIQUE,
				AllowAutomaticChanges bit NOT NULL,
				AllowManualChanges bit NOT NULL,
				Alias varchar(128) NULL,
				NumberOfLvl tinyint NOT NULL, 
				Comment nvarchar(MAX) NULL,
				RootMemberName varchar(128) NULL);
			DELETE FROM @Hier;
			DECLARE
				@EmptyAttributes_xml xml,
				@EmptyAttributes_str varchar(MAX),
				@AttributeSet Hier.udt_HierMemberAttribute;
			SET @EmptyAttributes_xml = Hier.ufn_HierMemberAttributeSet2xml (@AttributeSet);
			SET @EmptyAttributes_str = CAST(@EmptyAttributes_xml AS varchar(MAX));
			INSERT INTO @Hier(HierId, Name, AllowAutomaticChanges, AllowManualChanges, NumberOfLvl, RootMemberName) VALUES (255, 'Test', 0, 1, 	4, 'All');
			MERGE --Refreshes Hier.Hier
				INTO Hier.Hier D USING @Hier S ON S.HierId = D.HierId
				WHEN MATCHED THEN UPDATE SET Name = S.Name, AllowAutomaticChanges = S.AllowAutomaticChanges, AllowManualChanges = S.AllowManualChanges, 
					Alias = S.Alias, NumberOfLvl = S.NumberOfLvl, Comment = S.Comment, RootMemberName = S.RootMemberName
				WHEN NOT MATCHED BY TARGET THEN INSERT(HierId, Name, AllowAutomaticChanges, AllowManualChanges, Alias, NumberOfLvl, Comment, RootMemberName) 
					VALUES (S.HierId, S.Name, S.AllowAutomaticChanges, S.AllowManualChanges, S.Alias, S.NumberOfLvl, S.Comment, S.RootMemberName);
			BEGIN --Creates [All] members and their versions if necessary
				UPDATE D SET Name = S.Name, FullName = ''
					FROM
						Hier.HierMember D
						INNER JOIN @Hier S ON S.HierId = D.HierId
					WHERE D.HierMemberId = '/' AND (D.Name != S.Name OR D.FullNameStr != '');
				INSERT INTO Hier.HierMember(HierMemberId, Name, HierId, FullName)
					SELECT '/', RootMemberName, HierId, '' FROM @Hier S WHERE NOT EXISTS(SELECT * FROM Hier.HierMember D WHERE D.HierId = S.HierId AND D.HierMemberId = '/');
				MERGE INTO Hier.HierMemberVersion D
					USING @Hier S ON D.HierMemberId = '/' AND S.HierId = D.HierId
					WHEN MATCHED AND (D.StartDate != '20000101' OR D.EndDate != '99990101' OR D.IsCurrent != 1 OR D.AttributesStr != @EmptyAttributes_str)
						THEN UPDATE SET StartDate = '20000101', EndDate = '99990101', IsCurrent = 1, Attributes = @EmptyAttributes_xml
					WHEN NOT MATCHED BY TARGET THEN INSERT(HierId, HierMemberId, StartDate, EndDate, IsCurrent, Attributes) 
						VALUES (S.HierId, '/', '20000101', '99990101', 1, @EmptyAttributes_xml);
		END;
			BEGIN --Creates [Unknown] members and their versions if necessary
				DECLARE @UndefinedMembers TABLE (HierId tinyint, Lvl int, HierMemberId sys.hierarchyid, Name varchar(128), FullName xml, FullNameStr AS (CONVERT([varchar](max),[FullName])));
				DELETE FROM @UndefinedMembers;
				WITH Numbers (Number) AS (SELECT * FROM (VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10)) N(N))
				INSERT INTO @UndefinedMembers (HierId, Lvl, HierMemberId, Name, FullName)
					SELECT HierId, UnknownMemberLevel.Number, REPLICATE('/0', UnknownMemberLevel.Number) + '/', 'UNKNOWN',
						Hier.ufn_General_NameXML2HierMemberFullName (
							(SELECT AncestorLevel.Number [@Level], 'UNKNOWN'
								FROM
									@Hier IH
									CROSS JOIN Numbers AncestorLevel
								WHERE IH.HierId = OH.HierId AND AncestorLevel.Number <= UnknownMemberLevel.Number
								ORDER BY IH.HierId 
								FOR XML PATH('Name'), TYPE))
						FROM
							@Hier OH
							INNER JOIN Numbers UnknownMemberLevel ON UnknownMemberLevel.Number <= OH.NumberOfLvl
				UPDATE Hier.HierMember SET Name = S.Name, FullName = S.FullName 
					FROM
						Hier.HierMember D
						INNER JOIN @UndefinedMembers S ON S.HierId = D.HierId AND S.HierMemberId = D.HierMemberId
					WHERE D.Name != S.Name OR D.FullNameStr != S.FullNameStr;
				INSERT INTO Hier.HierMember (HierId, HierMemberId, Name, FullName) 
					SELECT HierId, HierMemberId, Name, FullName 
						FROM @UndefinedMembers OM
						WHERE NOT EXISTS(SELECT * FROM Hier.HierMember IM WHERE IM.HierId = OM.HierId AND IM.HierMemberId = OM.HierMemberId);
				MERGE Hier.HierMemberVersion D
					USING @UndefinedMembers S ON S.HierId = D.HierId AND S.HierMemberId = D.HierMemberId
					WHEN MATCHED AND (D.StartDate != '20000101' OR D.EndDate != '99990101' OR D.IsCurrent != 1 OR D.AttributesStr != @EmptyAttributes_str)
						THEN UPDATE SET StartDate = '20000101', EndDate = '99990101', IsCurrent = 1, Attributes = @EmptyAttributes_xml
					WHEN NOT MATCHED BY TARGET THEN INSERT(HierId, HierMemberId, StartDate, EndDate, IsCurrent, Attributes) 
						VALUES (S.HierId, HierMemberId, '20000101', '99990101', 1, @EmptyAttributes_xml);
			END;
		END;
		BEGIN; --Populates test's data
			INSERT INTO Hier.HierMember (HierId, HierMemberId, Name, FullName) 
				SELECT 255, HierMemberId, Name, FullName FROM Test.HierMember WHERE TestNumber = @CurrTestId;
			INSERT INTO Hier.HierMemberVersion (HierId, HierMemberId, StartDate, EndDate, IsCurrent, Attributes)
				SELECT 255, HierMemberId, StartDate, EndDate, 0, Attributes FROM Test.HierMemberVersion WHERE TestNumber = @CurrTestId;
			INSERT INTO @HierMemberSet (MemberId, FullName)
				SELECT HierMemberLocalId, FullName FROM Test.HierMember WHERE TestNumber = @CurrTestId;
			INSERT INTO @HierMemberVersionSet (HierMemberLocalId, StartDate, EndDate, [Action], Attributes)
				SELECT HierMemberLocalId, StartDate, EndDate, [Action], Attributes FROM Test.HierMemberVersionInp WHERE TestNumber = @CurrTestId;
		END;
		EXEC Hier.usp_HierMembersVersions_Merge
		   @HierId = 255,
		   @HierMemberSet = @HierMemberSet,
		   @HierMemberVersionSet = @HierMemberVersionSet;
		BEGIN; --Checks the result of the test
			INSERT INTO @TestUnmatchedRows(TestId, HierMemberId, StartDate, EndDate, Attributes, ExtraRowIn)
				SELECT @CurrTestId, HierMemberId, StartDate, EndDate, CAST(Attributes AS xml) Attributes, ExtraRowIn
					FROM (
						SELECT HierMemberId.ToString() HierMemberId, StartDate, EndDate, CAST(Attributes AS nvarchar(max)) Attributes, 'Actual' AS ExtraRowIn 
							FROM Hier.HierMemberVersion
							WHERE HierId = 255
						EXCEPT
						SELECT HierMemberId.ToString() HierMemberId, StartDate, EndDate, CAST(Attributes AS nvarchar(max)) Attributes, 'Actual' AS ExtraRowIn 
							FROM Test.HierMemberVersionRes 
							WHERE TestNumber = @CurrTestId
						UNION
						SELECT HierMemberId.ToString() HierMemberId, StartDate, EndDate, CAST(Attributes AS nvarchar(max)) Attributes, 'Expected' AS ExtraRowIn 
							FROM Test.HierMemberVersionRes 
							WHERE TestNumber = @CurrTestId
						EXCEPT
						SELECT HierMemberId.ToString() HierMemberId, StartDate, EndDate, CAST(Attributes AS nvarchar(max)) Attributes, 'Expected' AS ExtraRowIn 
							FROM Hier.HierMemberVersion
							WHERE HierId = 255) A;
			UPDATE @Tests SET Success = IIF(@@ROWCOUNT > 0, 0, 1) WHERE TestId = @CurrTestId
		END;
	END;
CLOSE Tests; DEALLOCATE Tests;
SELECT * FROM @Tests ORDER BY TestId;
SELECT * FROM @TestUnmatchedRows ORDER BY TestId;
