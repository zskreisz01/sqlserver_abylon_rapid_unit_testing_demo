#!/bin/bash
# Deploy tSQLt Tests to SQL Server Test Instance

set -e

echo "================================================"
echo "Deploying tSQLt Tests"
echo "================================================"
echo ""

TEST_CONTAINER="sqlserver2025-test"
TEST_DB="SampleDatabase_Test"
SA_PASSWORD="YourStrong@Passw0rd"

# Create test classes
echo "[1/3] Creating test classes..."
docker exec $TEST_CONTAINER /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$SA_PASSWORD" -d $TEST_DB -C -Q "
EXEC tSQLt.NewTestClass 'CustomerTests';
EXEC tSQLt.NewTestClass 'OrderTests';
EXEC tSQLt.NewTestClass 'ProductTests';
EXEC tSQLt.NewTestClass 'ViewTests';
PRINT 'Test classes created';
"
echo "✓ Test classes created"
echo ""

# Create Customer Tests
echo "[2/3] Creating test procedures..."
docker exec $TEST_CONTAINER /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$SA_PASSWORD" -d $TEST_DB -C -Q "
-- Test: Customer insertion
CREATE PROCEDURE CustomerTests.[test Customer insertion creates record with all fields]
AS
BEGIN
    DECLARE @CustomerId INT;
    DECLARE @ExpectedFirstName NVARCHAR(50) = 'John';
    DECLARE @ExpectedLastName NVARCHAR(50) = 'Doe';
    DECLARE @ExpectedEmail NVARCHAR(100) = 'john.doe@test.com';

    EXEC usp_AddCustomer
        @FirstName = @ExpectedFirstName,
        @LastName = @ExpectedLastName,
        @Email = @ExpectedEmail,
        @PhoneNumber = '555-1234',
        @CustomerId = @CustomerId OUTPUT;

    DECLARE @ActualFirstName NVARCHAR(50), @ActualLastName NVARCHAR(50), @ActualEmail NVARCHAR(100);
    SELECT @ActualFirstName = FirstName, @ActualLastName = LastName, @ActualEmail = Email
    FROM Customers WHERE CustomerId = @CustomerId;

    EXEC tSQLt.AssertEquals @ExpectedFirstName, @ActualFirstName;
    EXEC tSQLt.AssertEquals @ExpectedLastName, @ActualLastName;
    EXEC tSQLt.AssertEquals @ExpectedEmail, @ActualEmail;
END;
GO

-- Test: Product default values
CREATE PROCEDURE ProductTests.[test Product has correct default values]
AS
BEGIN
    INSERT INTO Products (ProductName, Description, Price)
    VALUES ('Test Product', 'Test Description', 99.99);

    DECLARE @StockQuantity INT, @IsActive BIT;
    SELECT @StockQuantity = StockQuantity, @IsActive = IsActive
    FROM Products WHERE ProductName = 'Test Product';

    EXEC tSQLt.AssertEquals 0, @StockQuantity;
    EXEC tSQLt.AssertEquals 1, @IsActive;
END;
GO

-- Test: View aggregation
CREATE PROCEDURE ViewTests.[test vw_CustomerOrderSummary calculates totals correctly]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Customers';
    EXEC tSQLt.FakeTable 'Orders';

    INSERT INTO Customers (CustomerId, FirstName, LastName, Email, CreatedDate, ModifiedDate)
    VALUES (99, 'Test', 'Customer', 'test@test.com', GETDATE(), GETDATE());

    INSERT INTO Orders (OrderId, CustomerId, OrderDate, TotalAmount, Status, CreatedDate)
    VALUES
        (101, 99, '2025-01-01', 100.00, 'Completed', GETDATE()),
        (102, 99, '2025-01-02', 200.00, 'Completed', GETDATE()),
        (103, 99, '2025-01-03', 50.00, 'Pending', GETDATE());

    DECLARE @TotalOrders INT, @TotalSpent DECIMAL(18,2);
    SELECT @TotalOrders = TotalOrders, @TotalSpent = TotalSpent
    FROM vw_CustomerOrderSummary WHERE CustomerId = 99;

    EXEC tSQLt.AssertEquals 3, @TotalOrders;
    EXEC tSQLt.AssertEquals 350.00, @TotalSpent;
END;
GO

PRINT 'Test procedures created successfully';
"
echo "✓ Test procedures created"
echo ""

echo "[3/3] Listing all tests..."
docker exec $TEST_CONTAINER /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$SA_PASSWORD" -d $TEST_DB -C -Q "
SELECT
    SCHEMA_NAME(schema_id) + '.[' + name + ']' AS TestName
FROM sys.objects
WHERE type = 'P'
    AND SCHEMA_NAME(schema_id) IN ('CustomerTests', 'OrderTests', 'ProductTests', 'ViewTests')
ORDER BY SCHEMA_NAME(schema_id), name;
"

echo ""
echo "================================================"
echo "✓ tSQLt tests deployed successfully!"
echo "================================================"
echo ""
echo "To run all tests: ./run-tsqlt-tests.sh"
echo ""
