# The AAA Pattern: Arrange, Act, Assert

## What is AAA?

The AAA pattern (Arrange-Act-Assert) is a standard structure for writing clear, maintainable unit tests. It divides each test into three distinct phases:

```
┌─────────────────────────────────────────────────────────────┐
│                         TEST                                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐                                           │
│  │   ARRANGE   │  Set up the test conditions               │
│  └─────────────┘                                           │
│         ↓                                                   │
│  ┌─────────────┐                                           │
│  │     ACT     │  Execute the code under test              │
│  └─────────────┘                                           │
│         ↓                                                   │
│  ┌─────────────┐                                           │
│  │   ASSERT    │  Verify the expected outcome              │
│  └─────────────┘                                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## The Three Phases Explained

### 1. Arrange

**Purpose:** Set up everything needed for the test

**Activities:**
- Create test data
- Configure mocks/fakes
- Initialize objects
- Set preconditions

**In Database Testing:**
- Insert test records
- Fake tables to isolate dependencies
- Set up spy procedures
- Configure expected exceptions

```sql
-- ARRANGE
EXEC tSQLt.FakeTable 'dbo.Orders';
EXEC tSQLt.FakeTable 'dbo.OrderItems';

INSERT INTO dbo.Orders (OrderID, CustomerID, OrderDate)
VALUES (1, 100, '2024-01-15');

INSERT INTO dbo.OrderItems (OrderID, ProductID, Quantity, UnitPrice)
VALUES (1, 10, 2, 25.00),
       (1, 20, 1, 50.00);
```

### 2. Act

**Purpose:** Execute the specific behavior being tested

**Characteristics:**
- Usually a single line or statement
- Calls the code under test
- Should be clearly identifiable

**In Database Testing:**
- Execute a stored procedure
- Run a function
- Perform an INSERT/UPDATE/DELETE that triggers behavior

```sql
-- ACT
EXEC dbo.CalculateOrderTotal @OrderID = 1;
```

### 3. Assert

**Purpose:** Verify that the expected outcome occurred

**Activities:**
- Check return values
- Verify state changes
- Confirm expected side effects
- Validate exceptions were thrown

**In Database Testing:**
- Compare actual vs. expected values
- Check table contents
- Verify row counts
- Confirm exceptions

```sql
-- ASSERT
DECLARE @ActualTotal MONEY;
SELECT @ActualTotal = TotalAmount FROM dbo.Orders WHERE OrderID = 1;

EXEC tSQLt.AssertEquals 100.00, @ActualTotal, 'Order total should be 100.00';
```

## Complete Example in tSQLt

```sql
CREATE PROCEDURE [TestOrderCalculations].[test_CalculateOrderTotal_SumsItemsCorrectly]
AS
BEGIN
    -- =============================================
    -- ARRANGE: Set up test conditions
    -- =============================================
    -- Fake the tables to isolate from real data
    EXEC tSQLt.FakeTable 'dbo.Orders';
    EXEC tSQLt.FakeTable 'dbo.OrderItems';

    -- Insert test order
    INSERT INTO dbo.Orders (OrderID, CustomerID, OrderDate, TotalAmount)
    VALUES (1, 100, '2024-01-15', 0.00);

    -- Insert test items: 2 x $25 + 1 x $50 = $100
    INSERT INTO dbo.OrderItems (OrderID, ProductID, Quantity, UnitPrice)
    VALUES (1, 10, 2, 25.00),  -- $50
           (1, 20, 1, 50.00);  -- $50
                               -- Total: $100

    -- =============================================
    -- ACT: Execute the code under test
    -- =============================================
    EXEC dbo.CalculateOrderTotal @OrderID = 1;

    -- =============================================
    -- ASSERT: Verify the expected outcome
    -- =============================================
    DECLARE @ActualTotal MONEY;
    SELECT @ActualTotal = TotalAmount FROM dbo.Orders WHERE OrderID = 1;

    EXEC tSQLt.AssertEquals 100.00, @ActualTotal,
        'Order total should equal sum of (Quantity * UnitPrice) for all items';
END;
```

## Why AAA Matters

### 1. Readability

Anyone reading the test can immediately understand:
- What conditions are being tested (Arrange)
- What action is performed (Act)
- What outcome is expected (Assert)

### 2. Maintainability

When a test fails:
- Check Assert to understand what was expected
- Check Act to see what was executed
- Check Arrange to verify the setup

### 3. Focus

Forces you to:
- Set up only what's needed
- Test one specific behavior
- Verify specific outcomes

## Common Anti-Patterns

### Anti-Pattern 1: Multiple Acts

```sql
-- BAD: Testing multiple things
CREATE PROCEDURE [Test].[test_OrderWorkflow]
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo.Orders';

    -- ACT 1
    EXEC dbo.CreateOrder @CustomerID = 1;
    EXEC tSQLt.AssertEquals 1, (SELECT COUNT(*) FROM dbo.Orders);

    -- ACT 2 - This should be a separate test!
    EXEC dbo.CancelOrder @OrderID = 1;
    EXEC tSQLt.AssertEquals 'Cancelled', (SELECT Status FROM dbo.Orders);
END;
```

**Solution:** Split into separate tests, each with one Act.

### Anti-Pattern 2: Assert in Arrange

```sql
-- BAD: Asserting during setup
CREATE PROCEDURE [Test].[test_Something]
AS
BEGIN
    -- Arrange
    EXEC tSQLt.FakeTable 'dbo.Orders';
    INSERT INTO dbo.Orders (OrderID) VALUES (1);
    -- This assertion is part of ARRANGE, not ASSERT!
    EXEC tSQLt.AssertEquals 1, (SELECT COUNT(*) FROM dbo.Orders);

    -- Act
    EXEC dbo.SomeProc;

    -- Assert
    ...
END;
```

**Solution:** Only assert after the Act phase. Trust your setup.

### Anti-Pattern 3: No Clear Separation

```sql
-- BAD: Phases are mixed together
CREATE PROCEDURE [Test].[test_Messy]
AS
BEGIN
    INSERT INTO dbo.Orders (OrderID) VALUES (1);
    EXEC dbo.ProcessOrder @OrderID = 1;
    INSERT INTO dbo.AuditLog (Message) VALUES ('Test');
    EXEC tSQLt.AssertEquals 'Processed', (SELECT Status FROM dbo.Orders);
    EXEC dbo.CompleteOrder @OrderID = 1;
END;
```

**Solution:** Clearly separate and comment each phase.

## AAA Variations

### Given-When-Then (BDD Style)

Same concept, different terminology:
- **Given** = Arrange (the context)
- **When** = Act (the action)
- **Then** = Assert (the outcome)

```sql
-- Given an order with two items
-- When the total is calculated
-- Then the total equals the sum of item prices
```

### Setup-Exercise-Verify

Another common naming:
- **Setup** = Arrange
- **Exercise** = Act
- **Verify** = Assert

## Summary

| Phase | Purpose | Key Question |
|-------|---------|--------------|
| **Arrange** | Set up conditions | What state is needed? |
| **Act** | Execute behavior | What action triggers the behavior? |
| **Assert** | Verify outcome | What should happen? |

The AAA pattern is simple but powerful. It creates consistent, readable tests that clearly communicate intent and make failures easy to diagnose.
