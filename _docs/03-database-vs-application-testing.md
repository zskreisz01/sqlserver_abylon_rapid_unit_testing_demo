# Database Testing vs. Application Testing

## Why Database Testing is Different

Testing database code (T-SQL, PL/SQL, etc.) presents unique challenges compared to testing application code in languages like C#, Java, or Python. Understanding these differences is crucial for effective database testing.

## Key Differences

### 1. State Persistence

**Application Code:**
- Objects exist in memory
- State is typically discarded after test execution
- Easy to create fresh instances for each test

**Database Code:**
- Data persists in tables
- State survives test execution
- Requires explicit cleanup or isolation strategies

```
Application Testing:              Database Testing:
┌──────────────────┐              ┌──────────────────┐
│ Create object    │              │ Insert test data │
│ Call method      │              │ Execute procedure│
│ Assert result    │              │ Assert result    │
│ Object discarded │              │ DATA STILL EXISTS│
└──────────────────┘              └──────────────────┘
                                          ↓
                                  Must clean up or
                                  rollback transaction
```

### 2. Isolation Challenges

**Application Code:**
- Use mocking frameworks to isolate dependencies
- Inject fake services/repositories
- Complete control over test environment

**Database Code:**
- Tables have foreign key relationships
- Triggers fire automatically
- Constraints enforce data integrity
- Stored procedures may call other procedures

```sql
-- In application code, you mock the dependency:
var mockRepository = new Mock<IOrderRepository>();

-- In database code, you must "fake" the table:
EXEC tSQLt.FakeTable 'dbo.Orders';
-- This removes constraints, triggers, and foreign keys
```

### 3. Transaction Scope

**Application Code:**
- Tests typically don't manage transactions
- Database operations are abstracted away
- Repository pattern handles persistence

**Database Code:**
- Every operation is a transaction
- Tests often run inside a transaction that's rolled back
- Must consider transaction isolation levels

### 4. Side Effects

**Application Code:**
- Side effects can be mocked/intercepted
- Email service, file system, etc., are injected
- Easy to verify without actual execution

**Database Code:**
- Triggers execute automatically
- Computed columns update
- Cascading deletes occur
- These are harder to isolate

### 5. Test Data Setup

**Application Code:**
```csharp
// Create objects in memory - fast and simple
var order = new Order { Id = 1, Total = 100.00m };
var customer = new Customer { Name = "Test" };
```

**Database Code:**
```sql
-- Must insert actual rows - slower and more complex
INSERT INTO dbo.Customers (CustomerID, Name) VALUES (1, 'Test');
INSERT INTO dbo.Orders (OrderID, CustomerID, Total) VALUES (1, 1, 100.00);
-- Must respect foreign keys, constraints, not-null columns, etc.
```

## Comparison Table

| Aspect | Application Testing | Database Testing |
|--------|--------------------|--------------------|
| **State** | In-memory, temporary | Persistent, must clean up |
| **Isolation** | Dependency injection, mocking | Table faking, transaction rollback |
| **Speed** | Typically milliseconds | Slower due to I/O |
| **Setup** | Create objects | Insert rows, respect constraints |
| **Cleanup** | Garbage collected | Must rollback or delete |
| **Side effects** | Mocked | Real triggers, constraints |
| **Parallelization** | Easy | Difficult (shared state) |

## Common Database Testing Challenges

### Challenge 1: Referential Integrity

```sql
-- Can't insert order without customer
INSERT INTO dbo.Orders (CustomerID) VALUES (999);
-- ERROR: FK violation!

-- Solution: Fake the table or insert parent records first
EXEC tSQLt.FakeTable 'dbo.Orders';
-- Now FK is disabled, can insert freely
```

### Challenge 2: Identity Columns

```sql
-- Can't control identity values
INSERT INTO dbo.Orders (OrderID, Amount) VALUES (1, 100);
-- ERROR: Cannot insert explicit value for identity column!

-- Solution: Fake the table (removes identity property)
EXEC tSQLt.FakeTable 'dbo.Orders';
INSERT INTO dbo.Orders (OrderID, Amount) VALUES (1, 100);
-- Works!
```

### Challenge 3: Triggers

```sql
-- Trigger fires automatically, may cause unexpected behavior
INSERT INTO dbo.Orders (Amount) VALUES (100);
-- Trigger updates audit table, sends notification, etc.

-- Solution: Fake the table (removes triggers)
EXEC tSQLt.FakeTable 'dbo.Orders';
-- Or apply the trigger to faked table if testing trigger behavior
EXEC tSQLt.ApplyTrigger 'dbo.Orders', 'trg_AuditOrders';
```

### Challenge 4: Time-Dependent Logic

```sql
-- Procedure uses GETDATE() internally
EXEC dbo.CalculateLateFees; -- Uses current date

-- Solution: Use SpyProcedure or design for testability
-- Pass date as parameter, or use a wrapper function that can be faked
```

## How tSQLt Addresses These Challenges

| Challenge | tSQLt Solution |
|-----------|----------------|
| Referential integrity | `FakeTable` removes FK constraints |
| Identity columns | `FakeTable` removes identity property |
| Triggers | `FakeTable` removes triggers; `ApplyTrigger` adds them back selectively |
| Cleanup | Tests run in transactions that are rolled back |
| Isolation | Each test class runs in its own schema |
| Assertions | Built-in assertions for tables, values, exceptions |

## Best Practices for Database Testing

1. **Use transactions:** Let tests roll back automatically
2. **Fake tables:** Isolate the code under test
3. **Minimize test data:** Only insert what's necessary
4. **Test one thing:** Each test should verify one behavior
5. **Avoid shared state:** Don't rely on data from other tests
6. **Design for testability:** Parameterize dates, use wrapper functions

## Summary

Database testing requires different strategies than application testing due to:
- Persistent state that must be managed
- Built-in behaviors (constraints, triggers) that must be isolated
- Shared resources that complicate parallelization

Frameworks like tSQLt provide tools specifically designed to address these database-specific challenges, making unit testing in SQL Server practical and effective.
