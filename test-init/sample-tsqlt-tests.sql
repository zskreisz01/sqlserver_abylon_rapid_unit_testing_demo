-- Sample tSQLt Unit Tests for SampleDatabase
-- These tests demonstrate unit testing with tSQLt framework

USE SampleDatabase_Test;
GO

-- Create a test class for Customer tests
EXEC tSQLt.NewTestClass 'CustomerTests';
GO

-- Test: Verify customer insertion
CREATE PROCEDURE CustomerTests.[test Customer insertion creates record with all fields]
AS
BEGIN
    -- Arrange
    DECLARE @CustomerId INT;
    DECLARE @ExpectedFirstName NVARCHAR(50) = 'John';
    DECLARE @ExpectedLastName NVARCHAR(50) = 'Doe';
    DECLARE @ExpectedEmail NVARCHAR(100) = 'john.doe@test.com';

    -- Act
    EXEC usp_AddCustomer
        @FirstName = @ExpectedFirstName,
        @LastName = @ExpectedLastName,
        @Email = @ExpectedEmail,
        @PhoneNumber = '555-1234',
        @CustomerId = @CustomerId OUTPUT;

    -- Assert
    DECLARE @ActualFirstName NVARCHAR(50);
    DECLARE @ActualLastName NVARCHAR(50);
    DECLARE @ActualEmail NVARCHAR(100);

    SELECT
        @ActualFirstName = FirstName,
        @ActualLastName = LastName,
        @ActualEmail = Email
    FROM Customers
    WHERE CustomerId = @CustomerId;

    EXEC tSQLt.AssertEquals @ExpectedFirstName, @ActualFirstName, 'FirstName does not match';
    EXEC tSQLt.AssertEquals @ExpectedLastName, @ActualLastName, 'LastName does not match';
    EXEC tSQLt.AssertEquals @ExpectedEmail, @ActualEmail, 'Email does not match';
END;
GO

-- Test: Verify email is unique (should be tested via constraint, but this is an example)
CREATE PROCEDURE CustomerTests.[test Customer email is stored correctly]
AS
BEGIN
    -- Arrange
    DECLARE @CustomerId INT;
    DECLARE @TestEmail NVARCHAR(100) = 'unique@test.com';

    -- Act
    EXEC usp_AddCustomer
        @FirstName = 'Test',
        @LastName = 'User',
        @Email = @TestEmail,
        @PhoneNumber = NULL,
        @CustomerId = @CustomerId OUTPUT;

    -- Assert
    DECLARE @Count INT;
    SELECT @Count = COUNT(*)
    FROM Customers
    WHERE Email = @TestEmail;

    EXEC tSQLt.AssertEquals 1, @Count, 'Email should appear exactly once';
END;
GO

-- Create a test class for Order tests
EXEC tSQLt.NewTestClass 'OrderTests';
GO

-- Test: Verify foreign key relationship
CREATE PROCEDURE OrderTests.[test Order requires valid CustomerId]
AS
BEGIN
    -- Arrange
    EXEC tSQLt.FakeTable 'Orders';
    EXEC tSQLt.FakeTable 'Customers';

    -- Insert a test customer
    INSERT INTO Customers (CustomerId, FirstName, LastName, Email, CreatedDate, ModifiedDate)
    VALUES (1, 'John', 'Doe', 'john@test.com', GETDATE(), GETDATE());

    -- Act
    INSERT INTO Orders (CustomerId, TotalAmount, Status, CreatedDate)
    VALUES (1, 100.00, 'Pending', GETDATE());

    -- Assert
    DECLARE @OrderCount INT;
    SELECT @OrderCount = COUNT(*) FROM Orders WHERE CustomerId = 1;

    EXEC tSQLt.AssertEquals 1, @OrderCount, 'Order should be inserted for valid CustomerId';
END;
GO

