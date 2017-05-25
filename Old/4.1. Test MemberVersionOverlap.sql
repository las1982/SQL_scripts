SET NOCOUNT ON
GO
DECLARE @Members TABLE (HierId tinyint, HierMemberId sys.hierarchyid, Name varchar(128), FullName xml);
DECLARE @MemberVersions TABLE (
	HierId tinyint,
	HierMemberId sys.hierarchyid, 
	StartDate date NOT NULL,
	EndDate date NOT NULL,
	IsCurrent bit,
	Attributes xml NULL);
DECLARE @MapVersions TABLE (
	StartDate date,
	EndDate date,
	IsCurrent bit,
	SrcHierId tinyint,
	SrcHierMemberId sys.hierarchyid,
	DstHierId tinyint,
	DstHierMemberId sys.hierarchyid);
INSERT INTO @Members (HierId, HierMemberId, Name, FullName) VALUES
	('1',	'/11/',		'.11.',		'<M Name=".11."		Level="1"/>'),
	('1',	'/11/1/',	'.11.1.',	'<M Name=".11.1."	Level="2">	<M Name=".11."	Level="1"/></M>'),
	('1',	'/11/1/1/',	'.11.1.1.', '<M Name=".11.1.1."	Level="3">	<M Name=".11.1." Level="2">	<M Name=".11." Level="1" /></M></M>'),
	('1',	'/12/',		'.12.',		'<M Name=".12."		Level="1"/>'),
	('6',	'/12/',		'.12.',		'<M Name=".12."		Level="1"/>'),
	('6',	'/12/1/',	'.12.1.',	'<M Name=".12.1."	Level="2">	<M Name=".12."	Level="1"/></M>'),
	('6',	'/12/2/',	'.12.2.',	'<M Name=".12.2."	Level="2">	<M Name=".12."	Level="1"/></M>'),
	('6',	'/12/3/',	'.12.3.',	'<M Name=".12.3."	Level="2">	<M Name=".12."	Level="1"/></M>'),
	('6',	'/12/4/',	'.12.4.',	'<M Name=".12.4."	Level="2">	<M Name=".12."	Level="1"/></M>'),
	('6',	'/12/5/',	'.12.5.',	'<M Name=".12.5."	Level="2">	<M Name=".12."	Level="1"/></M>'),
	('6',	'/12/6/',	'.12.6.',	'<M Name=".12.6."	Level="2">	<M Name=".12."	Level="1"/></M>'),
	('6',	'/12/7/',	'.12.7.',	'<M Name=".12.7."	Level="2">	<M Name=".12."	Level="1"/></M>'),
	('6',	'/12/8/',	'.12.8.',	'<M Name=".12.8."	Level="2">	<M Name=".12."	Level="1"/></M>'),
	('6',	'/12/9/',	'.12.9.',	'<M Name=".12.9."	Level="2">	<M Name=".12."	Level="1"/></M>'),
	('6',	'/12/10/',	'.12.10.',	'<M Name=".12.10."	Level="2">	<M Name=".12."	Level="1"/></M>'),
	('6',	'/12/14/',	'.12.14.',	'<M Name=".12.14."	Level="2">	<M Name=".12."	Level="1"/></M>');

INSERT INTO @MemberVersions (HierId, HierMemberId, StartDate, EndDate, IsCurrent, Attributes) VALUES
('1',	'/11/',		'20150101',	'20150211',	'0',	NULL),
('1',	'/11/1/',	'20150102',	'20150128',	'0',	NULL),
('1',	'/11/1/',	'20150130',	'20150205',	'0',	NULL),
('1',	'/11/1/1/',	'20150102',	'20150105',	'0',	NULL),
('1',	'/11/1/1/',	'20150109',	'20150128',	'0',	NULL),
('1',	'/11/1/1/',	'20150131',	'20150204',	'0',	NULL),
('1',	'/12/',		'20150101',	'20150111',	'0',	NULL),
('1',	'/12/',		'20150115',	'20150115',	'0',	NULL),
('1',	'/12/',		'20150118',	'20150123',	'0',	NULL),
('1',	'/12/',		'20150129',	'20150207',	'0',	NULL),
('1',	'/12/',		'20150209',	'20150212',	'0',	NULL),
('6',	'/12/1/',	'20150103',	'20150113',	'0',	NULL),
('6',	'/12/2/',	'20150104',	'20150116',	'0',	NULL),
('6',	'/12/2/',	'20150121',	'20150204',	'0',	NULL),
('6',	'/12/3/',	'20150104',	'20150119',	'0',	NULL),
('6',	'/12/4/',	'20150110',	'20150121',	'0',	NULL),
('6',	'/12/5/',	'20150114',	'20150117',	'0',	NULL),
('6',	'/12/6/',	'20150116',	'20150122',	'0',	NULL),
('6',	'/12/6/',	'20150128',	'20150202',	'0',	NULL),
('6',	'/12/7/',	'20150118',	'20150126',	'0',	NULL),
('6',	'/12/8/',	'20150116',	'20150131',	'0',	NULL),
('6',	'/12/9/',	'20150109',	'20150120',	'0',	NULL),
('6',	'/12/9/',	'20150126',	'20150203',	'0',	NULL),
('6',	'/12/10/',	'20150123',	'20150201',	'0',	NULL),
('6',	'/12/14/',	'20150127',	'20150131',	'0',	NULL),
('6',	'/12/14/',	'20150203',	'20150207',	'0',	NULL);

