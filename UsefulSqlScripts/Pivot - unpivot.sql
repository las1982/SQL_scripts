CREATE TABLE #Customer_Order
(
	Customer VARCHAR(10),
	MONTH INTEGER, 
	YEAR INTEGER, 
	Purchase_Made INTEGER
)    

 INSERT INTO #Customer_Order VALUES('Bhushan',1,2012, 11)  
 INSERT INTO #Customer_Order VALUES('Bhushan',2,2012, 8)  
 INSERT INTO #Customer_Order VALUES('Bhushan',1,2012, 10)  
 INSERT INTO #Customer_Order VALUES('Bhushan',4,2012, 2)  
 INSERT INTO #Customer_Order VALUES('Bhushan',5,2012, 7)  
 INSERT INTO #Customer_Order VALUES('Bhushan',2,2012, 1)  
 INSERT INTO #Customer_Order VALUES('Bhushan',1,2012, 4)  
 INSERT INTO #Customer_Order VALUES('Bhushan',6,2012, 5)  
 INSERT INTO #Customer_Order VALUES('Bhushan',8,2012, 8 )  
 INSERT INTO #Customer_Order VALUES('Bhushan',3,2013, 5)  
 INSERT INTO #Customer_Order VALUES('Bhushan',5,2013, 7)  
 INSERT INTO #Customer_Order VALUES('Bhushan',12,2013, 5)  
 INSERT INTO #Customer_Order VALUES('Bhushan',11,2013, 4)  
 INSERT INTO #Customer_Order VALUES('Bhushan',1,2013, 7)  
 INSERT INTO #Customer_Order VALUES('Bhushan',5,2013, 5)  
 INSERT INTO #Customer_Order VALUES('Ash',2,2012, 6)  
 INSERT INTO #Customer_Order VALUES('Ash',4,2012, 7)  
 INSERT INTO #Customer_Order VALUES('Ash',2,2012, 4)  
 INSERT INTO #Customer_Order VALUES('Ash',3,2012, 5)  
 INSERT INTO #Customer_Order VALUES('Ash',5,2012, 7)  
 INSERT INTO #Customer_Order VALUES('Ash',12,2012, 2)  
 INSERT INTO #Customer_Order VALUES('Ash',11,2012, 4)  
 INSERT INTO #Customer_Order VALUES('Ash',1,2012, 9)  
 INSERT INTO #Customer_Order VALUES('Ash',5,2012, 4)  
 INSERT INTO #Customer_Order VALUES('Ash',3,2012, 5)  
 INSERT INTO #Customer_Order VALUES('Ash',4,2013, 7)  
 INSERT INTO #Customer_Order VALUES('Ash',1,2013, 1)  
 INSERT INTO #Customer_Order VALUES('Ash',4,2013, 4)  
 INSERT INTO #Customer_Order VALUES('Ash',2,2013, 9)  
 INSERT INTO #Customer_Order VALUES('Ash',5,2013, 4)    
 INSERT INTO #Customer_Order VALUES('Hershal',1,2012, 5)  
 INSERT INTO #Customer_Order VALUES('Hershal',3,2012, 6)  
 INSERT INTO #Customer_Order VALUES('Hershal',5,2012, 8 )  
 INSERT INTO #Customer_Order VALUES('Hershal',12,2012, 3)  
 INSERT INTO #Customer_Order VALUES('Hershal',9,2012, 5)  
 INSERT INTO #Customer_Order VALUES('Hershal',5,2012, 3)  
 INSERT INTO #Customer_Order VALUES('Hershal',1,2012, 5)  
 INSERT INTO #Customer_Order VALUES('Hershal',4,2012, 3)  
 INSERT INTO #Customer_Order VALUES('Hershal',3,2012, 9)  
 INSERT INTO #Customer_Order VALUES('Hershal',3,2013, 5)  
 INSERT INTO #Customer_Order VALUES('Hershal',5,2013, 7)  
 INSERT INTO #Customer_Order VALUES('Hershal',12,2013, 1)  
 INSERT INTO #Customer_Order VALUES('Hershal',11,2013, 4)  
 INSERT INTO #Customer_Order VALUES('Hershal',1,2013, 9)  
 INSERT INTO #Customer_Order VALUES('Hershal',5,2013, 4) 


 select * from #Customer_Order


 
 select * into #Customer_Order_1 from (
 SELECT		*  
FROM
	(SELECT	Customer,
			CAST([YEAR] As VARCHAR(4)) + ' ' + cast([MONTH] as varchar(2)) As MONTHS,  
			Purchase_Made  
	 FROM
			#Customer_Order
	 )P
		PIVOT
		(  
		SUM(Purchase_Made) FOR MONTHS IN ([2012 4], [2012 5], [2012 6], [2012 7], [2012 8])
		)AS PVT  ) as #Customer_Order_1

 select * from #Customer_Order_1




 SELECT *
FROM
(select * from #Customer_Order_1) stu
UNPIVOT
(val FOR mon IN ([2012 4], [2012 5], [2012 6], [2012 7], [2012 8])
) AS mrks





DROP TABLE #Customer_Order
DROP TABLE #Customer_Order_1

