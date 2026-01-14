# tSQLt Tools for the AAA Pattern

## Why Use a Testing Framework?

Before frameworks like tSQLt, database unit testing was painful:

```sql
-- Without a framework:
BEGIN TRY
    BEGIN TRANSACTION;

    -- Setup
    DELETE FROM dbo.Orders WHERE OrderID = 9999;
    INSERT INTO dbo.Orders (OrderID, Amount) VALUES (9999, 100);

    -- Test
    EXEC dbo.CalculateDiscount @OrderID = 9999;

    -- Verify (manually!)
    DECLARE @Result MONEY;
    SELECT @Result = Amount FROM dbo.Orders WHERE OrderID = 9999;
    IF @Result <> 90.00
        RAISERROR('Test failed: Expected 90, got %s', 16, 1, @Result);

    ROLLBACK TRANSACTION;
    PRINT 'Test passed!';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Test failed: ' + ERROR_MESSAGE();
END CATCH
```

**Problems:**
- Lots of boilerplate code
- Manual cleanup
- No test organization
- No reporting
- Foreign key constraints block test data
- Triggers interfere with tests

## What tSQLt Provides

tSQLt is a unit testing framework for SQL Server that provides:

1. **Test organization** (test classes/schemas)
2. **Automatic transaction rollback** (cleanup)
3. **Isolation tools** (FakeTable, SpyProcedure)
4. **Assertions** (AssertEquals, AssertEqualsTable, etc.)
5. **Test runners** with reporting
6. **Exception testing** (ExpectException, ExpectNoException)

## tSQLt Tools Mapped to AAA

### Tools for ARRANGE Phase

#### `tSQLt.FakeTable`

**Purpose:** Creates an empty copy of a table without constraints, triggers, or identity properties.

**Why it's useful:**
- Removes foreign key constraints (can insert test data freely)
- Removes triggers (prevents side effects)
- Removes identity property (can specify exact IDs)
- Isolates tests from real data

```sql
-- Before: Must satisfy all constraints
INSERT INTO dbo.Orders (CustomerID, ProductID) VALUES (1, 1);
-- Error: CustomerID 1 doesn't exist in Customers table!

-- After: FakeTable removes constraints
EXEC tSQLt.FakeTable 'dbo.Orders';
INSERT INTO dbo.Orders (OrderID, CustomerID, ProductID) VALUES (1, 999, 888);
-- Works! No FK check, no identity, no triggers
```

#### `tSQLt.FakeFunction`

**Purpose:** Replaces a function with a fake that returns controlled values.

```sql
-- Original function returns current date
-- We want to test with a specific date
EXEC tSQLt.FakeFunction 'dbo.GetCurrentDate', 'dbo.FakeGetCurrentDate';

-- FakeGetCurrentDate always returns '2024-01-15'
-- Now our test is deterministic!
```

#### `tSQLt.SpyProcedure`

**Purpose:** Replaces a procedure with a "spy" that logs calls without executing.

**Why it's useful:**
- Verify a procedure was called
- Capture parameters passed to it
- Prevent side effects (email sending, external API calls)

```sql
-- We want to test OrderProcessor without actually sending emails
EXEC tSQLt.SpyProcedure 'dbo.SendOrderConfirmation';

-- Run the procedure under test
EXEC dbo.ProcessOrder @OrderID = 1;

-- Check if SendOrderConfirmation was called correctly
SELECT * FROM dbo.SendOrderConfirmation_SpyProcedureLog;
-- Shows: @OrderID = 1, @CustomerEmail = 'test@example.com'
```

#### `tSQLt.ApplyConstraint`

**Purpose:** Re-applies a specific constraint to a faked table.

**Why it's useful:** When you want most constraints removed but need to test one specific constraint.

```sql
EXEC tSQLt.FakeTable 'dbo.Orders';
-- All constraints removed

EXEC tSQLt.ApplyConstraint 'dbo.Orders', 'CK_Orders_PositiveAmount';
-- Now just the PositiveAmount check constraint is active
-- Can test that constraint specifically!
```

#### `tSQLt.ApplyTrigger`

**Purpose:** Re-applies a specific trigger to a faked table.

```sql
EXEC tSQLt.FakeTable 'dbo.Orders';
EXEC tSQLt.FakeTable 'dbo.AuditLog';

EXEC tSQLt.ApplyTrigger 'dbo.Orders', 'trg_Orders_Audit';
-- Now the audit trigger fires, but writes to faked AuditLog
```

### Tools for ACT Phase

The Act phase typically involves calling your actual code:
- `EXEC dbo.YourStoredProcedure @Param = value;`
- `SELECT dbo.YourFunction(parameters);`
- `INSERT/UPDATE/DELETE` statements that trigger behavior

**No special tSQLt tools needed** - you're testing your real code!

### Tools for ASSERT Phase

#### `tSQLt.AssertEquals`

**Purpose:** Compares two scalar values.

```sql
DECLARE @Expected INT = 100;
DECLARE @Actual INT;
SELECT @Actual = Amount FROM dbo.Orders WHERE OrderID = 1;

EXEC tSQLt.AssertEquals @Expected, @Actual, 'Amount should be 100';
```

