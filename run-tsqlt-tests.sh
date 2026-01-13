#!/bin/bash
# Run tSQLt Tests

set -e

echo "================================================"
echo "Running tSQLt Unit Tests"
echo "================================================"
echo ""

TEST_CONTAINER="sqlserver2025-test"
TEST_DB="SampleDatabase_Test"
SA_PASSWORD="YourStrong@Passw0rd"

echo "Executing all tSQLt tests..."
echo ""

# Run all tests
docker exec $TEST_CONTAINER /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$SA_PASSWORD" -d $TEST_DB -C -Q "
EXEC tSQLt.RunAll;
"

echo ""
echo "================================================"
echo "Test Results Summary"
echo "================================================"
echo ""

# Get test results
docker exec $TEST_CONTAINER /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$SA_PASSWORD" -d $TEST_DB -C -Q "
SELECT
    Class,
    TestCase,
    Result,
    Msg
FROM tSQLt.TestResult
ORDER BY Class, TestCase;
"

echo ""

# Get summary
docker exec $TEST_CONTAINER /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$SA_PASSWORD" -d $TEST_DB -C -Q "
DECLARE @TotalTests INT, @Passed INT, @Failed INT;

SELECT
    @TotalTests = COUNT(*),
    @Passed = SUM(CASE WHEN Result = 'Success' THEN 1 ELSE 0 END),
    @Failed = SUM(CASE WHEN Result = 'Failure' THEN 1 ELSE 0 END)
FROM tSQLt.TestResult;

PRINT '================================================';
PRINT 'Summary:';
PRINT '  Total Tests: ' + CAST(@TotalTests AS VARCHAR);
PRINT '  Passed: ' + CAST(@Passed AS VARCHAR);
PRINT '  Failed: ' + CAST(@Failed AS VARCHAR);
PRINT '================================================';
"

echo ""
