/* Example 5b:  retrieving a series of child records for each parent record */
/* What we want:  a view to see each customer's latest 5 invoices, including information
		at the invoice line level. */

/* Method 1:  correlated sub-query */
SELECT
	c.CustomerName,
	cc.CustomerCategoryName,
	p.FullName AS CustomerContactName,
	COUNT(DISTINCT i.InvoiceID) AS NumberOfInvoices,
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
	LEFT OUTER JOIN Sales.Invoices i
		ON c.CustomerID = i.CustomerID
	LEFT OUTER JOIN Sales.InvoiceLines il
		ON i.InvoiceID = il.InvoiceID
WHERE
	i.InvoiceID IN
	(
		SELECT TOP(5)
			inv.InvoiceID
		FROM Sales.Invoices inv
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
WITH invoices AS
(
	SELECT
		inv.CustomerID,
		inv.InvoiceDate,
		inv.InvoiceID,
		ROW_NUMBER() OVER (PARTITION BY inv.CustomerID ORDER BY inv.InvoiceDate DESC) AS rownum
	FROM Sales.Invoices inv
)
SELECT
	c.CustomerName,
	cc.CustomerCategoryName,
	p.FullName AS CustomerContactName,
	COUNT(DISTINCT i.InvoiceID) AS NumberOfInvoices,
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
	LEFT OUTER JOIN invoices i
		ON c.CustomerID = i.CustomerID
		AND i.rownum <= 5
	LEFT OUTER JOIN Sales.InvoiceLines il
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
	COUNT(DISTINCT i.InvoiceID) AS NumberOfInvoices,
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
		FROM Sales.Invoices inv
		WHERE
			inv.CustomerID = c.CustomerID
		ORDER BY
			inv.InvoiceDate DESC
	) i
	LEFT OUTER JOIN Sales.InvoiceLines il
		ON i.InvoiceID = il.InvoiceID
GROUP BY
	c.CustomerName,
	cc.CustomerCategoryName,
	p.FullName;
GO
