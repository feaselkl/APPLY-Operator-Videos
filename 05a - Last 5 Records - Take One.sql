/* Example 5a:  retrieving a series of child records for each parent record */
/* What we want:  a view to see each customer's latest 5 InvoicesSmall, including information
		at the invoice line level. */

/* Create appropriate indexes to make sure that we get the best performance out of each technique. */
IF NOT EXISTS
(
	SELECT *
	FROM sys.indexes i
	WHERE
		i.name = N'IX_Sales_InvoicesSmall_InvoiceDate'
)
BEGIN
	CREATE NONCLUSTERED INDEX [IX_Sales_InvoicesSmall_InvoiceDate] ON Sales.InvoicesSmall
	(
		CustomerID ASC,
		InvoiceDate ASC
	)
	INCLUDE
	(
		InvoiceID
	) WITH(DATA_COMPRESSION = PAGE)
END
GO

IF NOT EXISTS
(
	SELECT *
	FROM sys.indexes i
	WHERE
		i.name = N'IX_Sales_Invoices_InvoiceDate'
)
BEGIN
	CREATE NONCLUSTERED INDEX [IX_Sales_Invoices_InvoiceDate] ON Sales.Invoices
	(
		CustomerID ASC,
		InvoiceDate ASC
	)
	INCLUDE
	(
		InvoiceID
	) WITH(DATA_COMPRESSION = PAGE)
END
GO

/* Method 1:  correlated sub-query */
SELECT
	c.CustomerName,
	cc.CustomerCategoryName,
	p.FullName AS CustomerContactName,
	COUNT(DISTINCT i.InvoiceID) AS NumberOfInvoicesSmall,
	COUNT(*) AS NumberOfInvoiceLines,
	SUM(il.Quantity) AS TotalQuantity,
	SUM(il.ExtendedPrice) AS TotalExtendedPrice,
	SUM(il.TaxAmount) AS TotalTaxAmount,
	SUM(il.LineProfit) AS TotalProfit
FROM Sales.Customers c
	INNER JOIN Sales.CustomerCategories cc
		ON c.CustomerCategoryID = cc.CustomerCategoryID
	INNER JOIN Application.People p
		ON c.PrimaryContactPersonID = p.PersonID
	LEFT OUTER JOIN Sales.InvoicesSmall i
		ON c.CustomerID = i.CustomerID
	LEFT OUTER JOIN Sales.InvoiceLinesSmall il
		ON i.InvoiceID = il.InvoiceID
WHERE
	i.InvoiceID IN
	(
		SELECT TOP(5)
			inv.InvoiceID
		FROM Sales.InvoicesSmall inv
		WHERE
			inv.CustomerID = c.CustomerID
		ORDER BY
			inv.InvoiceDate DESC
	)
GROUP BY
	c.CustomerName,
	cc.CustomerCategoryName,
	p.FullName;

/* Method 2:  CTE with a window function */
WITH InvoicesSmall AS
(
	SELECT
		inv.CustomerID,
		inv.InvoiceDate,
		inv.InvoiceID,
		ROW_NUMBER() OVER (PARTITION BY inv.CustomerID ORDER BY inv.InvoiceDate DESC) AS rownum
	FROM Sales.InvoicesSmall inv
)
SELECT
	c.CustomerName,
	cc.CustomerCategoryName,
	p.FullName AS CustomerContactName,
	COUNT(DISTINCT i.InvoiceID) AS NumberOfInvoicesSmall,
	COUNT(*) AS NumberOfInvoiceLines,
	SUM(il.Quantity) AS TotalQuantity,
	SUM(il.ExtendedPrice) AS TotalExtendedPrice,
	SUM(il.TaxAmount) AS TotalTaxAmount,
	SUM(il.LineProfit) AS TotalProfit
FROM Sales.Customers c
	INNER JOIN Sales.CustomerCategories cc
		ON c.CustomerCategoryID = cc.CustomerCategoryID
	INNER JOIN Application.People p
		ON c.PrimaryContactPersonID = p.PersonID
	LEFT OUTER JOIN InvoicesSmall i
		ON c.CustomerID = i.CustomerID
		AND i.rownum <= 5
	LEFT OUTER JOIN Sales.InvoiceLinesSmall il
		ON i.InvoiceID = il.InvoiceID
GROUP BY
	c.CustomerName,
	cc.CustomerCategoryName,
	p.FullName;


/* Method 3:  APPLY operator */
SELECT
	c.CustomerName,
	cc.CustomerCategoryName,
	p.FullName AS CustomerContactName,
	COUNT(DISTINCT i.InvoiceID) AS NumberOfInvoicesSmall,
	COUNT(*) AS NumberOfInvoiceLines,
	SUM(il.Quantity) AS TotalQuantity,
	SUM(il.ExtendedPrice) AS TotalExtendedPrice,
	SUM(il.TaxAmount) AS TotalTaxAmount,
	SUM(il.LineProfit) AS TotalProfit
FROM Sales.Customers c
	INNER JOIN Sales.CustomerCategories cc
		ON c.CustomerCategoryID = cc.CustomerCategoryID
	INNER JOIN Application.People p
		ON c.PrimaryContactPersonID = p.PersonID
	OUTER APPLY
	(
		SELECT TOP(5)
			inv.InvoiceID,
			inv.InvoiceDate
		FROM Sales.InvoicesSmall inv
		WHERE
			inv.CustomerID = c.CustomerID
		ORDER BY
			inv.InvoiceDate DESC
	) i
	LEFT OUTER JOIN Sales.InvoiceLinesSmall il
		ON i.InvoiceID = il.InvoiceID
GROUP BY
	c.CustomerName,
	cc.CustomerCategoryName,
	p.FullName;
GO
