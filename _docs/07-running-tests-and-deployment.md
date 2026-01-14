# Running Tests and Deployment Strategies

## How to Run tSQLt Tests

### Basic Test Execution

#### Run All Tests

```sql
EXEC tSQLt.RunAll;
```

#### Run Tests in a Specific Class (Schema)

```sql
EXEC tSQLt.Run 'TestOrderProcessing';
```

#### Run a Single Test

```sql
EXEC tSQLt.Run 'TestOrderProcessing.[test_CalculateTotal_ReturnsCorrectSum]';
```

### Understanding Test Output

```
+----------------------+
|Test Execution Summary|
+----------------------+

|No|Test Case Name                                          |Dur(ms)|Result |
+--+--------------------------------------------------------+-------+-------+
|1 |[TestOrderProcessing].[test_CalculateTotal_ReturnsSum] |    45 |Success|
|2 |[TestOrderProcessing].[test_ValidateOrder_RejectsNull] |    32 |Success|
|3 |[TestOrderProcessing].[test_ApplyDiscount_CalculatesOK]|    28 |Failure|
+--+--------------------------------------------------------+-------+-------+
Msg 50000, Level 16, State 10, Line 1
Test Case Summary: 3 test case(s) executed, 2 succeeded, 1 failed, 0 errored.
```

### Output Formats

#### XML Results (for CI/CD integration)

```sql
EXEC tSQLt.RunAll;
EXEC tSQLt.XmlResultFormatter;
```

#### Default Text Format

```sql
EXEC tSQLt.RunAll;
EXEC tSQLt.DefaultResultFormatter;
```

## Test Organization Best Practices

### Use Test Classes (Schemas)

Organize tests by the functionality they test:

```sql
-- Create test classes for different areas
EXEC tSQLt.NewTestClass 'TestOrderProcessing';
EXEC tSQLt.NewTestClass 'TestCustomerManagement';
EXEC tSQLt.NewTestClass 'TestInventory';
EXEC tSQLt.NewTestClass 'TestReporting';
```

### Naming Conventions

```sql
-- Pattern: [TestClass].[test_MethodUnderTest_Scenario_ExpectedResult]

-- Good examples:
[TestOrders].[test_CreateOrder_ValidInput_InsertsRow]
[TestOrders].[test_CreateOrder_NegativeQuantity_ThrowsError]
[TestOrders].[test_CalculateTotal_MultipleItems_SumsCorrectly]

-- Bad examples:
[TestOrders].[Test1]
[TestOrders].[OrderTest]
[TestOrders].[test orders work]
```

## Deployment Strategies

### Strategy 1: tSQLt in Development Only

```
┌────────────────┐    ┌────────────────┐    ┌────────────────┐
│  Development   │ →  │    Testing     │ →  │   Production   │
│                │    │                │    │                │
│  + tSQLt       │    │  + tSQLt       │    │  - tSQLt       │
│  + Test Classes│    │  + Test Classes│    │  (No tests)    │
└────────────────┘    └────────────────┘    └────────────────┘
```

**Pros:**
- Production database stays clean
- No risk of test code affecting production
- Smaller production footprint

**Cons:**
- Can't verify tests in production environment
- Must maintain separate deployment scripts

### Strategy 2: tSQLt in All Environments

```
┌────────────────┐    ┌────────────────┐    ┌────────────────┐
│  Development   │ →  │    Testing     │ →  │   Production   │
│                │    │                │    │                │
│  + tSQLt       │    │  + tSQLt       │    │  + tSQLt       │
│  + Test Classes│    │  + Test Classes│    │  + Test Classes│
└────────────────┘    └────────────────┘    └────────────────┘
```

**Pros:**
- Consistent across environments
- Can run smoke tests in production
- Simpler deployment process

**Cons:**
- Additional objects in production
- Potential security concerns
- Larger database footprint

### Strategy 3: Separate Test Database

```
┌─────────────────────────────────────────────────┐
│                 SQL Server Instance             │
├────────────────┬────────────────────────────────┤
│  AppDatabase   │     AppDatabase_Tests          │
│                │                                │
│  - Tables      │  + tSQLt                       │
│  - Procedures  │  + Test Classes                │
│  - Functions   │  + Synonyms → AppDatabase      │
│                │                                │
│  (No tests)    │  (All tests here)              │
└────────────────┴────────────────────────────────┘
```

**Pros:**
- Complete separation
- Easy to drop/recreate test database
- Production stays clean

**Cons:**
- More complex setup
- Cross-database references needed

## CI/CD Integration

### GitHub Actions Example

