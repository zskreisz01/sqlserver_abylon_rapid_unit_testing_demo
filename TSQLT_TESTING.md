# tSQLt Unit Testing Guide

This document describes the tSQLt unit testing framework setup for the SQL Server 2025 test environment.

## Overview

tSQLt is a unit testing framework for SQL Server that allows you to write and execute automated unit tests for database objects. This project includes a separate test environment with tSQLt installed.

## Test Environment

### Architecture

- **Production Server**: `sqlserver2025` on port 1433
- **Test Server**: `sqlserver2025-test` on port 1434
- **Test Database**: `SampleDatabase_Test`
- **tSQLt Version**: 1.0.8083.3529

### Connection Details

```
Host: localhost
Port: 1434
Database: SampleDatabase_Test
Username: SA
Password: YourStrong@Passw0rd
```

## Starting the Test Environment

```bash
# Start only the test server
docker-compose up -d sqlserver-test

# Or start both servers
docker-compose up -d
```

## tSQLt Installation

The tSQLt framework is installed with CLR enabled for Linux/Docker compatibility.

### Key Configuration

- **CLR Enabled**: Required for tSQLt assemblies
- **CLR Strict Security**: Disabled (required for Linux containers)
- **Permission Set**: Modified to `SAFE` for Docker compatibility

### Installation Files

- `tsqlt-framework/tSQLt_V1/PrepareServer.sql` - Server preparation script
- `tsqlt-framework/tSQLt_V1/tSQLt.class.docker.sql` - Modified tSQLt framework for Docker

## Running Tests

### Quick Start

```bash
# Deploy test cases
./deploy-tsqlt-tests.sh

# Run all tests
./run-tsqlt-tests.sh
```

### Manual Test Execution

```bash
# Run all tests
docker exec sqlserver2025-test /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -d SampleDatabase_Test -C -Q "EXEC tSQLt.RunAll;"

# Run specific test class
docker exec sqlserver2025-test /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -d SampleDatabase_Test -C -Q "EXEC tSQLt.Run 'CustomerTests';"

# Run specific test
docker exec sqlserver2025-test /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -d SampleDatabase_Test -C -Q "EXEC tSQLt.Run 'CustomerTests.[test Customer insertion creates record with all fields]';"
```

## Test Structure

### Test Classes

Tests are organized into test classes (schemas):

- **CustomerTests**: Tests for customer-related functionality
- **ProductTests**: Tests for product-related functionality
- **OrderTests**: Tests for order-related functionality
- **ViewTests**: Tests for database views

### Creating a New Test Class

```sql
EXEC tSQLt.NewTestClass 'MyTestClass';
```

### Creating a Test Procedure

```sql
CREATE PROCEDURE MyTestClass.[test my feature works correctly]
AS
BEGIN
    -- Arrange
    DECLARE @Expected INT = 5;

    -- Act
    DECLARE @Actual INT = (SELECT COUNT(*) FROM SomeTable);

    -- Assert
    EXEC tSQLt.AssertEquals @Expected, @Actual, 'Count should match';
END;
```

## Example Tests

### Test 1: Customer Insertion

```sql
CREATE PROCEDURE CustomerTests.[test Customer insertion creates record with all fields]
AS
BEGIN
    DECLARE @CustomerId INT;

    EXEC usp_AddCustomer
        @FirstName = 'John',
        @LastName = 'Doe',
        @Email = 'john.doe@test.com',
        @PhoneNumber = '555-1234',
        @CustomerId = @CustomerId OUTPUT;

    DECLARE @ActualFirstName NVARCHAR(50);
    SELECT @ActualFirstName = FirstName FROM Customers WHERE CustomerId = @CustomerId;

    EXEC tSQLt.AssertEquals 'John', @ActualFirstName;
END;
```

### Test 2: Product Default Values

```sql
CREATE PROCEDURE ProductTests.[test Product has correct default values]
AS
BEGIN
    INSERT INTO Products (ProductName, Description, Price)
    VALUES ('Test Product', 'Test Description', 99.99);

    DECLARE @StockQuantity INT;
    SELECT @StockQuantity = StockQuantity FROM Products WHERE ProductName = 'Test Product';

    EXEC tSQLt.AssertEquals 0, @StockQuantity;
END;
```

### Test 3: View Aggregation

```sql
CREATE PROCEDURE ViewTests.[test vw_CustomerOrderSummary calculates totals correctly]
AS
BEGIN
    -- Use FakeTable to isolate test data
    EXEC tSQLt.FakeTable 'Customers';
    EXEC tSQLt.FakeTable 'Orders';

    -- Insert test data
    INSERT INTO Customers VALUES (1, 'Test', 'Customer', 'test@test.com', GETDATE(), GETDATE());
    INSERT INTO Orders VALUES (1, 1, GETDATE(), 100.00, 'Completed', NULL, GETDATE());
    INSERT INTO Orders VALUES (2, 1, GETDATE(), 200.00, 'Completed', NULL, GETDATE());

    -- Assert
    DECLARE @TotalSpent DECIMAL(18,2);
    SELECT @TotalSpent = TotalSpent FROM vw_CustomerOrderSummary WHERE CustomerId = 1;

    EXEC tSQLt.AssertEquals 300.00, @TotalSpent;
END;
```

