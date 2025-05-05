/* Example 9:  Splitting strings. */
/* We need to read a delimited set of values in fixed positions.
	This is something we would want to use APPLY or a tally table to solve.
	With the introduction of STRING_SPLIT(), you might be tempted to use
	that function, but it does not return things in a guaranteed order
	and so we can't guarantee that we'll be able to pivot the data correctly. */

CREATE TABLE #StockItems
(
	StockItemID INT NOT NULL,
	StockItemName NVARCHAR(100) NOT NULL,
	SupplierID INT NOT NULL,
	ProductFeatures NVARCHAR(500) NOT NULL
);

-- Populating this with some data.  Say we got this info from a flat file or third-party API.
INSERT INTO #StockItems
(
	StockItemID,
	StockItemName,
	SupplierID,
	ProductFeatures
)
SELECT
	si.StockItemID,
	si.StockItemName,
	si.SupplierID,
	CONCAT(
		si.Brand, N',',
		si.Barcode, N',',
		si.TaxRate, N',',
		si.UnitPrice, N',',
		si.Size, N',',
		si.QuantityPerOuter, N','
	) AS ProductFeatures
FROM Warehouse.StockItems si;

-- This is what we have to work with.
-- Note that not all of the columns are filled in.
SELECT *
FROM #StockItems;

-- Option 0:  STRING_SPLIT()
-- This does split out into rows, but we can't pivot.
-- It would be a much better solution if we had key-value pairs instead.
SELECT *
FROM #StockItems si
	CROSS APPLY STRING_SPLIT(si.ProductFeatures, N',');

-- Option 1:  tally table.
-- Tally tables are a way of unpivoting strings, typically giving
-- us one character per row.  We can then merge results back together.
SET NOCOUNT ON;
CREATE TABLE #Tally
(
    N INT IDENTITY(0,1) NOT NULL PRIMARY KEY
);
GO
INSERT INTO #Tally DEFAULT VALUES
GO 10000
GO

WITH tally AS
(
	SELECT
		si.StockItemID,
		si.StockItemName,
		si.SupplierID,
		ROW_NUMBER() OVER (PARTITION BY si.StockItemID ORDER BY N) as rownum,
		SUBSTRING(',' + si.ProductFeatures + ',', N+1, 
					CHARINDEX(',', ',' + si.ProductFeatures + ',', N+1 ) - N-1) AS [Value]
	FROM
		#Tally tally
		CROSS JOIN #StockItems si
	WHERE
		N < LEN(',' + si.ProductFeatures + ',')
		AND SUBSTRING(',' + si.ProductFeatures + ',', N, 1) = ','

	/* Read this query bottom-up:
	0)  Take product features and add commas before and after.  This ensures we have consistent behavior
		and don't need to think about how to handle the first or last values.
	1)  Include numbers from the tally table where the current column in product features is a comma.
	2)  Include only enough numbers from the tally table to match the length of product features.  If the string
		is 50 characters long, we want the numbers 0-49 so we can assign a number to each character.
	3)  Form a Cartesian product of the tally/numbers table and stock items.
	4)  Starting from position N+1 (because N is a comma), get everything up to but not including the next comma.
	5)  Number each of these collections of data so we can sort them out appropriately.
	6)  Include the other columns we need.
	*/
)
SELECT
	t.StockItemID,
	t.StockItemName,
	t.SupplierId,
	MAX(CASE WHEN t.rownum = 1 THEN t.[Value] END) as [Brand],
	MAX(CASE WHEN t.rownum = 2 THEN t.[Value] END) as [Barcode],
	MAX(CASE WHEN t.rownum = 3 THEN t.[Value] END) as [TaxRate],
	MAX(CASE WHEN t.rownum = 4 THEN t.[Value] END) as [UnitPrice],
	MAX(CASE WHEN t.rownum = 5 THEN t.[Value] END) as [Size],
	MAX(CASE WHEN t.rownum = 6 THEN t.[Value] END) as [QuantityPerOuter]
