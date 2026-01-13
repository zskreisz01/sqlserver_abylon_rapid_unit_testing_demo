# tSQLt Demo Test Results

This document shows examples of both **successful** and **failing** unit tests using tSQLt.

## Test Class: DemoTests

### Test 1: Successful Test ✓

**Test Name:** `test Simple math works correctly`

**Purpose:** Demonstrate a passing test with correct assertion

**Test Code:**
```sql
CREATE PROCEDURE DemoTests.[test Simple math works correctly]
AS
BEGIN
    -- Arrange
    DECLARE @Expected INT = 5;
    DECLARE @Actual INT;

    -- Act
    SET @Actual = 2 + 3;

    -- Assert
    EXEC tSQLt.AssertEquals @Expected, @Actual, 'Math should work: 2 + 3 should equal 5';
END;
```

**Result:** ✅ **SUCCESS**
- Duration: 7ms
- Status: Passed
- Message: (none - test passed)

---

### Test 2: Failing Test ✗

**Test Name:** `test This will deliberately fail`

**Purpose:** Demonstrate a failing test with incorrect assertion

**Test Code:**
```sql
CREATE PROCEDURE DemoTests.[test This will deliberately fail]
AS
BEGIN
    -- Arrange
    DECLARE @Expected INT = 10;
    DECLARE @Actual INT;

    -- Act
    SET @Actual = 2 + 3;  -- This gives 5, not 10

    -- Assert - This will fail!
    EXEC tSQLt.AssertEquals @Expected, @Actual, 'Expected 10 but got 5 - this test should fail!';
END;
```

**Result:** ❌ **FAILURE**
- Duration: 6ms
- Status: Failed
- Message: `Expected 10 but got 5 - this test should fail! Expected: <10> but was: <5>`

---

## Test Execution Summary

```
+----------------------+
|Test Execution Summary|
+----------------------+

|No|Test Case Name                                |Dur(ms)|Result |
+--+----------------------------------------------+-------+-------+
|1 |[DemoTests].[test Simple math works correctly]|      7|Success|
|2 |[DemoTests].[test This will deliberately fail]|      6|Failure|
----------------------------------------------------------------------------------------
Test Case Summary: 2 test case(s) executed, 1 succeeded, 0 skipped, 1 failed, 0 errored.
----------------------------------------------------------------------------------------
```

## Key Observations

### Successful Test Characteristics:
- Clear arrange-act-assert pattern
- Expected value matches actual value
- Test passes without errors
- No failure message displayed

### Failing Test Characteristics:
- Same arrange-act-assert pattern
- Expected value does NOT match actual value
- Test fails with clear error message
- tSQLt shows both expected and actual values for debugging

## Understanding Failure Messages

When a test fails, tSQLt provides detailed information:

```
Expected 10 but got 5 - this test should fail! Expected: <10> but was: <5>
```

This message includes:
1. **Custom Message**: "Expected 10 but got 5 - this test should fail!"
2. **Expected Value**: `<10>`
3. **Actual Value**: `<5>`

This makes debugging very clear - you can immediately see what went wrong.

## How to Run These Tests

```bash
# Run all DemoTests
docker exec sqlserver2025-test /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P 'YourStrong@Passw0rd' \
  -d SampleDatabase_Test -C \
  -Q "EXEC tSQLt.Run 'DemoTests';"

# Run a specific test
docker exec sqlserver2025-test /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P 'YourStrong@Passw0rd' \
  -d SampleDatabase_Test -C \
  -Q "EXEC tSQLt.Run 'DemoTests.[test Simple math works correctly]';"
```

## Detailed Test Results Query

```sql
SELECT
    Class,
    TestCase,
    Result,
    Msg
FROM tSQLt.TestResult
WHERE Class = 'DemoTests'
ORDER BY TestCase;
```

**Output:**

| Class | TestCase | Result | Msg |
|-------|----------|--------|-----|
| DemoTests | test Simple math works correctly | Success | (null) |
| DemoTests | test This will deliberately fail | Failure | Expected 10 but got 5... |

## Best Practices Demonstrated

1. **Clear Test Names**: Descriptive names that explain what is being tested
2. **AAA Pattern**: Arrange, Act, Assert structure in both tests
3. **Meaningful Messages**: Custom assertion messages that explain the failure
4. **Simple Assertions**: Using `tSQLt.AssertEquals` for straightforward comparisons

## Next Steps

To fix the failing test, you would:
1. Identify the issue: Expected value is wrong (should be 5, not 10)
2. Update the test:
   ```sql
   DECLARE @Expected INT = 5; -- Changed from 10
   ```
3. Re-run the test
4. Verify it now passes

This demonstrates the test-driven development cycle with tSQLt!
