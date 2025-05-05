/* Example 3:  pre-aggregating data. */
/* What we want:  find the number of invoice lines for a particular type of slipper. */
-- Create an index if we don't have one already
-- CREATE INDEX [IX_InvoiceLinesSmall_StockItemID] ON Sales.InvoiceLinesSmall (StockItemID);

-- The "normal" way to write this query.
SELECT
	si.StockItemName,
	s.SupplierName,
	pt.PackageTypeName,
	COUNT(*) AS NumberOfInvoiceLines
FROM Warehouse.StockItems si
	INNER JOIN Purchasing.Suppliers s
		ON si.SupplierID = s.SupplierID
	INNER JOIN Warehouse.PackageTypes pt
		ON si.UnitPackageID = pt.PackageTypeID
	INNER JOIN Sales.InvoiceLinesSmall il
		ON si.StockItemID = il.StockItemID
WHERE
	si.StockItemName = 'Plush shark slippers (Gray) XL'
GROUP BY
	si.StockItemName,
	s.SupplierName,
	pt.PackageTypeName;

-- The APPLY Operator way to write this query.
SELECT
	si.StockItemName,
	s.SupplierName,
	pt.PackageTypeName,
	i.NumberOfInvoiceLines
FROM Warehouse.StockItems si
	INNER JOIN Purchasing.Suppliers s
		ON si.SupplierID = s.SupplierID
	INNER JOIN Warehouse.PackageTypes pt
		ON si.UnitPackageID = pt.PackageTypeID
	CROSS APPLY
	(
		SELECT
			COUNT(*) AS NumberOfInvoiceLines
		FROM Sales.InvoiceLinesSmall il
		WHERE
			il.StockItemID = si.StockItemID
	) i
WHERE
	si.StockItemName = 'Plush shark slippers (Gray) XL';


-- Performance is the same as if you used a correlated subquery.
SELECT
	si.StockItemName,
	s.SupplierName,
	pt.PackageTypeName,
	(
		SELECT
			COUNT(*) AS NumberOfInvoiceLines
		FROM Sales.InvoiceLinesSmall il
		WHERE
			il.StockItemID = si.StockItemID
	)
FROM Warehouse.StockItems si
	INNER JOIN Purchasing.Suppliers s
		ON si.SupplierID = s.SupplierID
	INNER JOIN Warehouse.PackageTypes pt
		ON si.UnitPackageID = pt.PackageTypeID
WHERE
	si.StockItemName = 'Plush shark slippers (Gray) XL';

/* Pull in more stock items to see how these perform. */
-- The "normal" way to write this query.
SELECT
	si.StockItemName,
	s.SupplierName,
	pt.PackageTypeName,
	COUNT(*) AS NumberOfInvoiceLines
FROM Warehouse.StockItems si
	INNER JOIN Purchasing.Suppliers s
		ON si.SupplierID = s.SupplierID
	INNER JOIN Warehouse.PackageTypes pt
		ON si.UnitPackageID = pt.PackageTypeID
	INNER JOIN Sales.InvoiceLinesSmall il
		ON si.StockItemID = il.StockItemID
WHERE
	si.StockItemName LIKE '%slippers%'
GROUP BY
	si.StockItemName,
	s.SupplierName,
	pt.PackageTypeName;

-- The APPLY Operator way to write this query.
SELECT
	si.StockItemName,
	s.SupplierName,
	pt.PackageTypeName,
	i.NumberOfInvoiceLines
FROM Warehouse.StockItems si
	INNER JOIN Purchasing.Suppliers s
		ON si.SupplierID = s.SupplierID
	INNER JOIN Warehouse.PackageTypes pt
		ON si.UnitPackageID = pt.PackageTypeID
	CROSS APPLY
	(
		SELECT
			COUNT(*) AS NumberOfInvoiceLines
		FROM Sales.InvoiceLinesSmall il
		WHERE
			il.StockItemID = si.StockItemID
	) i
WHERE
	si.StockItemName LIKE '%slippers%';


-- Performance is the same as if you used a correlated subquery.
SELECT
	si.StockItemName,
	s.SupplierName,
	pt.PackageTypeName,
	(
		SELECT
			COUNT(*) AS NumberOfInvoiceLines
		FROM Sales.InvoiceLinesSmall il
		WHERE
			il.StockItemID = si.StockItemID
	)
FROM Warehouse.StockItems si
	INNER JOIN Purchasing.Suppliers s
		ON si.SupplierID = s.SupplierID
	INNER JOIN Warehouse.PackageTypes pt
		ON si.UnitPackageID = pt.PackageTypeID
WHERE
	si.StockItemName LIKE '%slippers%';


/* Now let's try this against a larger dataset and see how things compare. */

-- The "normal" way to write this query.
SELECT
	si.StockItemName,
	s.SupplierName,
	pt.PackageTypeName,
	COUNT(*) AS NumberOfInvoiceLines
FROM Warehouse.StockItems si
	INNER JOIN Purchasing.Suppliers s
		ON si.SupplierID = s.SupplierID
	INNER JOIN Warehouse.PackageTypes pt
		ON si.UnitPackageID = pt.PackageTypeID
	INNER JOIN Sales.InvoiceLines il
		ON si.StockItemID = il.StockItemID
WHERE
	si.StockItemName LIKE '%slippers%'
GROUP BY
	si.StockItemName,
	s.SupplierName,
	pt.PackageTypeName;

-- The APPLY Operator way to write this query.
SELECT
	si.StockItemName,
	s.SupplierName,
	pt.PackageTypeName,
	i.NumberOfInvoiceLines
FROM Warehouse.StockItems si
	INNER JOIN Purchasing.Suppliers s
		ON si.SupplierID = s.SupplierID
	INNER JOIN Warehouse.PackageTypes pt
		ON si.UnitPackageID = pt.PackageTypeID
	CROSS APPLY
	(
		SELECT
			COUNT(*) AS NumberOfInvoiceLines
		FROM Sales.InvoiceLines il
		WHERE
			il.StockItemID = si.StockItemID
	) i
WHERE
	si.StockItemName LIKE '%slippers%';


-- Performance is the same as if you used a correlated subquery.
SELECT
	si.StockItemName,
	s.SupplierName,
	pt.PackageTypeName,
	(
		SELECT
			COUNT(*) AS NumberOfInvoiceLines
		FROM Sales.InvoiceLines il
		WHERE
			il.StockItemID = si.StockItemID
	)
FROM Warehouse.StockItems si
	INNER JOIN Purchasing.Suppliers s
		ON si.SupplierID = s.SupplierID
	INNER JOIN Warehouse.PackageTypes pt
		ON si.UnitPackageID = pt.PackageTypeID
WHERE
	si.StockItemName LIKE '%slippers%';