/* Example 2:  working with User-Defined Functions. */
/* What we want:  the latest execution plan for each connection. */

-- Create a simple table-valued function.
CREATE OR ALTER FUNCTION dbo.GetPickerDetails
(
@PickedByPersonID INT
)
RETURNS TABLE
AS RETURN
SELECT
	p.FullName,
	p.IsEmployee,
	p.IsSalesperson,
	JSON_VALUE(UserPreferences, '$.theme') AS Theme,
	JSON_VALUE(UserPreferences, '$.timeZone') AS TimeZone
FROM Application.People p
WHERE
	p.PersonID = @PickedByPersonID;
GO

-- Here is a quick test of the function.
SELECT * FROM dbo.GetPickerDetails(3);

-- Show the top 50 orders.  Some of these have picker IDs.
SELECT TOP(50) *
FROM Sales.Orders o
ORDER BY
	o.OrderID ASC;

-- Let's see how CROSS APPLY and OUTER APPLY handle this.
-- Start with OUTER APPLY, where we expect to see the first 50 orders.
SELECT TOP(50)
	o.OrderID,
	o.CustomerID,
	o.PickedByPersonID,
	o.OrderDate,
	p.FullName,
	p.IsEmployee,
	p.IsSalesperson,
	p.Theme,
	p.TimeZone
FROM Sales.Orders o
	OUTER APPLY dbo.GetPickerDetails(o.PickedByPersonID) p;

-- Move to CROSS APPLY, where we expect to see only orders with pickers.
SELECT TOP(50)
	o.OrderID,
	o.CustomerID,
	o.PickedByPersonID,
	o.OrderDate,
	p.FullName,
	p.IsEmployee,
	p.IsSalesperson,
	p.Theme,
	p.TimeZone
FROM Sales.Orders o
	CROSS APPLY dbo.GetPickerDetails(o.PickedByPersonID) p;
GO

-- Now let's try a different function.
-- This one returns NULL if the order value is less than 100 USD,
-- and the order value if greater.
CREATE OR ALTER FUNCTION dbo.GetExpensiveOrderDetails
(
@OrderID INT
)
RETURNS TABLE
AS RETURN
SELECT
	CASE
		WHEN SUM(ol.Quantity * ol.UnitPrice) < 100 THEN NULL
		ELSE SUM(ol.Quantity * ol.UnitPrice)
	END AS OrderPrice
FROM Sales.OrderLines ol
WHERE
	ol.OrderID = @OrderID;
GO

-- Start with OUTER APPLY, where we expect to see the first 50 orders.
SELECT TOP(50)
	o.OrderID,
	o.CustomerID,
	o.PickedByPersonID,
	o.OrderDate,
	d.OrderPrice
FROM Sales.Orders o
	OUTER APPLY dbo.GetExpensiveOrderDetails(o.OrderID) d;

-- Now move to CROSS APPLY, where we expect to see low-cost orders go missing.
SELECT TOP(50)
	o.OrderID,
	o.CustomerID,
	o.PickedByPersonID,
	o.OrderDate,
	d.OrderPrice
FROM Sales.Orders o
	CROSS APPLY dbo.GetExpensiveOrderDetails(o.OrderID) d;
GO

-- But this is interesting!
-- The reason:  CROSS APPLY only filters out a left-hand side row if
-- there is no matching right-hand side row.  But we have one:  it's just
-- that its one value is NULL!
SELECT * FROM dbo.GetExpensiveOrderDetails(3);
GO

-- So let's change this.
CREATE OR ALTER FUNCTION dbo.GetExpensiveOrderDetails
(
@OrderID INT
)
RETURNS TABLE
AS RETURN
SELECT
	SUM(ol.Quantity * ol.UnitPrice) AS OrderPrice
FROM Sales.OrderLines ol
WHERE
	ol.OrderID = @OrderID
HAVING
	SUM(ol.Quantity * ol.UnitPrice) >= 100;
GO

-- Start with OUTER APPLY, where we expect to see the first 50 orders.
SELECT TOP(50)
	o.OrderID,
	o.CustomerID,
	o.PickedByPersonID,
	o.OrderDate,
	d.OrderPrice
FROM Sales.Orders o
	OUTER APPLY dbo.GetExpensiveOrderDetails(o.OrderID) d;

-- Now move to CROSS APPLY, where we expect to see low-cost orders go missing.
SELECT TOP(50)
	o.OrderID,
	o.CustomerID,
	o.PickedByPersonID,
	o.OrderDate,
	d.OrderPrice
FROM Sales.Orders o
	CROSS APPLY dbo.GetExpensiveOrderDetails(o.OrderID) d;
GO

SELECT * FROM dbo.GetExpensiveOrderDetails(3);
GO

-- Clean up the functions
DROP FUNCTION IF EXISTS dbo.GetExpensiveOrderDetails;
DROP FUNCTION IF EXISTS dbo.GetPickerDetails;
GO
