/* Example 7:  APPLY has its limits */

-- If this is good...
SELECT
	o.OrderID,
	o.OrderDate,
	SUM(il.LineProfit + c.UnitCost) AS Revenue,
	SUM(c.UnitCost) AS CostOfGoodsSold,
	SUM(il.Quantity * si.TypicalWeightPerUnit) AS TotalWeight
FROM Sales.Orders o
	INNER JOIN Sales.Invoices i
		ON i.OrderID = o.OrderID
	INNER JOIN Sales.InvoiceLines il
		ON il.InvoiceID = i.InvoiceID
	INNER JOIN Warehouse.StockItems si
		ON il.StockItemID = si.StockItemID
	CROSS APPLY
	(
		SELECT
			il.UnitPrice * il.Quantity AS UnitCost
	) c
GROUP BY
	o.OrderID,
	o.OrderDate;

-- Couldn't this be better?
SELECT
	o.OrderID,
	o.OrderDate,
	c.CostOfGoodsSold
FROM Sales.Orders o
	INNER JOIN Sales.Invoices i
		ON i.OrderID = o.OrderID
	INNER JOIN Sales.InvoiceLines il
		ON il.InvoiceID = i.InvoiceID
	INNER JOIN Warehouse.StockItems si
		ON il.StockItemID = si.StockItemID
	CROSS APPLY
	(
		SELECT
			SUM(il.UnitPrice * il.Quantity) AS CostOfGoodsSold
	) c
GROUP BY
	o.OrderID,
	o.OrderDate;

-- APPLY and windows
-- Let's look at orders by customer in a given month.
SELECT
	o.OrderID,
	o.CustomerID,
	ROW_NUMBER() OVER (PARTITION BY o.CustomerID ORDER BY o.OrderID) AS rownum
FROM Sales.Orders o
	INNER JOIN dbo.Calendar c
		ON o.OrderDate = c.Date
WHERE
	c.CalendarYear = 2016
	AND c.CalendarMonth = 9;

-- Suppose we'd like to get just the first 5 orders for each customer.
-- We can't do this because we defined rownum in the SELECT clause:
SELECT
	o.OrderID,
	o.CustomerID,
	ROW_NUMBER() OVER (PARTITION BY o.CustomerID ORDER BY o.OrderID) AS rownum
FROM Sales.Orders o
	INNER JOIN dbo.Calendar c
		ON o.OrderDate = c.Date
WHERE
	c.CalendarYear = 2016
	AND c.CalendarMonth = 9
	AND rownum <= 5;

-- It'd be really nice to do something like this:
SELECT
	o.OrderID,
	o.CustomerID,
	r.rownum
FROM Sales.Orders o
	INNER JOIN dbo.Calendar c
		ON o.OrderDate = c.Date
	CROSS APPLY
	(
		SELECT
			ROW_NUMBER() OVER (PARTITION BY o.CustomerID ORDER BY o.OrderID) AS rownum
	) r
WHERE
	c.CalendarYear = 2016
	AND c.CalendarMonth = 9
	AND r.rownum <= 5
ORDER BY
	o.CustomerID,
	o.OrderID,
	r.rownum;

-- Instead, we put it this in a CTE or subquery:
WITH orders AS
(
	SELECT
		o.OrderID,
		o.CustomerID,
		ROW_NUMBER() OVER (PARTITION BY o.CustomerID ORDER BY o.OrderID) AS rownum
	FROM Sales.Orders o
		INNER JOIN dbo.Calendar c
			ON o.OrderDate = c.Date
	WHERE
		c.CalendarYear = 2016
		AND c.CalendarMonth = 9
)
SELECT *
FROM orders o
WHERE o.rownum <= 5
ORDER BY
	o.CustomerID,
	o.rownum;
