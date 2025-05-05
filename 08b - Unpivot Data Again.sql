/* Example 8b:  Unpivoting data sets. */
/* We can use the APPLY operator to unpivot a broad data set. */

-- Suppose we have some report of product sales per year.
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

-- We want to load this data into SQL Server, but we'd like to normalize it first.
-- One method we can use to do this is the CASE statement.
SELECT
    s.Product,
    y.[Year],
    CASE
        WHEN y.Year = 2013 THEN Quantity2013
        WHEN y.Year = 2014 THEN Quantity2014
        WHEN y.Year = 2015 THEN Quantity2015
    END AS Quantity,
    CASE
        WHEN y.Year = 2013 THEN Revenue2013
        WHEN y.Year = 2014 THEN Revenue2014
        WHEN y.Year = 2015 THEN Revenue2015
    END AS [Revenue]
FROM #Sales s
    CROSS JOIN (VALUES(2013),(2014),(2015)) y([Year]);

-- We can also use APPLY.
SELECT
    s.Product,
    y.[Year],
    y.Quantity,
    y.[Revenue]
FROM #Sales s
    CROSS APPLY
	(	VALUES
        (2013, [Quantity2013], [Revenue2013]),
        (2014, [Quantity2014], [Revenue2014]),
        (2015, [Quantity2015], [Revenue2015])
    ) y([Year], Quantity, [Revenue]);