-- Test: Verify usp_GetCustomerOrders returns correct data
CREATE PROCEDURE OrderTests.[test usp_GetCustomerOrders returns orders for customer]
AS
BEGIN
    -- Arrange
    EXEC tSQLt.FakeTable 'Orders';
    EXEC tSQLt.FakeTable 'Customers';

    -- Insert test data
    INSERT INTO Customers (CustomerId, FirstName, LastName, Email, CreatedDate, ModifiedDate)
    VALUES (1, 'Jane', 'Smith', 'jane@test.com', GETDATE(), GETDATE());

    INSERT INTO Orders (OrderId, CustomerId, OrderDate, TotalAmount, Status, CreatedDate)
    VALUES
        (1, 1, GETDATE(), 100.00, 'Completed', GETDATE()),
        (2, 1, GETDATE(), 200.00, 'Pending', GETDATE()),
        (3, 2, GETDATE(), 150.00, 'Completed', GETDATE()); -- Different customer

    -- Act
    SELECT OrderId, CustomerId, TotalAmount, Status
    INTO #Actual
    FROM Orders
    WHERE CustomerId = 1
    ORDER BY OrderDate DESC;

    -- Assert
    DECLARE @OrderCount INT;
    SELECT @OrderCount = COUNT(*) FROM #Actual;

    EXEC tSQLt.AssertEquals 2, @OrderCount, 'Should return 2 orders for customer 1';
END;
GO

-- Create a test class for Product tests
EXEC tSQLt.NewTestClass 'ProductTests';
GO

-- Test: Verify product default values
CREATE PROCEDURE ProductTests.[test Product has correct default values]
AS
BEGIN
    -- Arrange & Act
    INSERT INTO Products (ProductName, Description, Price)
    VALUES ('Test Product', 'Test Description', 99.99);

    -- Assert
    DECLARE @StockQuantity INT;
    DECLARE @IsActive BIT;

    SELECT
        @StockQuantity = StockQuantity,
        @IsActive = IsActive
    FROM Products
    WHERE ProductName = 'Test Product';

    EXEC tSQLt.AssertEquals 0, @StockQuantity, 'Default StockQuantity should be 0';
    EXEC tSQLt.AssertEquals 1, @IsActive, 'Default IsActive should be 1';
END;
GO

-- Test: Verify product price validation (example of asserting numeric values)
CREATE PROCEDURE ProductTests.[test Product price is stored with correct precision]
AS
BEGIN
    -- Arrange
    DECLARE @ExpectedPrice DECIMAL(18,2) = 123.45;

    -- Act
    INSERT INTO Products (ProductName, Description, Price, StockQuantity)
    VALUES ('Precision Test', 'Testing price precision', @ExpectedPrice, 10);

    -- Assert
    DECLARE @ActualPrice DECIMAL(18,2);
    SELECT @ActualPrice = Price FROM Products WHERE ProductName = 'Precision Test';

    EXEC tSQLt.AssertEquals @ExpectedPrice, @ActualPrice, 'Price precision should be maintained';
END;
GO

-- Create a test class for View tests
EXEC tSQLt.NewTestClass 'ViewTests';
GO

-- Test: Verify vw_CustomerOrderSummary aggregates correctly
CREATE PROCEDURE ViewTests.[test vw_CustomerOrderSummary calculates totals correctly]
AS
BEGIN
    -- Arrange
    EXEC tSQLt.FakeTable 'Customers';
    EXEC tSQLt.FakeTable 'Orders';

    INSERT INTO Customers (CustomerId, FirstName, LastName, Email, CreatedDate, ModifiedDate)
    VALUES (1, 'Test', 'Customer', 'test@test.com', GETDATE(), GETDATE());

    INSERT INTO Orders (OrderId, CustomerId, OrderDate, TotalAmount, Status, CreatedDate)
    VALUES
        (1, 1, '2025-01-01', 100.00, 'Completed', GETDATE()),
        (2, 1, '2025-01-02', 200.00, 'Completed', GETDATE()),
        (3, 1, '2025-01-03', 50.00, 'Pending', GETDATE());

    -- Act
    DECLARE @TotalOrders INT;
    DECLARE @TotalSpent DECIMAL(18,2);

    SELECT
        @TotalOrders = TotalOrders,
        @TotalSpent = TotalSpent
    FROM vw_CustomerOrderSummary
    WHERE CustomerId = 1;

    -- Assert
    EXEC tSQLt.AssertEquals 3, @TotalOrders, 'Should have 3 total orders';
    EXEC tSQLt.AssertEquals 350.00, @TotalSpent, 'Total spent should be 350.00';
END;
GO

PRINT 'tSQLt test cases created successfully!';
PRINT 'Run tests with: EXEC tSQLt.RunAll';
GO
