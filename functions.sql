USE [AdventureWorks2014]
GO

-- scalar function
--ALTER FUNCTION test ()
--RETURNS INT
--AS
--BEGIN
--	RETURN 42;
--END

--SELECT dbo.test()

CREATE FUNCTION Sales.uf_MostRecentCustomerOrderDate(@CustomerID INT)
	RETURNS DATETIME
AS 
BEGIN
	DECLARE @MostRecentOrderDate DATETIME;

	SELECT @MostRecentOrderDate = MAX(OrderDate)
	FROM Sales.SalesOrderHeader 
	WHERE CustomerID = @CustomerID;

	RETURN @MostRecentOrderDate;
END;

SELECT Sales.uf_MostRecentCustomerOrderDate(11000)

-- yields all the customers with order dates using cross apply
SELECT c.CustomerID,
	cod.OrderDate
FROM sales.Customer c
CROSS APPLY Sales.uf_CustomerOrderDates(c.CustomerID) cod

-- table function
CREATE FUNCTION Sales.uf_CustomerOrderDates(@CustomerID int)
	RETURNS TABLE
AS
RETURN
SELECT OrderDate
FROM Sales.SalesOrderHeader
WHERE CustomerID = @CustomerID;

SELECT OrderDate
FROM Sales.uf_CustomerOrderDates(11000)

-- multi statement table valued function
-- returns a table, but can use complex logic

ALTER FUNCTION Sales.uf_CustomerOrderDetails(@ContactsWithOrders bit)
	RETURNS @ContactOrderDetails TABLE (ContactID int)
AS
BEGIN
	IF @ContactsWithOrders = 1
	BEGIN
	    INSERT INTO @ContactOrderDetails
		SELECT CustomerID
		FROM Sales.Customer c
		WHERE EXISTS (SELECT * 
						FROM Sales.SalesOrderHeader soh
						WHERE soh.CustomerId = c.CustomerId);
	END
	ELSE
	BEGIN
		INSERT INTO @ContactOrderDetails
		SELECT CustomerID
		FROM Sales.Customer c
		WHERE NOT EXISTS (SELECT *
							FROM Sales.SalesOrderHeader soh
							WHERE soh.CustomerID = c.CustomerID);
	END
	RETURN;
END;

SELECT *
FROM Sales.uf_CustomerOrderDetails(0)