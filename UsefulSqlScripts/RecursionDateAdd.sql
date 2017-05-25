USE [CSRMAR_DataMart];
WITH
t1 as (
	select E.SrcHierId, E.SrcHierMemberId, E.DstHierId, E.DstHierMemberId, e.StartDate, e.EndDate
	from 
		Hier.HierMemberMappingEffectiveVersion E
	WHERE
		(E.SrcHierId = 1 AND (E.SrcHierMemberId.IsDescendantOf('/11/') = 1 OR E.SrcHierMemberId.IsDescendantOf('/12/') = 1 OR E.SrcHierMemberId = '/')) OR
		(E.DstHierId = 1 AND (E.DstHierMemberId.IsDescendantOf('/11/') = 1 OR E.DstHierMemberId.IsDescendantOf('/12/') = 1 OR E.DstHierMemberId = '/'))
	),
t2 as (
	select t1.StartDate d1, t1.EndDate d2, dt = t1.StartDate
	from t1
	union all
	select d1, d2, DATEADD(day, 1, dt) from t2
	where t2.dt < t2.d2
	)

select E.SrcHierId, E.SrcHierMemberId, E.DstHierId, E.DstHierMemberId, t2.dt
from t1 as E left join t2 on t2.d1 = e.StartDate  and t2.d2 = e.EndDate
option (maxrecursion 32767);