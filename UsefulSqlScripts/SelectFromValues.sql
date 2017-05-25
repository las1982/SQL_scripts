with t1 as (
	select * from (values
	('a', 'a1'),
	('a', 'd1'),
	('a', 'd1'),
	('b', 'c2'),
	('b', 'c2'),
	('c', 'd1'),
	('c', 'd1'),
	('d', 'e1'),
	('e', 'd3'),
	('e', 'd4'))
	t1 (a, b)
	),
t2 as (
	select
		 a
		,b
		,count(a) over (partition by a) as c
	from (select distinct * from t1) t1
	)

--select * from t2
--where c = 1 and SUBSTRING(b, 1, 1) = 'd'

select distinct t1.a, t1.b
from t1
where
	SUBSTRING(b, 1, 1) = 'd' and
	(select count(distinct b) from t1 as t11 where t11.a = t1.a group by t11.a) = 1




with t1 as (
	select * from (values
	('a', 'a1'),
	('a', 'd1'),
	('a', 'd1'),
	('b', 'c2'),
	('b', 'c2'),
	('c', 'd1'),
	('c', 'd1'),
	('d', 'e1'),
	('e', 'd3'),
	('e', 'd4'))
	t1 (a, b)
	)

select
--	 count(distinct t1.a) as num,
	distinct t1.a, t1.b
from t1
where
	SUBSTRING(b, 1, 1) = 'd' and
	(select count(distinct b) from t1 as t11 where t11.a = t1.a group by t11.a) = 1




with t as (
 select * from (values
 ('a', 'a1'),
 ('a', 'd1'),
 ('a', 'd1'),
 ('b', 'c2'),
 ('b', 'c2'),
 ('c', 'd1'),
 ('c', 'd1'),
 ('d', 'e1'),
 ('e', 'd3'),
 ('e', 'd4'))
 t1 (a,b))

 select a,  b, count(1) as cnt
 from t
 join
 (
 select a as a2, count(distinct b) as cnt_2
 from t
 group by a
 having count(distinct b) = 1) t2 on t.a = t2.a2
   
 where b like '%d%'
 group by a,b
 having count(1) >1