# tSQLt Core Framework Skill

Core knowledge for creating unit tests with the tSQLt framework. This skill is **generic** and can be used with any SQL Server project.

## Quick Reference

| Feature | Syntax |
|---------|--------|
| Create test class | `EXEC tSQLt.NewTestClass 'ClassName'` |
| Fake table | `EXEC tSQLt.FakeTable 'schema.TableName'` |
| Spy procedure | `EXEC tSQLt.SpyProcedure 'schema.ProcName'` |
| Run all tests | `EXEC tSQLt.RunAll` |
| Run specific class | `EXEC tSQLt.Run 'ClassName'` |
| Run single test | `EXEC tSQLt.Run 'ClassName.test_Name'` |

## Official Documentation

- Main site: https://tsqlt.org/
- Test creation: https://tsqlt.org/user-guide/test-creation-and-execution/
- Assertions: https://tsqlt.org/user-guide/assertions/
- Isolating dependencies: https://tsqlt.org/user-guide/isolating-dependencies/

---

## Test Structure (AAA Pattern)

Every test follows **Arrange-Act-Assert**:

```sql
CREATE OR ALTER PROCEDURE [TestClass].[test_Description]
AS
BEGIN
    SET NOCOUNT ON;

    --========================================
    -- ARRANGE - Setup test data
    --========================================

    -- Fake tables to isolate from real data
    EXEC tSQLt.FakeTable 'schema.TableName';

    -- Insert test data
    INSERT INTO schema.TableName (Col1, Col2)
    VALUES ('value1', 'value2');

    -- Declare expected results
    DECLARE @Expected INT = 1;

    --========================================
    -- ACT - Execute the code under test
    --========================================

    DECLARE @Actual INT;
    EXEC @Actual = schema.usp_ProcedureUnderTest @Param = 'value';

    --========================================
    -- ASSERT - Verify results
    --========================================

    EXEC tSQLt.AssertEquals @Expected, @Actual, 'Description of what failed';
END
```

---

## Assertions

### Value Comparisons

```sql
-- Exact equality
EXEC tSQLt.AssertEquals @Expected = 'value', @Actual = @variable,
    @Message = 'Values should match';

-- Not equal
EXEC tSQLt.AssertNotEquals @Expected = 'value', @Actual = @variable,
    @Message = 'Values should differ';

-- Pattern matching (LIKE)
EXEC tSQLt.AssertLike @ExpectedPattern = '%pattern%', @Actual = @variable,
    @Message = 'Should match pattern';

-- Object exists
EXEC tSQLt.AssertObjectExists 'schema.ObjectName',
    @Message = 'Object should exist';

-- Object does not exist
EXEC tSQLt.AssertObjectDoesNotExist 'schema.ObjectName';
```

### Table Comparisons

```sql
-- Compare two tables (most common)
EXEC tSQLt.AssertEqualsTable
    @Expected = '#ExpectedTable',
    @Actual = '#ActualTable',
    @Message = 'Tables should match';

-- Compare with column exclusion
EXEC tSQLt.AssertEqualsTable
    @Expected = '#Expected',
    @Actual = '#Actual',
    @FailMsg = 'Mismatch',
    @ExcludeColumn = 'CreatedDate,ModifiedDate';  -- Ignore these columns

-- Assert table is empty
EXEC tSQLt.AssertEmptyTable 'schema.TableName';

-- Assert row count
DECLARE @Count INT = (SELECT COUNT(*) FROM schema.TableName);
EXEC tSQLt.AssertEquals 5, @Count, 'Should have 5 rows';
```

### Exception Testing

```sql
-- Expect specific exception
EXEC tSQLt.ExpectException @ExpectedMessage = 'Error message text';

-- Then call code that should throw
EXEC schema.usp_ProcedureThatThrows;

-- Expect exception with pattern
EXEC tSQLt.ExpectException @ExpectedMessagePattern = '%constraint%';

-- Expect no exception (implicit - test fails if exception occurs)
```

---

## Isolation Techniques

### FakeTable

Replaces table with empty version, removing constraints and triggers:

```sql
-- Basic fake
EXEC tSQLt.FakeTable 'schema.TableName';

-- Fake with identity preserved (auto-increment works)
EXEC tSQLt.FakeTable 'schema.TableName', @Identity = 1;

-- Fake with computed columns preserved
EXEC tSQLt.FakeTable 'schema.TableName', @ComputedColumns = 1;

-- Fake with defaults preserved
EXEC tSQLt.FakeTable 'schema.TableName', @Defaults = 1;
```

### SpyProcedure

Replaces procedure with logging version:

```sql
-- Spy on procedure
EXEC tSQLt.SpyProcedure 'schema.usp_SendEmail';

-- Call code that uses the procedure
EXEC schema.usp_ProcessOrder @OrderId = 1;

-- Verify procedure was called with expected params
SELECT _id_, @To, @Subject, @Body
FROM schema.usp_SendEmail_SpyProcedureLog;
```

### FakeFunction

```sql
-- Replace scalar function with fake
EXEC tSQLt.FakeFunction 'schema.fn_GetCurrentDate', 'schema.fn_FakeDate';

-- Your fake function returns controlled value
CREATE FUNCTION schema.fn_FakeDate() RETURNS DATETIME
AS BEGIN RETURN '2025-01-01' END;
```

### ApplyConstraint

Re-enable specific constraint after FakeTable:

```sql
EXEC tSQLt.FakeTable 'schema.Orders';
EXEC tSQLt.FakeTable 'schema.Customers';

-- Re-enable just the FK we want to test
EXEC tSQLt.ApplyConstraint 'schema.Orders', 'FK_Orders_Customers';

-- Now FK is enforced, other constraints still disabled
```

---

## Test Naming Conventions

