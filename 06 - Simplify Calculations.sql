/* Example 6:  simplifying calculations */
/* Wide World Importers Accounting wants us to build a report based on
	some hypothetical changes to the way they do business.

	The new rules:
	- Orders over $4000 get a 5% discount
	- Orders over $8000 get a 10% discount
	- Orders under 3kg ship for free
	- Orders over 3kg cost $5 + 20 cents per kilo to ship

	What they want BY MONTH:
	- Revenue (sum of retail price * quantity sold)
	- Net Sales (Revenue - sum of discounts)
	- Cost of Goods Sold (sum of unit cost * quantity sold)
	- Shipping Expenses (sum of shipping costs)
	- Gross Profit (Net Sales - Cost of Goods Sold)
	- Gross Profit Margin (Gross Profit / Net Sales)
	- Net Income (Gross Profit - Shipping Expenses)
*/

-- Step 1:  Calculate Revenue by month
-- Unit Price is the *cost*.
-- Line Profit is the difference between retail price and cost.
SELECT
	c.CalendarYear,
	c.CalendarMonth,
	SUM(il.LineProfit + (il.UnitPrice * il.Quantity)) AS Revenue
FROM Sales.Orders o
	INNER JOIN Sales.Invoices i
		ON i.OrderID = o.OrderID
	INNER JOIN Sales.InvoiceLines il
		ON il.InvoiceID = i.InvoiceID
	INNER JOIN dbo.Calendar c
		ON o.OrderDate = c.Date
GROUP BY
	c.CalendarYear,
	c.CalendarMonth
ORDER BY
	c.CalendarYear,
	c.CalendarMonth;

-- Step 2:  Calculate Net Sales by month.
-- We need to add in discount rules:  any order with revenue > 4000 gets a 5% discount
-- Any order with revenue > 8000 gets a 10% discount
WITH orders AS
(
	SELECT
		o.OrderID,
		o.OrderDate,
		SUM(il.LineProfit + (il.UnitPrice * il.Quantity)) AS Revenue
	FROM Sales.Orders o
		INNER JOIN Sales.Invoices i
			ON i.OrderID = o.OrderID
		INNER JOIN Sales.InvoiceLines il
			ON il.InvoiceID = i.InvoiceID
	GROUP BY
		o.OrderID,
		o.OrderDate
)
SELECT
	c.CalendarYear,
	c.CalendarMonth,
	SUM(o.Revenue) AS Revenue,
	SUM(CASE
			WHEN o.Revenue > 8000 THEN o.Revenue * 0.1
			WHEN o.Revenue > 4000 THEN o.Revenue * 0.05
			ELSE 0.0
		END) AS DiscountAmount,
	-- Note the duplication here!
	SUM(o.Revenue - CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) AS NetSales
FROM orders o
	INNER JOIN dbo.Calendar c
		ON o.OrderDate = c.Date
GROUP BY
	c.CalendarYear,
	c.CalendarMonth
ORDER BY
	c.CalendarYear,
	c.CalendarMonth;

-- Step 3:  Calculate Cost of Goods Sold by month.
WITH orders AS
(
	SELECT
		o.OrderID,
		o.OrderDate,
		SUM(il.LineProfit + (il.UnitPrice * il.Quantity)) AS Revenue,
		-- Note the duplication here!
		SUM(il.UnitPrice * il.Quantity) AS CostOfGoodsSold
	FROM Sales.Orders o
		INNER JOIN Sales.Invoices i
			ON i.OrderID = o.OrderID
		INNER JOIN Sales.InvoiceLines il
			ON il.InvoiceID = i.InvoiceID
	GROUP BY
		o.OrderID,
		o.OrderDate
)
SELECT
	c.CalendarYear,
	c.CalendarMonth,
	SUM(o.CostOfGoodsSold) AS CostOfGoodsSold,
	SUM(o.Revenue) AS Revenue,
	SUM(CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) AS DiscountAmount,
	-- Note the duplication here!
	SUM(o.Revenue - CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) AS NetSales
