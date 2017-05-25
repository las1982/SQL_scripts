use [CSRMAR_DataMart]
SET NOCOUNT ON
IF OBJECT_ID('tempdb..#Mem') IS NOT NULL DROP TABLE #Mem;
IF OBJECT_ID('tempdb..#MemVer') IS NOT NULL DROP TABLE #MemVer;
IF OBJECT_ID('tempdb..#MapVer') IS NOT NULL DROP TABLE #MapVer;
IF OBJECT_ID('tempdb..#MapEf') IS NOT NULL DROP TABLE #MapEf;

--Creating temp tables from test data

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
--drop table #MapEf

--creating temp table MapEf: for each SrcHierId, SrcHierMemberId, SrcMemLifeDate exists many DstHierId

create table #MapEf (SrcHierId tinyint, SrcHierMemberId sys.hierarchyid, SrcMemLifeDate date, DstHierId tinyint, DstHierMemberId sys.hierarchyid)
declare
	 @SrcHierId tinyint = 1
	,@SrcHierMemberId sys.hierarchyid = '/12/'
	,@SrcMemStartDate date
	,@SrcMemEndDate date
	,@DstHierId tinyint
	,@DstHierMemberId sys.hierarchyid
	,@SrcMemLifeDate date
	,@sql nvarchar(max)
	,@SrcParentHierMemberId sys.hierarchyid

declare Hier_cursor cursor --start in hier
for select distinct HierId from Hier.Hier order by 1
open Hier_cursor
fetch next from Hier_cursor
into @DstHierId
while @@fetch_status =  0
begin
	declare MemVer_cursor cursor --start in member version
	for select StartDate, EndDate from #MemVer where HierId = @SrcHierId and HierMemberId = @SrcHierMemberId order by StartDate
	open MemVer_cursor
	fetch next from MemVer_cursor
	into @SrcMemStartDate, @SrcMemEndDate
	while @@fetch_status =  0
	begin
		set @SrcMemLifeDate = @SrcMemStartDate
		while @SrcMemLifeDate <= @SrcMemEndDate
			begin
				insert into #MapEf values (@SrcHierId, @SrcHierMemberId, @SrcMemLifeDate, @DstHierId, null)
				set @SrcMemLifeDate = DATEADD(dd, 1, @SrcMemLifeDate)
			end
		fetch next from MemVer_cursor
		into @SrcMemStartDate, @SrcMemEndDate
	end
	close MemVer_cursor
	deallocate MemVer_cursor
	fetch next from Hier_cursor
	into @DstHierId
end
close Hier_cursor
deallocate Hier_cursor

--then fill DstHierMemberId column. If mapping for SrcMember exists and DstMember exists for date, then fill the cell, then continue filling cells (witch is null) by parent's mapping.

set @SrcParentHierMemberId = @SrcHierMemberId
while @SrcParentHierMemberId <> '/'
begin
	declare MapEf_cursor cursor --start in MapEf
	for select SrcHierId, SrcHierMemberId, SrcMemLifeDate, DstHierId from #MapEf where DstHierMemberId is null --there are all nulls at first run through table, after filling cells we need nulls only
	open MapEf_cursor
	fetch next from MapEf_cursor
	into @SrcHierId, @SrcHierMemberId, @SrcMemLifeDate, @DstHierId
	while @@fetch_status =  0
	begin
		set @DstHierMemberId = (select DstHierMemberId from #MapVer where SrcHierId = @SrcHierId and SrcHierMemberId = @SrcParentHierMemberId and DstHierId = @DstHierId and @SrcMemLifeDate between StartDate and EndDate)
		if len(@DstHierMemberId.ToString()) > 0
		begin
			if (select count(1) from #MemVer where HierId = @DstHierId and HierMemberId = @DstHierMemberId and @SrcMemLifeDate between StartDate and EndDate) = 1
			begin
				set @sql = 'update #MapEf set DstHierMemberId = ''' + @DstHierMemberId.ToString() + ''' where SrcHierId = ' + cast(@SrcHierId as nvarchar(max)) + ' and SrcHierMemberId = ''' + @SrcHierMemberId.ToString() + ''' and SrcMemLifeDate = ''' + cast(@SrcMemLifeDate as nvarchar(max)) + ''' and DstHierId = ' + cast(@DstHierId as nvarchar(max))
				exec sp_executesql @sql
			end
		end
		fetch next from MapEf_cursor
		into @SrcHierId, @SrcHierMemberId, @SrcMemLifeDate, @DstHierId
	end
	close MapEf_cursor
	deallocate MapEf_cursor
	set @SrcParentHierMemberId = @SrcParentHierMemberId.GetAncestor(1)
end

--then clean up the table from nulls in DstHierMemberId column

delete from #MapEf where DstHierMemberId is null

--select * from #MapEf
select
	 SrcHierId
	,SrcHierMemberId.ToString() as SrcHierMemberId
	,SrcMemLifeDate
	,DstHierId
	,DstHierMemberId.ToString() as DstHierMemberId
from #MapEf