FROM tally t
GROUP BY
	t.StockItemID,
	t.StockItemName,
	t.SupplierId
ORDER BY
	StockItemID;

-- Option 2:  APPLY
-- This is a little complex, so let's take step by step.
-- First, note that not every row has every value filled in.
SELECT * FROM #StockItems;

-- It looks like we have enough commas but just in case, let's add 6 commas to the end.
-- This would be important if we see data like "Val1,Val2,Val3" and we expect six fields in there.
SELECT
	*
FROM #StockItems si
	CROSS APPLY (SELECT ProductFeatures=si.ProductFeatures + ',,,,,,') l1;

-- Next, we want to get the locations of the first 6 commas in each row--these are the demarcation
-- lines for the six attributes we care about.
SELECT
	*
FROM #StockItems si
	CROSS APPLY (SELECT ProductFeatures = si.ProductFeatures + ',,,,,,') l1
	CROSS APPLY (SELECT pos1 = CHARINDEX(',', l1.ProductFeatures)) p1
	CROSS APPLY (SELECT pos2 = CHARINDEX(',', l1.ProductFeatures, p1.pos1 + 1)) p2
	CROSS APPLY (SELECT pos3 = CHARINDEX(',', l1.ProductFeatures, p2.pos2 + 1)) p3
	CROSS APPLY (SELECT pos4 = CHARINDEX(',', l1.ProductFeatures, p3.pos3 + 1)) p4
	CROSS APPLY (SELECT pos5 = CHARINDEX(',', l1.ProductFeatures, p4.pos4 + 1)) p5
	CROSS APPLY (SELECT pos6 = CHARINDEX(',', l1.ProductFeatures, p5.pos5 + 1)) p6;
-- Pos1, pos2, et al represent the string positions of **commas**.
-- What we care about are the non-comma values **between** these positions.
-- We can easily calculate this with one more CROSS APPLY operation.

-- Here's the final product.
SELECT
	si.StockItemID,
	si.StockItemName,
	si.SupplierID,
	features.Brand,
	features.Barcode,
	features.TaxRate,
	features.UnitPrice,
	features.Size,
	features.QuantityPerOuter
FROM #StockItems si
	CROSS APPLY (SELECT ProductFeatures = si.ProductFeatures + ',,,,,,') l1
	CROSS APPLY (SELECT pos1 = CHARINDEX(',', l1.ProductFeatures)) p1
	CROSS APPLY (SELECT pos2 = CHARINDEX(',', l1.ProductFeatures, pos1 + 1)) p2
	CROSS APPLY (SELECT pos3 = CHARINDEX(',', l1.ProductFeatures, pos2 + 1)) p3
	CROSS APPLY (SELECT pos4 = CHARINDEX(',', l1.ProductFeatures, pos3 + 1)) p4
	CROSS APPLY (SELECT pos5 = CHARINDEX(',', l1.ProductFeatures, pos4 + 1)) p5
	CROSS APPLY (SELECT pos6 = CHARINDEX(',', l1.ProductFeatures, pos5 + 1)) p6
	CROSS APPLY
	(
		SELECT
			Brand = SUBSTRING(l1.ProductFeatures, 1, pos1 - 1),
			Barcode = SUBSTRING(l1.ProductFeatures, pos1 + 1, pos2 - pos1 - 1),
			TaxRate = SUBSTRING(l1.ProductFeatures, pos2 + 1, pos3 - pos2 - 1),
			UnitPrice = SUBSTRING(l1.ProductFeatures, pos3 + 1, pos4 - pos3 - 1),
			Size = SUBSTRING(l1.ProductFeatures, pos4 + 1, pos5 - pos4 - 1),
			QuantityPerOuter = SUBSTRING(l1.ProductFeatures, pos5 + 1, pos6 - pos5 - 1)
	) features;