FROM orders o
	INNER JOIN dbo.Calendar c
		ON o.OrderDate = c.Date
GROUP BY
	c.CalendarYear,
	c.CalendarMonth
ORDER BY
	c.CalendarYear,
	c.CalendarMonth;

-- Step 4:  Calculate shipping expenses
-- Orders under 3kg ship for free
-- Orders over 3kg cost $5 + 20 cents per kilo to ship
WITH orders AS
(
	SELECT
		o.OrderID,
		o.OrderDate,
		SUM(il.LineProfit + (il.UnitPrice * il.Quantity)) AS Revenue,
		-- Note the duplication here!
		SUM(il.UnitPrice * il.Quantity) AS CostOfGoodsSold,
		SUM(il.Quantity * si.TypicalWeightPerUnit) AS TotalWeight
	FROM Sales.Orders o
		INNER JOIN Sales.Invoices i
			ON i.OrderID = o.OrderID
		INNER JOIN Sales.InvoiceLines il
			ON il.InvoiceID = i.InvoiceID
		INNER JOIN Warehouse.StockItems si
			ON il.StockItemID = si.StockItemID
	GROUP BY
		o.OrderID,
		o.OrderDate
)
SELECT
	c.CalendarYear,
	c.CalendarMonth,
	SUM(o.CostOfGoodsSold) AS CostOfGoodsSold,
	SUM(CASE WHEN o.TotalWeight <= 3 THEN 0.0 ELSE 5.0 + 0.2 * o.TotalWeight END) AS ShippingCost,
	SUM(o.Revenue) AS Revenue,
	SUM(CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) AS DiscountAmount,
	-- Note the duplication here!
	SUM(o.Revenue - CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) AS NetSales
FROM orders o
	INNER JOIN dbo.Calendar c
		ON o.OrderDate = c.Date
GROUP BY
	c.CalendarYear,
	c.CalendarMonth
ORDER BY
	c.CalendarYear,
	c.CalendarMonth;

-- Step 5:  Calculate Gross Profit = Net Sales - Cost of Goods Sold
WITH orders AS
(
	SELECT
		o.OrderID,
		o.OrderDate,
		SUM(il.LineProfit + (il.UnitPrice * il.Quantity)) AS Revenue,
		-- Note the duplication here!
		SUM(il.UnitPrice * il.Quantity) AS CostOfGoodsSold,
		SUM(il.Quantity * si.TypicalWeightPerUnit) AS TotalWeight
	FROM Sales.Orders o
		INNER JOIN Sales.Invoices i
			ON i.OrderID = o.OrderID
		INNER JOIN Sales.InvoiceLines il
			ON il.InvoiceID = i.InvoiceID
		INNER JOIN Warehouse.StockItems si
			ON il.StockItemID = si.StockItemID
	GROUP BY
		o.OrderID,
		o.OrderDate
)
SELECT
	c.CalendarYear,
	c.CalendarMonth,
	SUM(o.CostOfGoodsSold) AS CostOfGoodsSold,
	SUM(CASE WHEN o.TotalWeight <= 3 THEN 0.0 ELSE 5.0 + 0.2 * o.TotalWeight END) AS ShippingCost,
	SUM(o.Revenue) AS Revenue,
	SUM(CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) AS DiscountAmount,
	-- Note the duplication here!
	SUM(o.Revenue - CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) AS NetSales,
	-- More duplication!
	SUM(o.Revenue - CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) - SUM(o.CostOfGoodsSold) AS GrossProfit
FROM orders o
	INNER JOIN dbo.Calendar c
		ON o.OrderDate = c.Date
GROUP BY
	c.CalendarYear,
	c.CalendarMonth
ORDER BY
	c.CalendarYear,
	c.CalendarMonth;

