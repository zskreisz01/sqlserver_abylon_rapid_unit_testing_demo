## Test Logging System for tSQLt

A comprehensive logging system to track test execution sessions, individual test results, durations, and error messages.

## Overview

The test logging system consists of:
- **TestSession Table**: Logs test execution sessions with start/end timestamps and summary statistics
- **TestRun Table**: Logs individual test results with durations and error messages
- **Stored Procedures**: Automate the logging process
- **Views**: Provide convenient access to logged data

## Database Schema

### Tables

#### TestLog.TestSession
Stores test execution session information.

| Column | Type | Description |
|--------|------|-------------|
| SessionId | INT (PK) | Unique session identifier |
| Command | NVARCHAR(500) | Command executed (e.g., "EXEC tSQLt.RunAll") |
| StartTimestamp | DATETIME2 | Session start time |
| EndTimestamp | DATETIME2 | Session end time |
| TotalTests | INT | Total number of tests executed |
| PassedTests | INT | Number of tests that passed |
| FailedTests | INT | Number of tests that failed |
| SkippedTests | INT | Number of tests skipped |
| ErroredTests | INT | Number of tests with errors |
| DurationMs | INT | Total duration in milliseconds |
| ExecutedBy | NVARCHAR(128) | User who executed the tests |
| MachineName | NVARCHAR(128) | Server name |
| Status | NVARCHAR(50) | Session status (Running, Completed Successfully, Completed with Failures) |
| Notes | NVARCHAR(MAX) | Optional notes or error messages |

#### TestLog.TestRun
Stores individual test execution results.

| Column | Type | Description |
|--------|------|-------------|
| TestRunId | INT (PK) | Unique test run identifier |
| SessionId | INT (FK) | Reference to TestSession |
| TestClass | NVARCHAR(255) | Test class name (schema) |
| TestName | NVARCHAR(255) | Test procedure name |
| Result | NVARCHAR(20) | Test result (Success, Failure, Error, Skipped) |
| DurationMs | INT | Test duration in milliseconds |
| ErrorMessage | NVARCHAR(MAX) | Error message if test failed |
| TestStartTime | DATETIME2 | Test start time |
| TestEndTime | DATETIME2 | Test end time |

## Stored Procedures

### TestLog.StartTestSession
Starts a new test session.

```sql
DECLARE @SessionId INT;
EXEC TestLog.StartTestSession
    @Command = 'EXEC tSQLt.RunAll',
    @SessionId = @SessionId OUTPUT;
```

### TestLog.EndTestSession
Ends a test session and calculates summary statistics.

```sql
EXEC TestLog.EndTestSession
    @SessionId = 1,
    @Notes = 'Optional notes';
```

### TestLog.LogTestResult
Logs an individual test result.

```sql
EXEC TestLog.LogTestResult
    @SessionId = 1,
    @TestClass = 'CustomerTests',
    @TestName = 'test Customer insertion',
    @Result = 'Success',
    @DurationMs = 150,
    @ErrorMessage = NULL;
```

### TestLog.RunTestsWithLogging
Runs tests and automatically logs all results.

```sql
-- Run all tests with logging
DECLARE @SessionId INT;
EXEC TestLog.RunTestsWithLogging
    @TestClass = NULL,
    @SessionId = @SessionId OUTPUT;

-- Run specific test class with logging
DECLARE @SessionId INT;
EXEC TestLog.RunTestsWithLogging
    @TestClass = 'DemoTests',
    @SessionId = @SessionId OUTPUT;
```

## Views

### TestLog.vw_TestSessionSummary
Provides a summary view of all test sessions with calculated metrics.

```sql
SELECT
    SessionId,
    Command,
    StartTimestamp,
    EndTimestamp,
    DurationSeconds,
    TotalTests,
    PassedTests,
    FailedTests,
    PassRate,
    Status
FROM TestLog.vw_TestSessionSummary
ORDER BY SessionId DESC;
```