#### `tSQLt.AssertEqualsString`

**Purpose:** Compares two string values (handles NULLs better).

```sql
EXEC tSQLt.AssertEqualsString 'Active', @Status, 'Status should be Active';
```

#### `tSQLt.AssertEqualsTable`

**Purpose:** Compares two tables row by row.

```sql
-- Create expected results table
CREATE TABLE #Expected (OrderID INT, Status NVARCHAR(20));
INSERT INTO #Expected VALUES (1, 'Shipped'), (2, 'Pending');

-- Compare with actual results
EXEC tSQLt.AssertEqualsTable '#Expected', 'dbo.Orders';
```

#### `tSQLt.AssertEmptyTable`

**Purpose:** Verifies a table has no rows.

```sql
EXEC tSQLt.AssertEmptyTable 'dbo.ErrorLog';
-- Passes if ErrorLog has 0 rows
```

#### `tSQLt.AssertObjectExists`

**Purpose:** Verifies an object (table, procedure, etc.) exists.

```sql
EXEC tSQLt.AssertObjectExists 'dbo.Orders';
```

#### `tSQLt.Fail`

**Purpose:** Forces test failure with a message.

```sql
IF @SomeCondition = 1
    EXEC tSQLt.Fail 'This condition should not occur';
```

### Exception Testing Tools

#### `tSQLt.ExpectException`

**Purpose:** Asserts that an exception will be thrown.

```sql
-- Arrange
EXEC tSQLt.FakeTable 'dbo.Orders';

-- Assert (set up expectation BEFORE act)
EXEC tSQLt.ExpectException @ExpectedMessage = 'Quantity must be positive';

-- Act
EXEC dbo.CreateOrder @ProductID = 1, @Quantity = -5;
-- Test passes if this throws 'Quantity must be positive'
```

#### `tSQLt.ExpectNoException`

**Purpose:** Asserts that no exception should be thrown.

```sql
EXEC tSQLt.ExpectNoException;

EXEC dbo.ValidateOrder @OrderID = 1;
-- Test passes if no exception is thrown
```

## Complete Example Using All Phases

```sql
CREATE PROCEDURE [TestOrderProcessing].[test_ProcessOrder_UpdatesStatusAndLogsAudit]
AS
BEGIN
    -- =============================================
    -- ARRANGE
    -- =============================================
    -- Fake the tables to isolate
    EXEC tSQLt.FakeTable 'dbo.Orders';
    EXEC tSQLt.FakeTable 'dbo.AuditLog';

    -- Re-apply the audit trigger (we want to test it fires)
    EXEC tSQLt.ApplyTrigger 'dbo.Orders', 'trg_Orders_Audit';

    -- Spy on email sending (don't actually send)
    EXEC tSQLt.SpyProcedure 'dbo.SendNotification';

    -- Insert test data
    INSERT INTO dbo.Orders (OrderID, CustomerID, Status)
    VALUES (1, 100, 'Pending');

    -- =============================================
    -- ACT
    -- =============================================
    EXEC dbo.ProcessOrder @OrderID = 1;

    -- =============================================
    -- ASSERT
    -- =============================================
    -- 1. Verify status was updated
    DECLARE @ActualStatus NVARCHAR(20);
    SELECT @ActualStatus = Status FROM dbo.Orders WHERE OrderID = 1;
    EXEC tSQLt.AssertEquals 'Processed', @ActualStatus;

    -- 2. Verify audit log was written (trigger fired)
    DECLARE @AuditCount INT;
    SELECT @AuditCount = COUNT(*) FROM dbo.AuditLog WHERE OrderID = 1;
    EXEC tSQLt.AssertEquals 1, @AuditCount, 'Should have 1 audit entry';

    -- 3. Verify notification was called
    DECLARE @NotificationCount INT;
    SELECT @NotificationCount = COUNT(*)
    FROM dbo.SendNotification_SpyProcedureLog;
    EXEC tSQLt.AssertEquals 1, @NotificationCount, 'Should send 1 notification';
END;
```

## Summary: Tools by Phase

| Phase | Tool | Purpose |
|-------|------|---------|
| **Arrange** | `FakeTable` | Isolate from constraints/triggers |
| **Arrange** | `FakeFunction` | Control function return values |
| **Arrange** | `SpyProcedure` | Monitor procedure calls |
| **Arrange** | `ApplyConstraint` | Re-enable specific constraints |
| **Arrange** | `ApplyTrigger` | Re-enable specific triggers |
| **Assert** | `AssertEquals` | Compare scalar values |
| **Assert** | `AssertEqualsString` | Compare strings |
| **Assert** | `AssertEqualsTable` | Compare table contents |
| **Assert** | `AssertEmptyTable` | Verify table is empty |
| **Assert** | `ExpectException` | Verify exception is thrown |
| **Assert** | `ExpectNoException` | Verify no exception |
| **Assert** | `Fail` | Force test failure |

## Why This Matters

Without tSQLt, you would need to:
- Manually manage transactions
- Write complex cleanup scripts
- Build your own assertion logic
- Handle constraint violations manually
- Create your own test runners

**tSQLt handles all of this**, letting you focus on writing meaningful tests.
