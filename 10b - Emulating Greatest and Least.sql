/* Example 10b - Emulating GREATEST and LEAST */
/* GREATEST() and LEAST() are two interesting SQL functions.
	At present, they are not available on SQL Server on-premises, but
	they are just being introduced (as of December 2020) to Azure SQL Database.
	If you don't have the functions available, we can use APPLY to do the same! */

-- Assuming we are using the same data set, this doesn't need APPLY.
SELECT
	MAX(v.Val) AS LargestNumber,
	MIN(v.Val) AS SmallestNumber
FROM (VALUES(1), (2), (3), (4), (5)) v(Val);

-- More often, we'll want to use a pivoted data set like this.
DROP TABLE IF EXISTS #Sales;
CREATE TABLE #Sales
(
    Product VARCHAR(50),
    Quantity2013 INT,
    Quantity2014 INT,
    Quantity2015 INT,
    Revenue2013 INT,
    Revenue2014 INT,
    Revenue2015 INT
);
 
INSERT INTO #Sales
(
	Product,
	Quantity2013,
	Quantity2014,
	Quantity2015,
	Revenue2013,
	Revenue2014,
	Revenue2015
) VALUES
('P1', 200, 230, 255, 1995, 2448, 3006),
('P2', 126, 129, 127, 448, 463, 451),
('P3', 600, 16000, 38880, 750, 24000, 60000),
('P4', 390, 380, 370, 3000, 2900, 2800),
('P5', 125, 125, 125, 17008, 17008, 17008);

SELECT
	Product,
	MAX(qty.Quantity) AS MaxQuantity,
	MIN(qty.Quantity) AS MinQuantity,
	MAX(rev.Revenue) AS MaxRevenue,
	MIN(rev.Revenue) AS MinRevenue
FROM #Sales
	CROSS APPLY
	(
		SELECT Quantity2013
		UNION ALL
		SELECT Quantity2014
		UNION ALL
		SELECT Quantity2015
	) qty(Quantity)
	CROSS APPLY
	(
		SELECT Revenue2013
		UNION ALL
		SELECT Revenue2014
		UNION ALL
		SELECT Revenue2015
	) rev(Revenue)
GROUP BY
	Product;