INSERT INTO @MapVersions (StartDate, EndDate, IsCurrent, SrcHierId, SrcHierMemberId, DstHierId, DstHierMemberId) VALUES
('20150106',	'20150117',	'0',	'1',	'/11/',		'6',	'/12/3/'),
('20150118',	'20150201',	'0',	'1',	'/11/',		'6',	'/12/8/'),
('20150202',	'20150211',	'0',	'1',	'/11/',		'6',	'/12/14/'),
('20150101',	'20150107',	'0',	'1',	'/11/1/',	'6',	'/12/1/'),
('20150108',	'20150115',	'0',	'1',	'/11/1/',	'6',	'/12/2/'),
('20150116',	'20150125',	'0',	'1',	'/11/1/',	'6',	'/12/6/'),
('20150129',	'20150205',	'0',	'1',	'/11/1/',	'6',	'/12/9/'),
('20150106',	'20150113',	'0',	'1',	'/11/1/1/',	'6',	'/12/4/'),
('20150114',	'20150119',	'0',	'1',	'/11/1/1/',	'6',	'/12/5/'),
('20150120',	'20150130',	'0',	'1',	'/11/1/1/',	'6',	'/12/7/'),
('20150131',	'20150203',	'0',	'1',	'/11/1/1/',	'6',	'/12/10/'),
('20150104',	'20150106',	'0',	'1',	'/12/',		'6',	'/12/1/'),
('20150110',	'20150115',	'0',	'1',	'/12/',		'6',	'/12/2/'),
('20150116',	'20150125',	'0',	'1',	'/12/',		'6',	'/12/6/'),
('20150131',	'20150205',	'0',	'1',	'/12/',		'6',	'/12/9/');

DELETE FROM Hier.HierMemberVersion
	WHERE HierId IN (1, 6) AND (HierMemberId.IsDescendantOf('/11/') = 1 OR HierMemberId.IsDescendantOf('/12/') = 1);
DELETE FROM Hier.HierMemberMappingVersion 
	WHERE SrcHierId = 1 AND (SrcHierMemberId.IsDescendantOf('/11/') = 1 OR SrcHierMemberId.IsDescendantOf('/12/') = 1);
DELETE FROM Hier.HierMember 
	WHERE HierId IN (1, 6) AND (HierMemberId.IsDescendantOf('/11/') = 1 OR HierMemberId.IsDescendantOf('/12/') = 1);


--select * from @Members
--select * from @MemberVersions
--select * from @MapVersions

INSERT INTO Hier.HierMember (HierId, HierMemberId, Name, FullName)
	SELECT M.HierId, M.HierMemberId, M.Name, M.FullName FROM @Members M;

INSERT INTO Hier.HierMemberVersion(HierId, HierMemberId, StartDate, EndDate, IsCurrent, Attributes)
	SELECT M.HierId, M.HierMemberId, M.StartDate, M.EndDate, M.IsCurrent, M.Attributes FROM @MemberVersions M

INSERT INTO Hier.HierMemberMappingVersion(StartDate, EndDate, IsCurrent, SrcHierId, SrcHierMemberId, DstHierId, DstHierMemberId)
	SELECT M.StartDate, M.EndDate, M.IsCurrent, M.SrcHierId, M.SrcHierMemberId, M.DstHierId, M.DstHierMemberId FROM @MapVersions M
GO

use [CSRMAR_DataMart]
select * into #Mem from (
SELECT * FROM Hier.HierMember
	WHERE HierId IN (1, 6) AND (HierMemberId.IsDescendantOf('/11/') = 1 OR HierMemberId.IsDescendantOf('/12/') = 1 OR HierMemberId = '/')
--	ORDER BY HierId, HierMemberId
) as #Mem
select * into #MemVer from (
SELECT *, HierMemberId.ToString() HierMemberId_Str FROM Hier.HierMemberVersion
	WHERE HierId IN (1, 6) AND (HierMemberId.IsDescendantOf('/11/') = 1 OR HierMemberId.IsDescendantOf('/12/') = 1 OR HierMemberId = '/')
--	ORDER BY HierId, HierMemberId, StartDate
) as #MemVer
select * into #MapVer from (
SELECT *, SrcHierMemberId.ToString() SrcHierMemberId_Str, DstHierMemberId.ToString() DstHierMemberId_Str FROM Hier.HierMemberMappingVersion
	WHERE SrcHierId IN (1, 6) AND (SrcHierMemberId.IsDescendantOf('/11/') = 1 OR SrcHierMemberId.IsDescendantOf('/12/') = 1 OR SrcHierMemberId = '/')