-- Step 6:  Calculate Gross Profit Margin = Gross Profit / Net Sales
WITH orders AS
(
	SELECT
		o.OrderID,
		o.OrderDate,
		SUM(il.LineProfit + (il.UnitPrice * il.Quantity)) AS Revenue,
		-- Note the duplication here!
		SUM(il.UnitPrice * il.Quantity) AS CostOfGoodsSold,
		SUM(il.Quantity * si.TypicalWeightPerUnit) AS TotalWeight
	FROM Sales.Orders o
		INNER JOIN Sales.Invoices i
			ON i.OrderID = o.OrderID
		INNER JOIN Sales.InvoiceLines il
			ON il.InvoiceID = i.InvoiceID
		INNER JOIN Warehouse.StockItems si
			ON il.StockItemID = si.StockItemID
	GROUP BY
		o.OrderID,
		o.OrderDate
)
SELECT
	c.CalendarYear,
	c.CalendarMonth,
	SUM(o.CostOfGoodsSold) AS CostOfGoodsSold,
	SUM(CASE WHEN o.TotalWeight <= 3 THEN 0.0 ELSE 5.0 + 0.2 * o.TotalWeight END) AS ShippingCost,
	SUM(o.Revenue) AS Revenue,
	SUM(CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) AS DiscountAmount,
	-- Note the duplication here!
	SUM(o.Revenue - CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) AS NetSales,
	-- More duplication!
	SUM(o.Revenue - CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) - SUM(o.CostOfGoodsSold) AS GrossProfit,
	-- Even more duplication and getting hard to read
	(SUM(o.Revenue - CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) - SUM(o.CostOfGoodsSold)) /
		SUM(o.Revenue - CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) AS GrossProfitMargin
FROM orders o
	INNER JOIN dbo.Calendar c
		ON o.OrderDate = c.Date
GROUP BY
	c.CalendarYear,
	c.CalendarMonth
ORDER BY
	c.CalendarYear,
	c.CalendarMonth;

-- Step 7:  Net Income = Gross Profit - Shipping Cost
WITH orders AS
(
	SELECT
		o.OrderID,
		o.OrderDate,
		SUM(il.LineProfit + (il.UnitPrice * il.Quantity)) AS Revenue,
		-- Note the duplication here!
		SUM(il.UnitPrice * il.Quantity) AS CostOfGoodsSold,
		SUM(il.Quantity * si.TypicalWeightPerUnit) AS TotalWeight
	FROM Sales.Orders o
		INNER JOIN Sales.Invoices i
			ON i.OrderID = o.OrderID
		INNER JOIN Sales.InvoiceLines il
			ON il.InvoiceID = i.InvoiceID
		INNER JOIN Warehouse.StockItems si
			ON il.StockItemID = si.StockItemID
	GROUP BY
		o.OrderID,
		o.OrderDate
)
SELECT
	c.CalendarYear,
	c.CalendarMonth,
	SUM(o.CostOfGoodsSold) AS CostOfGoodsSold,
	SUM(CASE WHEN o.TotalWeight <= 3 THEN 0.0 ELSE 5.0 + 0.2 * o.TotalWeight END) AS ShippingCost,
	SUM(o.Revenue) AS Revenue,
	SUM(CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) AS DiscountAmount,
	-- Note the duplication here!
	SUM(o.Revenue - CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) AS NetSales,
	-- More duplication!
	SUM(o.Revenue - CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) - SUM(o.CostOfGoodsSold) AS GrossProfit,
	-- Even more duplication and getting hard to read
	(SUM(o.Revenue - CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) - SUM(o.CostOfGoodsSold)) /
		SUM(o.Revenue - CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) AS GrossProfitMargin,
	SUM(o.Revenue - CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) - SUM(o.CostOfGoodsSold) - SUM(CASE WHEN o.TotalWeight <= 3 THEN 0.0 ELSE 5.0 + 0.2 * o.TotalWeight END) AS NetIncome