### Recommended Format
```
test_<Entity>_<Scenario>_<ExpectedOutcome>
```

### Examples
```sql
test_Customer_ValidEmail_ShouldInsert
test_Customer_DuplicateEmail_ShouldFail
test_Order_ZeroQuantity_ShouldReject
test_CalculateTotal_WithDiscount_ReturnsDiscountedPrice
test_GetOrders_ForInactiveCustomer_ReturnsEmpty
```

---

## Common Patterns

### Testing Stored Procedure Output

```sql
CREATE PROCEDURE [Tests].[test_usp_GetTotal_CalculatesCorrectly]
AS
BEGIN
    -- Arrange
    EXEC tSQLt.FakeTable 'dbo.OrderItems';
    INSERT INTO dbo.OrderItems (OrderId, Price, Quantity)
    VALUES (1, 10.00, 3), (1, 5.00, 2);

    -- Act
    DECLARE @Total DECIMAL(18,2);
    EXEC dbo.usp_GetOrderTotal @OrderId = 1, @Total = @Total OUTPUT;

    -- Assert
    EXEC tSQLt.AssertEquals 40.00, @Total, 'Total should be (10*3)+(5*2)=40';
END
```

### Testing Result Sets

```sql
CREATE PROCEDURE [Tests].[test_usp_GetActiveUsers_ReturnsOnlyActive]
AS
BEGIN
    -- Arrange
    EXEC tSQLt.FakeTable 'dbo.Users';
    INSERT INTO dbo.Users (UserId, Name, IsActive)
    VALUES (1, 'Active User', 1), (2, 'Inactive User', 0);

    CREATE TABLE #Expected (UserId INT, Name NVARCHAR(100));
    INSERT INTO #Expected VALUES (1, 'Active User');

    CREATE TABLE #Actual (UserId INT, Name NVARCHAR(100));

    -- Act
    INSERT INTO #Actual
    EXEC dbo.usp_GetActiveUsers;

    -- Assert
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END
```

### Testing Triggers

```sql
CREATE PROCEDURE [Tests].[test_AuditTrigger_LogsInsert]
AS
BEGIN
    -- Arrange
    EXEC tSQLt.FakeTable 'dbo.Orders';
    EXEC tSQLt.FakeTable 'dbo.AuditLog';

    -- Apply the trigger we're testing
    EXEC tSQLt.ApplyTrigger 'dbo.Orders', 'TR_Orders_Audit';

    -- Act
    INSERT INTO dbo.Orders (OrderId, CustomerId) VALUES (1, 100);

    -- Assert
    DECLARE @LogCount INT = (SELECT COUNT(*) FROM dbo.AuditLog);
    EXEC tSQLt.AssertEquals 1, @LogCount, 'Trigger should create audit log';
END
```

### Testing with Transactions

```sql
CREATE PROCEDURE [Tests].[test_Transfer_RollsBackOnError]
AS
BEGIN
    -- Arrange
    EXEC tSQLt.FakeTable 'dbo.Accounts';
    INSERT INTO dbo.Accounts (AccountId, Balance)
    VALUES (1, 100.00), (2, 50.00);

    DECLARE @InitialBalance1 DECIMAL = 100.00;
    DECLARE @InitialBalance2 DECIMAL = 50.00;

    -- Act - Transfer more than available (should fail)
    BEGIN TRY
        EXEC dbo.usp_Transfer @From = 1, @To = 2, @Amount = 150.00;
    END TRY
    BEGIN CATCH
        -- Expected to fail
    END CATCH

    -- Assert - Balances should be unchanged
    DECLARE @Balance1 DECIMAL = (SELECT Balance FROM dbo.Accounts WHERE AccountId = 1);
    EXEC tSQLt.AssertEquals @InitialBalance1, @Balance1, 'Balance should be unchanged after failed transfer';
END
```

---

## Test Organization

### One Test Class Per Entity/Feature

```
TestClasses/
├── CustomerTests
│   ├── test_Customer_Insert_ValidData_Succeeds
│   ├── test_Customer_Insert_DuplicateEmail_Fails
│   └── test_Customer_Update_ChangesModifiedDate
│
├── OrderTests
│   ├── test_Order_Create_SetsDefaultStatus
│   └── test_Order_Cancel_UpdatesInventory
│
└── ReportTests
    ├── test_SalesReport_DateRange_FiltersCorrectly
    └── test_SalesReport_GroupBy_AggregatesCorrectly
```

### Test File Naming

```
test_<Entity>_<Scenario>_<ExpectedOutcome>.sql
```

---

## Debugging Failed Tests

### View Test Results

```sql
-- Run tests and see results
EXEC tSQLt.RunAll;

-- View detailed results
SELECT * FROM tSQLt.TestResult ORDER BY Result DESC;

-- View only failures
SELECT TestCase, Msg
FROM tSQLt.TestResult
WHERE Result = 'Failure';
```

### Common Issues

1. **Fake table doesn't have expected columns** - Check schema name is correct
2. **Identity issues** - Use `@Identity = 1` with FakeTable
3. **Computed column errors** - Use `@ComputedColumns = 1` with FakeTable
4. **Test pollution** - Each test runs in transaction that's rolled back

---

## Version Compatibility

| tSQLt Version | SQL Server Versions |
|---------------|---------------------|
| 1.0.8053+ | SQL Server 2012+ |
| 1.0.7xxx | SQL Server 2008 R2+ |

## Installation

```sql
-- 1. Enable CLR
EXEC sp_configure 'clr enabled', 1;
RECONFIGURE;

-- 2. Set database trustworthy (or sign assemblies)
ALTER DATABASE YourDatabase SET TRUSTWORTHY ON;

-- 3. Run tSQLt.class.sql
-- Download from https://tsqlt.org/downloads/
```
