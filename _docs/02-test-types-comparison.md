# Test Types: Understanding the Differences

## The Testing Pyramid

Testing is typically organized in a pyramid structure, with more tests at the bottom (faster, cheaper) and fewer at the top (slower, more expensive):

```
        /\
       /  \
      / E2E \        ← Few, slow, expensive
     /--------\
    /Integration\    ← Some, medium speed
   /--------------\
  /   Unit Tests   \ ← Many, fast, cheap
 /------------------\
```

## Test Types Explained

### 1. Unit Tests

**What they test:** Individual components in complete isolation

**Characteristics:**
- Test a single function, method, or stored procedure
- Dependencies are mocked or faked
- Execute in milliseconds
- Run frequently (on every save/commit)

**Example scenarios:**
- Does this function calculate tax correctly?
- Does this stored procedure validate input parameters?
- Does this trigger fire under the right conditions?

**In SQL Server:**
```sql
-- Testing a single stored procedure in isolation
-- Other tables are faked, focus is on THIS procedure's logic
CREATE PROCEDURE [TestOrderValidation].[test_RejectsNegativeQuantity]
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo.Orders';

    EXEC tSQLt.ExpectException @ExpectedMessage = 'Quantity must be positive';

    EXEC dbo.CreateOrder @ProductID = 1, @Quantity = -5;
END
```

### 2. Integration Tests

**What they test:** How multiple components work together

**Characteristics:**
- Test interactions between 2+ components
- May use real dependencies (databases, APIs)
- Execute in seconds to minutes
- Run less frequently (before commits, in CI/CD)

**Example scenarios:**
- Does the API correctly save data to the database?
- Do these three stored procedures work together correctly?
- Does the application connect to the database properly?

**In SQL Server:**
```sql
-- Testing that multiple procedures work together
-- Uses real tables, tests the full workflow
CREATE PROCEDURE [TestOrderWorkflow].[test_CompleteOrderProcess]
AS
BEGIN
    -- Insert real data
    INSERT INTO dbo.Customers (Name) VALUES ('Test Customer');

    -- Test the full order workflow
    EXEC dbo.CreateOrder @CustomerID = 1, @ProductID = 5;
    EXEC dbo.ProcessPayment @OrderID = 1;
    EXEC dbo.ShipOrder @OrderID = 1;

    -- Verify the entire workflow succeeded
    DECLARE @Status NVARCHAR(50);
    SELECT @Status = Status FROM dbo.Orders WHERE OrderID = 1;

    EXEC tSQLt.AssertEquals 'Shipped', @Status;
END
```

### 3. End-to-End (E2E) Tests

**What they test:** Complete user workflows through the entire system

**Characteristics:**
- Test from user interface to database and back
- Use real environments (or production-like)
- Execute in minutes
- Run infrequently (nightly, before releases)

**Example scenarios:**
- Can a user register, login, and place an order?
- Does the checkout process work from cart to confirmation?
- Can an admin generate and download reports?

### 4. Smoke Tests

**What they test:** Basic functionality after deployment

**Characteristics:**
- Quick sanity checks
- Verify system is operational
- Run after every deployment

**Example scenarios:**
- Does the application start?
- Can we connect to the database?
- Do the main pages load?

### 5. Regression Tests

**What they test:** Previously working functionality

**Characteristics:**
- Ensure bug fixes stay fixed
- Verify new changes don't break existing features
- Often automated unit/integration tests

**Example scenarios:**
- Did fixing bug #123 break feature X?
- Does the new module affect existing functionality?

### 6. Performance Tests

**What they test:** Speed, scalability, and resource usage

**Characteristics:**
- Measure response times
- Test under load
- Identify bottlenecks

**Example scenarios:**
- Can the system handle 1000 concurrent users?
- Does this query complete in under 100ms?
- How much memory does this process use?

## Comparison Table

| Test Type | Scope | Speed | Frequency | Cost to Maintain |
|-----------|-------|-------|-----------|------------------|
| Unit | Single component | Milliseconds | Every change | Low |
| Integration | Multiple components | Seconds | Before commit | Medium |
| E2E | Entire system | Minutes | Daily/Release | High |
| Smoke | Critical paths | Seconds | Every deploy | Low |
| Regression | Known issues | Varies | Every release | Medium |
| Performance | System capacity | Minutes-hours | Periodically | High |

## When to Use Each Type

```
┌─────────────────────────────────────────────────────────────┐
│                    Development Cycle                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Write Code → Unit Tests → Commit → Integration Tests       │
│                                           ↓                 │
│                              Build Pipeline                 │
│                                           ↓                 │
│                              Deploy → Smoke Tests           │
│                                           ↓                 │
│                              E2E Tests → Release            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## The Right Balance

- **70-80% Unit Tests:** Fast, cheap, catch most bugs
- **15-20% Integration Tests:** Verify components work together
- **5-10% E2E Tests:** Validate critical user journeys

> "Write tests at the lowest level possible while still giving you confidence."

## Key Takeaway

Each test type serves a specific purpose. Unit tests are your first line of defense—fast, focused, and run constantly. Integration and E2E tests provide confidence that the pieces work together, but they're slower and more expensive to maintain. A healthy test suite uses all types appropriately.