FROM orders o
	INNER JOIN dbo.Calendar c
		ON o.OrderDate = c.Date
GROUP BY
	c.CalendarYear,
	c.CalendarMonth
ORDER BY
	c.CalendarYear,
	c.CalendarMonth;

-- Now imagine having to change something like the discount amount!

-- The alternative:  use the APPLY operator to simplify these calculations.
-- Step 1:  Simplify within the CTE.
WITH orders AS
(
	SELECT
		o.OrderID,
		o.OrderDate,
		SUM(il.LineProfit + c.UnitCost) AS Revenue,
		-- No more duplication!
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
		o.OrderDate
)
SELECT
	c.CalendarYear,
	c.CalendarMonth,
	SUM(o.CostOfGoodsSold) AS CostOfGoodsSold,
	SUM(CASE WHEN o.TotalWeight <= 3 THEN 0.0 ELSE 5.0 + 0.2 * o.TotalWeight END) AS ShippingCost,
	SUM(o.Revenue) AS Revenue,
	SUM(CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) AS DiscountAmount,
	-- Note the duplication here!
	SUM(o.Revenue - CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) AS NetSales,
	-- More duplication!
	SUM(o.Revenue - CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) - SUM(o.CostOfGoodsSold) AS GrossProfit,
	-- Even more duplication and getting hard to read
	(SUM(o.Revenue - CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) - SUM(o.CostOfGoodsSold)) /
		SUM(o.Revenue - CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) AS GrossProfitMargin,
	SUM(o.Revenue - CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) - SUM(o.CostOfGoodsSold) - SUM(CASE WHEN o.TotalWeight <= 3 THEN 0.0 ELSE 5.0 + 0.2 * o.TotalWeight END) AS NetIncome
FROM orders o
	INNER JOIN dbo.Calendar c
		ON o.OrderDate = c.Date
GROUP BY
	c.CalendarYear,
	c.CalendarMonth
ORDER BY
	c.CalendarYear,
	c.CalendarMonth;

-- Step 2:  Simplify in the main query.
WITH orders AS
(
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
		o.OrderDate
)
SELECT
	c.CalendarYear,
	c.CalendarMonth,
	SUM(o.CostOfGoodsSold) AS CostOfGoodsSold,
	SUM(calc.ShippingCost) AS ShippingCost,
	SUM(o.Revenue) AS Revenue,
	SUM(calc.DiscountAmount) AS DiscountAmount,
	SUM(calc2.NetSales) AS NetSales,
	SUM(calc3.GrossProfit) AS GrossProfit,
	(SUM(calc3.GrossProfit)) / SUM(calc2.NetSales) AS GrossProfitMargin,
	SUM(calc3.GrossProfit) - SUM(calc.ShippingCost) AS NetIncome
FROM orders o
	INNER JOIN dbo.Calendar c
		ON o.OrderDate = c.Date
	CROSS APPLY
	(
		SELECT
			CASE
				WHEN o.TotalWeight <= 3 THEN 0.0
				ELSE 5.0 + 0.2 * o.TotalWeight
			END AS ShippingCost,
			CASE
				WHEN o.Revenue > 8000 THEN o.Revenue * 0.1
				WHEN o.Revenue > 4000 THEN o.Revenue * 0.05
				ELSE 0.0
			END AS DiscountAmount
	) calc
	CROSS APPLY
	(
		SELECT
			o.Revenue - calc.DiscountAmount AS NetSales
	) calc2
	CROSS APPLY
	(
		SELECT
			calc2.NetSales - o.CostOfGoodsSold AS GrossProfit
	) calc3
GROUP BY
	c.CalendarYear,
	c.CalendarMonth
ORDER BY
	c.CalendarYear,
	c.CalendarMonth;