--	ORDER BY SrcHierId, SrcHierMemberId, DstHierId, StartDate
) as #MapVer

--select * from #Mem
--select * from #MemVer
--select * from #MapVer

declare
	 @HierId tinyint = 1
	,@HierMemberId sys.hierarchyid = '/11/1/1/'
	,@MemStartDate date
	,@MemEndDate date
	,@DstHierId tinyint
	,@DstHierMemberId sys.hierarchyid
	,@DstMemStartDate date
	,@DstMemEndDate date
	,@MapStartDate date
	,@MapEndDate date
	,@EfMapStartDate date
	,@EfMapEndDate date
	,@MemLifeDate date

drop table #MapEf
create table #MapEf (HierId tinyint, HierMemberId sys.hierarchyid, DstHierId tinyint, MemLifeDate date)

declare MemVer_cursor cursor --start in member
for select StartDate, EndDate from #MemVer where HierId = @HierId and HierMemberId = @HierMemberId order by StartDate
open MemVer_cursor
fetch next from MemVer_cursor
into @MemStartDate, @MemEndDate
while @@fetch_status =  0
	begin
		declare DstHier_cursor cursor --start in DstHier for member
		for select distinct DstHierId from #MapVer where SrcHierId = @HierId and SrcHierMemberId = @HierMemberId order by DstHierId
		open DstHier_cursor
		fetch next from DstHier_cursor
		into @DstHierId
		while @@fetch_status =  0
			begin
				set @MemLifeDate = @MemStartDate
				while @MemLifeDate <= @MemEndDate
					begin
						insert into #MapEf values (@HierId, @HierMemberId, @DstHierId, @MemLifeDate)
						set @MemLifeDate = DATEADD(dd, 1, @MemLifeDate)
					end
			fetch next from DstHier_cursor
			into @DstHierId
			end
		close DstHier_cursor
		deallocate DstHier_cursor
		fetch next from MemVer_cursor
		into @MemStartDate, @MemEndDate
	end
close MemVer_cursor
deallocate MemVer_cursor

--select * from #MapEf



















/*TEST 1
select *, HierMemberId.ToString() from Hier.HierMemberVersion WHERE HierId = 1 AND HierMemberId.IsDescendantOf('/10/') = 1 order by HierId, HierMemberId, StartDate;
ENABLE TRIGGER ALL ON Hier.HierMemberVersion;
GO
INSERT INTO Hier.HierMemberVersion(HierId, HierMemberId, StartDate, EndDate, IsCurrent, Attributes) VALUES
	(1, '/10/1/2/1/', '20001201',	'20020101',	0, NULL)
GO
select *, HierMemberId.ToString() from Hier.HierMemberVersion WHERE HierId = 1 AND HierMemberId.IsDescendantOf('/10/') = 1 order by HierMemberId, StartDate;
GO
*/

/*TEST 2
DISABLE TRIGGER ALL ON Hier.HierMemberVersion;
INSERT INTO Hier.HierMemberVersion(HierId, HierMemberId, StartDate, EndDate, IsCurrent, Attributes) VALUES
	(1, '/10/1/2/1/', '20001201',	'20010601',	0, NULL)
GO
select *, HierMemberId.ToString() from Hier.HierMemberVersion WHERE HierId = 1 AND HierMemberId.IsDescendantOf('/10/') = 1 order by HierId, HierMemberId, StartDate;
ENABLE TRIGGER ALL ON Hier.HierMemberVersion;
GO
UPDATE Hier.HierMemberVersion SET EndDate = '20010601' WHERE HierId = 1 AND HierMemberId = '/10/1/2/'
GO
select *, HierMemberId.ToString() from Hier.HierMemberVersion WHERE HierId = 1 AND HierMemberId.IsDescendantOf('/10/') = 1 order by HierMemberId, StartDate;
GO
*/

/*TEST 3
DISABLE TRIGGER ALL ON Hier.HierMemberVersion;
INSERT INTO Hier.HierMemberVersion(HierId, HierMemberId, StartDate, EndDate, IsCurrent, Attributes) VALUES
	(1, '/10/1/2/1/', '20001201',	'20010601',	0, NULL)
GO
select *, HierMemberId.ToString() from Hier.HierMemberVersion WHERE HierId = 1 AND HierMemberId.IsDescendantOf('/10/') = 1 order by HierId, HierMemberId, StartDate;
ENABLE TRIGGER ALL ON Hier.HierMemberVersion;
GO
DELETE Hier.HierMemberVersion WHERE HierId = 1 AND HierMemberId = '/10/1/' AND StartDate = '20010201'
GO
select *, HierMemberId.ToString() from Hier.HierMemberVersion WHERE HierId = 1 AND HierMemberId.IsDescendantOf('/10/') = 1 order by HierMemberId, StartDate;
GO
*/