## tSQLt Assertions

Common assertion procedures:

- `tSQLt.AssertEquals @Expected, @Actual, [@Message]`
- `tSQLt.AssertNotEquals @Expected, @Actual, [@Message]`
- `tSQLt.AssertLike @ExpectedPattern, @Actual, [@Message]`
- `tSQLt.AssertEmptyTable @TableName, [@Message]`
- `tSQLt.AssertEqualsTable @Expected, @Actual, [@Message]`
- `tSQLt.AssertEqualsString @Expected, @Actual, [@Message]`
- `tSQLt.Fail [@Message]`

## Test Isolation

### FakeTable

Use `tSQLt.FakeTable` to create an isolated copy of a table:

```sql
EXEC tSQLt.FakeTable 'dbo.Customers';
-- Now you can insert test data without affecting real data
```

### SpyProcedure

Use `tSQLt.SpyProcedure` to intercept procedure calls:

```sql
EXEC tSQLt.SpyProcedure 'dbo.usp_SendEmail';
-- Procedure calls are logged, not executed
```

### ApplyConstraint

Reapply specific constraints to fake tables:

```sql
EXEC tSQLt.ApplyConstraint 'dbo.Orders', 'FK_Orders_Customers';
```

## Test Results

### Viewing Results

```sql
-- View all test results
SELECT Class, TestCase, Result, Msg
FROM tSQLt.TestResult
ORDER BY Class, TestCase;

-- View failed tests only
SELECT Class, TestCase, Msg
FROM tSQLt.TestResult
WHERE Result = 'Failure';
```

### Test Output Example

```
+----------------------+
|Test Execution Summary|
+----------------------+

|No|Test Case Name                                    |Dur(ms)|Result |
+--+--------------------------------------------------+-------+-------+
|1 |[CustomerTests].[test Customer insertion...]      |    150|Success|
|2 |[ProductTests].[test Product has correct...]      |     14|Success|
|3 |[ViewTests].[test vw_CustomerOrderSummary...]     |   1349|Success|
--------------------------------------------------------------------------------
Test Case Summary: 3 test case(s) executed, 3 succeeded, 0 skipped, 0 failed, 0 errored.
--------------------------------------------------------------------------------
```

## Continuous Integration

### GitHub Actions Example

```yaml
name: Run tSQLt Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Start SQL Server Test Container
        run: docker-compose up -d sqlserver-test

      - name: Wait for SQL Server
        run: sleep 30

      - name: Deploy Database
        run: |
          cd SampleDatabase
          dotnet build
          sqlpackage /Action:Publish /SourceFile:bin/Debug/SampleDatabase.dacpac \
            /TargetConnectionString:"Server=localhost,1434;Database=SampleDatabase_Test;..."

      - name: Run Tests
        run: ./run-tsqlt-tests.sh
```

## Troubleshooting

### CLR Not Enabled

If tests fail with CLR errors:

```sql
EXEC sp_configure 'clr enabled', 1;
RECONFIGURE;
EXEC sp_configure 'clr strict security', 0;
RECONFIGURE;
```

### Permission Issues

Ensure the SA account is used for test execution in Docker environments.

### Assembly Loading Errors

If you see assembly loading errors, verify the tSQLt installation:

```sql
SELECT name, permission_set_desc
FROM sys.assemblies
WHERE name LIKE '%tSQLt%';
```

## Best Practices

1. **Test Isolation**: Always use `tSQLt.FakeTable` to isolate test data
2. **Clear Test Names**: Use descriptive test names that explain what is being tested
3. **Arrange-Act-Assert**: Follow the AAA pattern in test procedures
4. **One Assert Per Test**: Each test should verify one specific behavior
5. **Clean Test Data**: Don't rely on existing data; create what you need
6. **Fast Tests**: Keep tests fast by minimizing database operations
7. **Independent Tests**: Tests should not depend on each other's execution order

## References

- [tSQLt Official Website](https://tsqlt.org/)
- [tSQLt GitHub Repository](https://github.com/tSQLt-org/tSQLt)
- [tSQLt User Guide](https://tsqlt.org/user-guide/)
- [SQL Server Unit Testing with tSQLt](https://www.sqlservercentral.com/blogs/how-to-use-tsqlt-unit-test-framework-with-a-sql-server-database-in-a-docker-container)
