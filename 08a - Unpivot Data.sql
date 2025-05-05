/* Example 8a:  Unpivoting data sets. */
/* We can use the APPLY operator to unpivot a data set.
	This is especially useful when reading in data from finished reports. */

-- Let's start with our financial metrics query.
WITH orders AS
(
	SELECT
		o.OrderID,
		o.OrderDate,
		SUM(il.LineProfit + c.UnitCost) AS Revenue,
		-- Note the duplication here!
		SUM(c.UnitCost) AS CostOfSales,
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
	SUM(o.CostOfSales) AS CostOfSales,
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
			calc2.NetSales - o.CostOfSales AS GrossProfit
	) calc3
GROUP BY
	c.CalendarYear,
	c.CalendarMonth
ORDER BY
	c.CalendarYear,
	c.CalendarMonth;

-- Now we want to unpivot our data set, including all values greater than 0.
-- One way that we can do this is to use the UNPIVOT operator.
WITH orders AS
(
	SELECT
		o.OrderID,
		o.OrderDate,
		SUM(il.LineProfit + c.UnitCost) AS Revenue,
		-- Note the duplication here!
		SUM(c.UnitCost) AS CostOfSales,
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
),
pivotvals AS
(
	SELECT
		c.CalendarYear,
		c.CalendarMonth,
		-- Note that we need to cast these explicitly to the same type; otherwise the query fails.
		CAST(SUM(o.CostOfSales) AS DECIMAL(16,2)) AS CostOfSales,
		CAST(SUM(calc.ShippingCost) AS DECIMAL(16,2)) AS ShippingCost,
		CAST(SUM(o.Revenue) AS DECIMAL(16,2)) AS Revenue,
		CAST(SUM(calc.DiscountAmount) AS DECIMAL(16,2)) AS DiscountAmount,
		CAST(SUM(calc2.NetSales) AS DECIMAL(16,2)) AS NetSales,
		CAST(SUM(calc3.GrossProfit) AS DECIMAL(16,2)) AS GrossProfit,
		CAST((SUM(calc3.GrossProfit)) / SUM(calc2.NetSales) AS DECIMAL(16,2)) AS GrossProfitMargin,
		CAST(SUM(calc3.GrossProfit) - SUM(calc.ShippingCost) AS DECIMAL(16,2)) AS NetIncome
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
				calc2.NetSales - o.CostOfSales AS GrossProfit
		) calc3
	GROUP BY
		c.CalendarYear,
		c.CalendarMonth
)
SELECT
	u.CalendarYear,
	u.CalendarMonth,
	u.Metric,
	u.[Value]
FROM pivotvals p
	UNPIVOT
	(
		[Value] FOR Metric IN (CostOfSales, ShippingCost, Revenue, DiscountAmount,
								NetSales, GrossProfit, GrossProfitMargin, NetIncome)
	) u
WHERE
	u.[Value] > 0
ORDER BY
	CalendarYear,
	CalendarMonth;

-- We can also use the APPLY operator to perform this unpviot.
WITH orders AS
(
	SELECT
		o.OrderID,
		o.OrderDate,
		SUM(il.LineProfit + c.UnitCost) AS Revenue,
		-- Note the duplication here!
		SUM(c.UnitCost) AS CostOfSales,
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
),
pivotvals AS
(
	SELECT
		c.CalendarYear,
		c.CalendarMonth,
		-- With APPLY, we don't need to perform explicit casts;
		-- the values can all be implicitly converted.
		SUM(o.CostOfSales) AS CostOfSales,
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
				calc2.NetSales - o.CostOfSales AS GrossProfit
		) calc3
	GROUP BY
		c.CalendarYear,
		c.CalendarMonth
)
SELECT
	p.CalendarYear,
	p.CalendarMonth,
	u.Metric,
	u.[Value]
FROM pivotvals p
	CROSS APPLY
	(	VALUES
		('Cost of Sales', p.CostOfSales),
		('Shipping Cost', p.ShippingCost),
		('Revenue', p.Revenue),
		('Discount Amount', p.DiscountAmount),
		('Net Sales', p.NetSales),
		('Gross Profit', p.GrossProfit),
		('Gross Profit Margin', p.GrossProfitMargin),
		('Net Income', p.NetIncome)
	) u(Metric, [Value])
WHERE u.[Value] > 0;