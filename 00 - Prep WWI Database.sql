/* NOTE:  you only need to run this if you decide to download the Wide World Importers
	database and run load it yourself rather than downloading my database backup. */

-- Prep script for APPLY Yourself training.

-- Move existing data to "small" tables.
SELECT *
INTO Sales.InvoiceLinesSmall
FROM Sales.InvoiceLines;

SELECT *
INTO Sales.InvoicesSmall
FROM Sales.Invoices;

SELECT *
INTO Sales.OrderLinesSmall
FROM Sales.OrderLines;

SELECT *
INTO Sales.OrdersSmall
FROM Sales.Orders;

SELECT *
INTO Sales.CustomerTransactionsSmall
FROM Sales.CustomerTransactions

-- Load much more data.
-- This will take a while!  On my machine, it took just under 8 hours.
EXECUTE DataLoadSimulation.PopulateDataToCurrentDate
        @AverageNumberOfCustomerOrdersPerDay = 303,
        @SaturdayPercentageOfNormalWorkDay = 55,
        @SundayPercentageOfNormalWorkDay = 21,
        @IsSilentMode = 1,
        @AreDatesPrinted = 1;