```yaml
name: SQL Server Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      sqlserver:
        image: mcr.microsoft.com/mssql/server:2022-latest
        env:
          SA_PASSWORD: StrongPassword123!
          ACCEPT_EULA: Y
        ports:
          - 1433:1433

    steps:
      - uses: actions/checkout@v3

      - name: Wait for SQL Server
        run: |
          for i in {1..30}; do
            sqlcmd -S localhost -U sa -P StrongPassword123! -Q "SELECT 1" && break
            sleep 1
          done

      - name: Deploy Database
        run: |
          sqlcmd -S localhost -U sa -P StrongPassword123! -i ./scripts/deploy-database.sql

      - name: Install tSQLt
        run: |
          sqlcmd -S localhost -U sa -P StrongPassword123! -i ./scripts/install-tsqlt.sql

      - name: Deploy Tests
        run: |
          sqlcmd -S localhost -U sa -P StrongPassword123! -i ./scripts/deploy-tests.sql

      - name: Run Tests
        run: |
          sqlcmd -S localhost -U sa -P StrongPassword123! \
            -Q "EXEC tSQLt.RunAll; EXEC tSQLt.XmlResultFormatter;" \
            -o test-results.xml

      - name: Upload Results
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: test-results.xml
```

### Azure DevOps Pipeline Example

```yaml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

stages:
  - stage: Test
    jobs:
      - job: RunTests
        services:
          sqlserver:
            image: mcr.microsoft.com/mssql/server:2022-latest
            ports:
              - 1433:1433

        steps:
          - task: SqlDacpacDeploymentOnMachineGroup@0
            inputs:
              dacpacFile: '$(Build.SourcesDirectory)/database.dacpac'
              serverName: 'localhost'

          - script: |
              sqlcmd -S localhost -U sa -P $(SA_PASSWORD) \
                -Q "EXEC tSQLt.RunAll;"
            displayName: 'Run tSQLt Tests'
```

## Deployment Order

### Recommended Deployment Sequence

```
1. Deploy/Update Database Schema
   └── Tables, columns, indexes
   └── Primary keys, foreign keys

2. Deploy/Update Programmable Objects
   └── Functions
   └── Stored procedures
   └── Triggers
   └── Views

3. Install/Update tSQLt Framework
   └── Only if not already installed
   └── Check version compatibility

4. Deploy/Update Test Classes
   └── Create test schemas
   └── Deploy test procedures

5. Run Tests
   └── EXEC tSQLt.RunAll
   └── Capture results

6. Evaluate Results
   └── Fail build if tests fail
   └── Generate reports
```

### Deployment Script Example

```sql
-- deploy.sql
PRINT 'Starting deployment...';

-- Step 1: Schema changes
PRINT 'Deploying schema changes...';
:r ./scripts/01-schema-changes.sql

-- Step 2: Stored procedures
PRINT 'Deploying stored procedures...';
:r ./scripts/02-stored-procedures.sql

-- Step 3: Install tSQLt (if not exists)
PRINT 'Installing tSQLt...';
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'tSQLt')
BEGIN
    :r ./lib/tSQLt.class.sql
END

-- Step 4: Deploy tests
PRINT 'Deploying tests...';
:r ./tests/TestOrderProcessing.sql
:r ./tests/TestCustomerManagement.sql

-- Step 5: Run tests
PRINT 'Running tests...';
EXEC tSQLt.RunAll;

-- Step 6: Check results
DECLARE @FailCount INT;
SELECT @FailCount = COUNT(*)
FROM tSQLt.TestResult
WHERE Result = 'Failure';

IF @FailCount > 0
BEGIN
    RAISERROR('Tests failed! Deployment aborted.', 16, 1);
    RETURN;
END

PRINT 'All tests passed. Deployment complete.';
```

## Best Practices Summary

### Development

1. **Write tests first** (TDD) or alongside code
2. **Run tests frequently** during development
3. **Keep tests fast** (mock external dependencies)
4. **One assertion per test** when possible

### CI/CD

1. **Use containers** for consistent environments
2. **Run all tests** on every commit
3. **Fail fast** - stop deployment if tests fail
4. **Capture results** in standard formats (XML)

### Deployment

1. **Never skip tests** before production deployment
2. **Use transactions** for rollback capability
3. **Version your tests** alongside your code
4. **Clean up test data** after each run

### Maintenance

1. **Delete obsolete tests** when features change
2. **Refactor tests** when code is refactored
3. **Monitor test duration** - slow tests hurt productivity
4. **Review failed tests** immediately

## Common Pitfalls to Avoid

| Pitfall | Solution |
|---------|----------|
| Tests depend on each other | Each test should be independent |
| Tests require specific data | Use FakeTable, insert test data |
| Tests are slow | Mock external calls, minimize data |
| Tests are flaky | Remove randomness, control dates/times |
| Tests left in production | Use deployment strategy 1 or 3 |
| Tests not maintained | Include tests in code reviews |

## Summary

Effective test running and deployment requires:

1. **Consistent environments** - Use containers or managed instances
2. **Automated execution** - Integrate with CI/CD pipelines
3. **Clear organization** - Use test classes and naming conventions
4. **Fast feedback** - Run tests on every change
5. **Fail-safe deployment** - Never deploy if tests fail

The goal is to catch issues early, deploy with confidence, and maintain a healthy, tested codebase.