### TestLog.vw_TestRunDetails
Provides detailed information about individual test runs.

```sql
SELECT
    TestRunId,
    SessionId,
    SessionCommand,
    TestClass,
    TestName,
    Result,
    DurationMs,
    ErrorMessage
FROM TestLog.vw_TestRunDetails
WHERE SessionId = 2
ORDER BY TestRunId;
```

## Usage Examples

### Example 1: Run All Tests with Logging

```sql
DECLARE @SessionId INT;
EXEC TestLog.RunTestsWithLogging
    @TestClass = NULL,
    @SessionId = @SessionId OUTPUT;

-- View the results
SELECT * FROM TestLog.vw_TestSessionSummary WHERE SessionId = @SessionId;
SELECT * FROM TestLog.TestRun WHERE SessionId = @SessionId;
```

### Example 2: View All Sessions

```sql
SELECT
    SessionId,
    Command,
    FORMAT(StartTimestamp, 'yyyy-MM-dd HH:mm:ss') AS StartTime,
    FORMAT(EndTimestamp, 'yyyy-MM-dd HH:mm:ss') AS EndTime,
    TotalTests,
    PassedTests,
    FailedTests,
    CAST(PassRate AS VARCHAR) + '%' AS PassRate,
    Status
FROM TestLog.vw_TestSessionSummary
ORDER BY SessionId DESC;
```

**Sample Output:**

| SessionId | Command | StartTime | EndTime | TotalTests | Passed | Failed | PassRate | Status |
|-----------|---------|-----------|---------|------------|--------|--------|----------|--------|
| 3 | EXEC tSQLt.Run 'DemoTests' | 2025-12-18 14:42:08 | 2025-12-18 14:42:08 | 2 | 1 | 1 | 50.00% | Completed with Failures |
| 2 | EXEC tSQLt.RunAll | 2025-12-18 14:41:46 | 2025-12-18 14:41:47 | 5 | 4 | 1 | 80.00% | Completed with Failures |
| 1 | EXEC tSQLt.RunAll | 2025-12-18 14:41:32 | 2025-12-18 14:41:46 | 5 | 4 | 1 | 80.00% | Completed with Failures |

### Example 3: View Failed Tests

```sql
SELECT
    tr.SessionId,
    FORMAT(s.StartTimestamp, 'yyyy-MM-dd HH:mm:ss') AS SessionTime,
    tr.TestClass,
    tr.TestName,
    tr.ErrorMessage
FROM TestLog.TestRun tr
INNER JOIN TestLog.TestSession s ON tr.SessionId = s.SessionId
WHERE tr.Result = 'Failure'
ORDER BY tr.SessionId DESC;
```

**Sample Output:**

| SessionId | SessionTime | TestClass | TestName | ErrorMessage |
|-----------|-------------|-----------|----------|--------------|
| 3 | 2025-12-18 14:42:08 | DemoTests | test This will deliberately fail | Expected 10 but got 5... |
| 2 | 2025-12-18 14:41:46 | DemoTests | test This will deliberately fail | Expected 10 but got 5... |

### Example 4: Test Class Statistics

```sql
SELECT
    TestClass,
    COUNT(*) AS TotalRuns,
    SUM(CASE WHEN Result = 'Success' THEN 1 ELSE 0 END) AS Passed,
    SUM(CASE WHEN Result = 'Failure' THEN 1 ELSE 0 END) AS Failed,
    CAST(SUM(CASE WHEN Result = 'Success' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS PassRate,
    AVG(CAST(DurationMs AS FLOAT)) AS AvgDurationMs
FROM TestLog.TestRun
GROUP BY TestClass
ORDER BY TestClass;
```

### Example 5: Session Performance Comparison

