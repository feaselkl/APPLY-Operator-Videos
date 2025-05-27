/* Example 4b:  retrieving a child record from a larger table */
/* What we want:  a view to see each customer's latest transaction, including a few details
	on the customer and the transaction. */

SELECT COUNT(*) FROM Sales.CustomerTransactions;


/* Method 1:  nested sub-query */
SELECT
	c.CustomerName,
	cc.CustomerCategoryName,
	p.FullName AS CustomerContactName,
	t.TransactionDate,
	t.InvoiceID,
	t.OutstandingBalance
FROM Sales.Customers c
	INNER JOIN Sales.CustomerCategories cc
		ON c.CustomerCategoryID = cc.CustomerCategoryID
	INNER JOIN Application.People p
		ON c.PrimaryContactPersonID = p.PersonID
	LEFT OUTER JOIN
	(
		SELECT
			ct.CustomerID,
			MAX(ct.CustomerTransactionID) AS CustomerTransactionID
		FROM Sales.CustomerTransactions ct
		GROUP BY
			ct.CustomerID
	) tmax
		ON c.CustomerID = tmax.CustomerID
	LEFT OUTER JOIN Sales.CustomerTransactions t
		ON tmax.CustomerTransactionID = t.CustomerTransactionID;

/* Method 2:  CTE with a window function */
WITH transactions AS
(
	SELECT
		ct.CustomerID,
		ct.TransactionDate,
		ct.InvoiceID,
		ct.OutstandingBalance,
		ROW_NUMBER() OVER (PARTITION BY ct.CustomerID ORDER BY ct.TransactionDate DESC) AS rownum
	FROM Sales.CustomerTransactions ct
)
SELECT
	c.CustomerName,
	cc.CustomerCategoryName,
	p.FullName AS CustomerContactName,
	t.TransactionDate,
	t.InvoiceID,
	t.OutstandingBalance
FROM Sales.Customers c
	INNER JOIN Sales.CustomerCategories cc
		ON c.CustomerCategoryID = cc.CustomerCategoryID
	INNER JOIN Application.People p
		ON c.PrimaryContactPersonID = p.PersonID
	LEFT OUTER JOIN transactions t
		ON c.CustomerID = t.CustomerID
		AND t.rownum = 1;


/* Method 3:  APPLY operator */
SELECT
	c.CustomerName,
	cc.CustomerCategoryName,
	p.FullName AS CustomerContactName,
	t.TransactionDate,
	t.InvoiceID,
	t.OutstandingBalance
FROM Sales.Customers c
	INNER JOIN Sales.CustomerCategories cc
		ON c.CustomerCategoryID = cc.CustomerCategoryID
	INNER JOIN Application.People p
		ON c.PrimaryContactPersonID = p.PersonID
	OUTER APPLY
	(
		SELECT TOP(1)
			ct.TransactionDate,
			ct.InvoiceID,
			ct.OutstandingBalance
		FROM Sales.CustomerTransactions ct
		WHERE
			ct.CustomerID = c.CustomerID
		ORDER BY
			ct.TransactionDate DESC
	) t;
GO

