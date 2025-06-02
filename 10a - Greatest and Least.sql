/* Example 10a - GREATEST and LEAST in SQL Server 2022 */
/* GREATEST() and LEAST() are two interesting SQL functions.
	They became available on-premises in SQL Server 2022 and are also
	available in Azure SQL Database. */

-- Be sure to run this on a version of SQL server which supports these functions!
SELECT
	GREATEST(1, 2, 3, 4, 5) AS LargestNumber,
	LEAST(1, 2, 3, 4, 5) AS SmallestNumber;

-- This also works per-row.
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
	GREATEST(Quantity2013, Quantity2014, Quantity2015) AS MaxQuantity,
	GREATEST(Revenue2013, Revenue2014, Revenue2015) AS MaxRevenue
FROM #Sales;