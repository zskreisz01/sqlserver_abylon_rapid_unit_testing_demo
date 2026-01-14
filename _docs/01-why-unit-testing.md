# Why Unit Testing?

```
┌─────────────────────────────────────────────────────────────────────┐
│           SOFTWARE TESTING PHILOSOPHY                               │
│      Every project gets tested. The question is when.               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   🧠        │  We test on every project                             │
│             │                                                       │
├─────────────┼───────────────────────────────────────────────────────┤
│             │                                                       │
│  ✨🧠✨     │  Only the lucky ones get tests written during         │
│             │  dev phase                                            │
├─────────────┼───────────────────────────────────────────────────────┤
│             │                                                       │
│  🔥🧠🔥    │  The brave ones test in production                    │
│             │                                                       │
└─────────────┴───────────────────────────────────────────────────────┘
```

*Don't be "brave." Write your tests during development.*

---

## The Core Purpose

Unit testing is a software development practice where individual components (units) of code are tested in isolation to verify they work correctly. But why do we invest time and effort into writing tests?

## Key Benefits of Unit Testing

### 1. Catching Bugs Early

The earlier a bug is found, the cheaper it is to fix. Unit tests catch issues during development, before they reach:
- Integration testing
- QA environments
- Production systems
- End users

**Cost of bug fixes increases exponentially** as code moves through the development lifecycle.

### 2. Documentation Through Code

Well-written unit tests serve as living documentation:
- They show how code is intended to be used
- They demonstrate expected inputs and outputs
- They remain up-to-date (unlike written documentation that often becomes stale)

### 3. Enabling Refactoring with Confidence

Without tests, refactoring is risky. With comprehensive unit tests:
- You can restructure code knowing tests will catch regressions
- You can improve performance without fear of breaking functionality
- Legacy code becomes safer to modify

### 4. Faster Development Cycles

While writing tests takes time initially:
- Debugging time decreases significantly
- You spend less time manually testing
- Issues are identified immediately, not days later

### 5. Better Code Design

Writing testable code naturally leads to:
- Smaller, focused functions
- Clear separation of concerns
- Reduced coupling between components
- More maintainable codebases

## What Do We Unit Test: Data or Functionality?

This is a crucial question, especially for database development.

### We Primarily Test Functionality

Unit tests verify **behavior**, not data itself:
- Does this stored procedure calculate the discount correctly?
- Does this function handle NULL values properly?
- Does this trigger prevent invalid state changes?

### Data in Tests is a Means, Not an End

We use test data to:
- Set up scenarios (Arrange phase)
- Trigger the behavior we want to test (Act phase)
- Verify the expected outcome (Assert phase)

The data itself is temporary and disposable—it exists only to test the logic.

### Example: Testing a Discount Calculation

```sql
-- We're not testing if "10" is stored correctly
-- We're testing if the discount LOGIC works
CREATE PROCEDURE TestDiscountCalculation
AS
BEGIN
    -- Arrange: Set up test data
    INSERT INTO Orders (OrderID, Amount) VALUES (1, 100.00);

    -- Act: Execute the functionality
    EXEC CalculateDiscount @OrderID = 1, @DiscountPercent = 10;

    -- Assert: Verify the behavior
    DECLARE @FinalAmount MONEY;
    SELECT @FinalAmount = FinalAmount FROM Orders WHERE OrderID = 1;

    -- We test that 10% discount on 100 = 90
    EXEC tSQLt.AssertEquals 90.00, @FinalAmount;
END
```

## The Testing Mindset

Think of unit tests as a safety net:
- They don't guarantee bug-free code
- They provide confidence that known scenarios work
- They make unknown bugs easier to find and fix

> "Code without tests is broken by design." — Jacob Kaplan-Moss

## Summary

| Aspect | Purpose |
|--------|---------|
| **Catching bugs** | Find issues before they reach production |
| **Documentation** | Show how code should behave |
| **Refactoring safety** | Change code without fear |
| **Development speed** | Less debugging, faster iterations |
| **Code quality** | Forces better design decisions |

Unit testing isn't about proving code is perfect—it's about building confidence in your codebase and making change manageable.