-- Comparing the final forms for performance:
WITH orders AS
(
	SELECT
		o.OrderID,
		o.OrderDate,
		SUM(il.LineProfit + (il.UnitPrice * il.Quantity)) AS Revenue,
		-- Note the duplication here!
		SUM(il.UnitPrice * il.Quantity) AS CostOfGoodsSold,
		SUM(il.Quantity * si.TypicalWeightPerUnit) AS TotalWeight
	FROM Sales.Orders o
		INNER JOIN Sales.Invoices i
			ON i.OrderID = o.OrderID
		INNER JOIN Sales.InvoiceLines il
			ON il.InvoiceID = i.InvoiceID
		INNER JOIN Warehouse.StockItems si
			ON il.StockItemID = si.StockItemID
	GROUP BY
		o.OrderID,
		o.OrderDate
)
SELECT
	c.CalendarYear,
	c.CalendarMonth,
	SUM(o.CostOfGoodsSold) AS CostOfGoodsSold,
	SUM(CASE WHEN o.TotalWeight <= 3 THEN 0.0 ELSE 5.0 + 0.2 * o.TotalWeight END) AS ShippingCost,
	SUM(o.Revenue) AS Revenue,
	SUM(CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) AS DiscountAmount,
	-- Note the duplication here!
	SUM(o.Revenue - CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) AS NetSales,
	-- More duplication!
	SUM(o.Revenue - CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) - SUM(o.CostOfGoodsSold) AS GrossProfit,
	-- Even more duplication and getting hard to read
	(SUM(o.Revenue - CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) - SUM(o.CostOfGoodsSold)) /
		SUM(o.Revenue - CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) AS GrossProfitMargin,
	SUM(o.Revenue - CASE WHEN o.Revenue > 8000 THEN o.Revenue * 0.1 WHEN o.Revenue > 4000 THEN o.Revenue * 0.05 ELSE 0.0 END) - SUM(o.CostOfGoodsSold) - SUM(CASE WHEN o.TotalWeight <= 3 THEN 0.0 ELSE 5.0 + 0.2 * o.TotalWeight END) AS NetIncome
FROM orders o
	INNER JOIN dbo.Calendar c
		ON o.OrderDate = c.Date
GROUP BY
	c.CalendarYear,
	c.CalendarMonth
ORDER BY
	c.CalendarYear,
	c.CalendarMonth;

WITH orders AS
(
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
		o.OrderDate
)
SELECT
	c.CalendarYear,
	c.CalendarMonth,
	SUM(o.CostOfGoodsSold) AS CostOfGoodsSold,
	SUM(calc.ShippingCost) AS ShippingCost,
	SUM(o.Revenue) AS Revenue,
	SUM(calc.DiscountAmount) AS DiscountAmount,
	SUM(calc2.NetSales) AS NetSales,
	SUM(calc3.GrossProfit) AS GrossProfit,
	(SUM(calc3.GrossProfit)) / SUM(calc2.NetSales) AS GrossProfitMargin,
	SUM(calc3.GrossProfit) - SUM(calc.ShippingCost) AS NetIncome
FROM orders o
	INNER JOIN dbo.Calendar c
		ON o.OrderDate = c.Date
	CROSS APPLY
	(
		SELECT
			CASE
				WHEN o.TotalWeight <= 3 THEN 0.0
				ELSE 5.0 + 0.2 * o.TotalWeight
			END AS ShippingCost,
			CASE
				WHEN o.Revenue > 8000 THEN o.Revenue * 0.1
				WHEN o.Revenue > 4000 THEN o.Revenue * 0.05
				ELSE 0.0
			END AS DiscountAmount
	) calc
	CROSS APPLY
	(
		SELECT
			o.Revenue - calc.DiscountAmount AS NetSales
	) calc2
	CROSS APPLY
	(
		SELECT
			calc2.NetSales - o.CostOfGoodsSold AS GrossProfit
	) calc3
GROUP BY
	c.CalendarYear,
	c.CalendarMonth
ORDER BY
	c.CalendarYear,
	c.CalendarMonth;