/* Example 4a:  retrieving a child record */
/* What we want:  a view to see each customer's latest transaction, including a few details
	on the customer and the transaction. */

/* Sanity check:  how many rows should we get back? */
SELECT
	COUNT(*) AS NumberOfCustomers
FROM Sales.Customers c
	INNER JOIN Application.People p
		ON c.PrimaryContactPersonID = p.PersonID;

/* Create appropriate indexes to make sure that we get the best performance out of each technique. */
IF NOT EXISTS
(
	SELECT *
	FROM sys.indexes i
	WHERE
		i.name = N'IX_Sales_CustomerTransactionsSmall_TransactionDate'
)
BEGIN
	CREATE NONCLUSTERED INDEX [IX_Sales_CustomerTransactionsSmall_TransactionDate] ON Sales.CustomerTransactionsSmall
	(
		CustomerID ASC,
		TransactionDate ASC
	)
	INCLUDE
	(
		InvoiceID,
		OutstandingBalance
	) WITH(DATA_COMPRESSION = PAGE)
END
GO

IF NOT EXISTS
(
	SELECT *
	FROM sys.indexes i
	WHERE
		i.name = N'IX_Sales_CustomerTransactions_TransactionDate'
)
BEGIN
	CREATE NONCLUSTERED INDEX [IX_Sales_CustomerTransactions_TransactionDate] ON Sales.CustomerTransactions
	(
		CustomerID ASC,
		TransactionDate ASC
	)
	INCLUDE
	(
		InvoiceID,
		OutstandingBalance
	) WITH(DATA_COMPRESSION = PAGE)
END
GO

-- Build out a micro version of the transactions table.
-- Even with the Small table, the distribution of customers versus
-- transactions is such that APPLY works well.
SELECT TOP(2000) *
INTO #CustomerTransactionsMicro
FROM Sales.CustomerTransactionsSmall
ORDER BY
	CustomerTransactionID DESC;

CREATE NONCLUSTERED INDEX [IX_CustomerTransactionsMicro_TransactionDate] ON #CustomerTransactionsMicro
(
	CustomerID ASC,
	TransactionDate ASC
)
INCLUDE
(
	InvoiceID,
	OutstandingBalance
);


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
		FROM #CustomerTransactionsMicro ct
		GROUP BY
			ct.CustomerID
	) tmax
		ON c.CustomerID = tmax.CustomerID
	LEFT OUTER JOIN #CustomerTransactionsMicro t
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
	FROM #CustomerTransactionsMicro ct
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
		FROM #CustomerTransactionsMicro ct
		WHERE
			ct.CustomerID = c.CustomerID
		ORDER BY
			ct.TransactionDate DESC
	) t;
GO
