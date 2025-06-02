/* Example 10b - Emulating GREATEST and LEAST */
/* GREATEST() and LEAST() are two interesting SQL functions.
	They became available on-premises in SQL Server 2022 and are also
	available in Azure SQL Database.
	If you don't have the functions available, we can use APPLY to do the same! */

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


-- And yes, you can use the VALUES() clause here as well.
SELECT
	Product,
	MAX(qty.Quantity) AS MaxQuantity,
	MIN(qty.Quantity) AS MinQuantity,
	MAX(rev.Revenue) AS MaxRevenue,
	MIN(rev.Revenue) AS MinRevenue
FROM #Sales
	CROSS APPLY
	(
		VALUES
			(Quantity2013),
			(Quantity2014),
			(Quantity2015)
	) qty(Quantity)
	CROSS APPLY
	(
		VALUES
			(Revenue2013),
			(Revenue2014),
			(Revenue2015)
	) rev(Revenue)
GROUP BY
	Product;