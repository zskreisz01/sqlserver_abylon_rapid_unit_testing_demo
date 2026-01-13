-- =============================================
-- Query Scripts for Test Logging
-- =============================================

USE SampleDatabase_Test;
GO

-- =============================================
-- View all test sessions
-- =============================================
PRINT '=== ALL TEST SESSIONS ===';
SELECT
    SessionId,
    Command,
    FORMAT(StartTimestamp, 'yyyy-MM-dd HH:mm:ss') AS StartTime,
    FORMAT(EndTimestamp, 'yyyy-MM-dd HH:mm:ss') AS EndTime,
    CAST(DurationMs / 1000.0 AS DECIMAL(10,2)) AS DurationSec,
    TotalTests,
    PassedTests,
    FailedTests,
    CAST(PassRate AS VARCHAR) + '%' AS PassRate,
    Status
FROM TestLog.vw_TestSessionSummary
ORDER BY SessionId DESC;
GO

-- =============================================
-- View latest session details
-- =============================================
PRINT '';
PRINT '=== LATEST SESSION DETAILS ===';
DECLARE @LatestSessionId INT = (SELECT MAX(SessionId) FROM TestLog.TestSession);

SELECT
    SessionId,
    Command,
    FORMAT(StartTimestamp, 'yyyy-MM-dd HH:mm:ss.fff') AS StartTime,
    FORMAT(EndTimestamp, 'yyyy-MM-dd HH:mm:ss.fff') AS EndTime,
    DurationMs,
    TotalTests,
    PassedTests,
    FailedTests,
    SkippedTests,
    ErroredTests,
    Status,
    ExecutedBy,
    MachineName
FROM TestLog.TestSession
WHERE SessionId = @LatestSessionId;
GO

-- =============================================
-- View all test results from latest session
-- =============================================
PRINT '';
PRINT '=== LATEST SESSION TEST RESULTS ===';
DECLARE @LatestSessionId INT = (SELECT MAX(SessionId) FROM TestLog.TestSession);

SELECT
    TestRunId,
    TestClass,
    TestName,
    Result,
    DurationMs,
    CASE
        WHEN ErrorMessage IS NULL THEN '(none)'
        WHEN LEN(ErrorMessage) > 100 THEN LEFT(ErrorMessage, 100) + '...'
        ELSE ErrorMessage
    END AS ErrorMessage
FROM TestLog.TestRun
WHERE SessionId = @LatestSessionId
ORDER BY TestRunId;
GO

-- =============================================
-- View failed tests across all sessions
-- =============================================
PRINT '';
PRINT '=== ALL FAILED TESTS ===';
SELECT
    tr.SessionId,
    FORMAT(s.StartTimestamp, 'yyyy-MM-dd HH:mm:ss') AS SessionTime,
    tr.TestClass,
    tr.TestName,
    tr.ErrorMessage
FROM TestLog.TestRun tr
INNER JOIN TestLog.TestSession s ON tr.SessionId = s.SessionId
WHERE tr.Result = 'Failure'
ORDER BY tr.SessionId DESC, tr.TestRunId;
GO

-- =============================================
-- Test execution trends (by test class)
-- =============================================
PRINT '';
PRINT '=== TEST CLASS STATISTICS ===';
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
GO

-- =============================================
-- Session performance comparison
-- =============================================
PRINT '';
PRINT '=== SESSION PERFORMANCE ===';
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
GO

-- =============================================
-- Most frequently failing tests
-- =============================================
PRINT '';
PRINT '=== MOST FREQUENTLY FAILING TESTS ===';
SELECT TOP 10
    TestClass,
    TestName,
    COUNT(*) AS FailureCount,
    MAX(ErrorMessage) AS LastErrorMessage
FROM TestLog.TestRun
WHERE Result = 'Failure'
GROUP BY TestClass, TestName
ORDER BY FailureCount DESC, TestClass, TestName;
GO

-- =============================================
-- Slowest tests
-- =============================================
PRINT '';
PRINT '=== SLOWEST TESTS (Top 10) ===';
SELECT TOP 10
    tr.TestClass,
    tr.TestName,
    tr.DurationMs,
    tr.Result,
    FORMAT(tr.TestStartTime, 'yyyy-MM-dd HH:mm:ss') AS ExecutedAt
FROM TestLog.TestRun tr
WHERE tr.DurationMs IS NOT NULL
ORDER BY tr.DurationMs DESC;
GO

PRINT '';
PRINT 'Test log queries completed!';