```sql
SELECT
    SessionId,
    Command,
    TotalTests,
    CAST(DurationMs / 1000.0 AS DECIMAL(10,2)) AS DurationSec,
    CAST(DurationMs / CAST(NULLIF(TotalTests, 0) AS FLOAT) AS DECIMAL(10,2)) AS AvgTestDurationMs,
    PassRate,
    Status
FROM TestLog.vw_TestSessionSummary
ORDER BY SessionId DESC;
```

### Example 6: Most Frequently Failing Tests

```sql
SELECT TOP 10
    TestClass,
    TestName,
    COUNT(*) AS FailureCount,
    MAX(ErrorMessage) AS LastErrorMessage
FROM TestLog.TestRun
WHERE Result = 'Failure'
GROUP BY TestClass, TestName
ORDER BY FailureCount DESC;
```

### Example 7: Slowest Tests

```sql
SELECT TOP 10
    TestClass,
    TestName,
    DurationMs,
    Result,
    FORMAT(TestStartTime, 'yyyy-MM-dd HH:mm:ss') AS ExecutedAt
FROM TestLog.TestRun
WHERE DurationMs IS NOT NULL
ORDER BY DurationMs DESC;
```

## Installation

Run the schema creation script:

```bash
docker exec sqlserver2025-test /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P 'YourStrong@Passw0rd' \
  -d SampleDatabase_Test -C \
  -i /path/to/test-logging-schema.sql
```

Or from the repository:

```bash
cat test-logging-schema.sql | docker exec -i sqlserver2025-test \
  /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' \
  -d SampleDatabase_Test -C
```

## Benefits

1. **Historical Tracking**: Track test execution over time
2. **Performance Monitoring**: Identify slow tests and performance trends
3. **Failure Analysis**: Quickly identify frequently failing tests
4. **Audit Trail**: Complete audit trail of who ran tests and when
5. **Reporting**: Generate reports on test health and trends
6. **CI/CD Integration**: Easy integration with CI/CD pipelines
7. **Troubleshooting**: Detailed error messages for failed tests

## Integration with CI/CD

The logging system can be easily integrated into CI/CD pipelines:

```yaml
# GitHub Actions example
- name: Run Tests with Logging
  run: |
    docker exec sqlserver2025-test /opt/mssql-tools18/bin/sqlcmd \
      -S localhost -U SA -P "${{ secrets.SA_PASSWORD }}" \
      -d SampleDatabase_Test -C \
      -Q "DECLARE @SessionId INT; EXEC TestLog.RunTestsWithLogging @SessionId = @SessionId OUTPUT;"

- name: Check Test Results
  run: |
    docker exec sqlserver2025-test /opt/mssql-tools18/bin/sqlcmd \
      -S localhost -U SA -P "${{ secrets.SA_PASSWORD }}" \
      -d SampleDatabase_Test -C \
      -Q "SELECT FailedTests FROM TestLog.TestSession WHERE SessionId = (SELECT MAX(SessionId) FROM TestLog.TestSession);"
```

## Maintenance

### Clear Old Test Logs

```sql
-- Delete sessions older than 30 days
DELETE FROM TestLog.TestRun
WHERE SessionId IN (
    SELECT SessionId FROM TestLog.TestSession
    WHERE StartTimestamp < DATEADD(DAY, -30, GETDATE())
);

DELETE FROM TestLog.TestSession
WHERE StartTimestamp < DATEADD(DAY, -30, GETDATE());
```

### Archive Test Logs

```sql
-- Archive to a separate table
SELECT * INTO TestLog.TestSession_Archive
FROM TestLog.TestSession
WHERE StartTimestamp < DATEADD(MONTH, -6, GETDATE());
```

## Files

- [test-logging-schema.sql](test-logging-schema.sql) - Complete schema creation script
- [view-test-logs.sql](view-test-logs.sql) - Sample query scripts for viewing logs

## See Also

- [TSQLT_TESTING.md](TSQLT_TESTING.md) - Complete tSQLt testing guide
- [README.md](README.md) - Project overview
