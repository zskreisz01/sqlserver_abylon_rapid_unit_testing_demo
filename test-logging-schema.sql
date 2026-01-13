-- =============================================
-- Test Logging Schema for tSQLt
-- =============================================
-- This script creates a comprehensive logging system for tSQLt test runs

USE SampleDatabase_Test;
GO

-- Create schema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'TestLog')
BEGIN
    EXEC('CREATE SCHEMA TestLog');
END
GO

-- =============================================
-- Table: TestSession
-- Logs test execution sessions with timestamps
-- =============================================
IF OBJECT_ID('TestLog.TestSession', 'U') IS NULL
BEGIN
    CREATE TABLE TestLog.TestSession (
        SessionId INT IDENTITY(1,1) PRIMARY KEY,
        Command NVARCHAR(500) NOT NULL,
        StartTimestamp DATETIME2 NOT NULL DEFAULT GETDATE(),
        EndTimestamp DATETIME2 NULL,
        TotalTests INT NULL,
        PassedTests INT NULL,
        FailedTests INT NULL,
        SkippedTests INT NULL,
        ErroredTests INT NULL,
        DurationMs INT NULL,
        ExecutedBy NVARCHAR(128) NOT NULL DEFAULT SYSTEM_USER,
        MachineName NVARCHAR(128) NULL DEFAULT @@SERVERNAME,
        Status NVARCHAR(50) NOT NULL DEFAULT 'Running',
        Notes NVARCHAR(MAX) NULL
    );
END
GO

-- =============================================
-- Table: TestRun
-- Logs individual test results
-- =============================================
IF OBJECT_ID('TestLog.TestRun', 'U') IS NULL
BEGIN
    CREATE TABLE TestLog.TestRun (
        TestRunId INT IDENTITY(1,1) PRIMARY KEY,
        SessionId INT NOT NULL,
        TestClass NVARCHAR(255) NOT NULL,
        TestName NVARCHAR(255) NOT NULL,
        Result NVARCHAR(20) NOT NULL,
        DurationMs INT NULL,
        ErrorMessage NVARCHAR(MAX) NULL,
        TestStartTime DATETIME2 NOT NULL DEFAULT GETDATE(),
        TestEndTime DATETIME2 NULL,
        CONSTRAINT FK_TestRun_Session FOREIGN KEY (SessionId)
            REFERENCES TestLog.TestSession(SessionId)
    );

    CREATE INDEX IX_TestRun_SessionId ON TestLog.TestRun(SessionId);
    CREATE INDEX IX_TestRun_Result ON TestLog.TestRun(Result);
    CREATE INDEX IX_TestRun_TestClass ON TestLog.TestRun(TestClass);
END
GO

-- =============================================
-- Stored Procedure: StartTestSession
-- Starts a new test session
-- =============================================
IF OBJECT_ID('TestLog.StartTestSession', 'P') IS NOT NULL
    DROP PROCEDURE TestLog.StartTestSession;
GO

CREATE PROCEDURE TestLog.StartTestSession
    @Command NVARCHAR(500),
    @SessionId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO TestLog.TestSession (Command, StartTimestamp, Status)
    VALUES (@Command, GETDATE(), 'Running');

    SET @SessionId = SCOPE_IDENTITY();
END;
GO

-- =============================================
-- Stored Procedure: EndTestSession
-- Ends a test session and calculates summary
-- =============================================
IF OBJECT_ID('TestLog.EndTestSession', 'P') IS NOT NULL
    DROP PROCEDURE TestLog.EndTestSession;
GO

CREATE PROCEDURE TestLog.EndTestSession
    @SessionId INT,
    @Notes NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTime DATETIME2;
    SELECT @StartTime = StartTimestamp FROM TestLog.TestSession WHERE SessionId = @SessionId;

    UPDATE TestLog.TestSession
    SET
        EndTimestamp = GETDATE(),
        DurationMs = DATEDIFF(MILLISECOND, @StartTime, GETDATE()),
        TotalTests = (SELECT COUNT(*) FROM TestLog.TestRun WHERE SessionId = @SessionId),
        PassedTests = (SELECT COUNT(*) FROM TestLog.TestRun WHERE SessionId = @SessionId AND Result = 'Success'),
        FailedTests = (SELECT COUNT(*) FROM TestLog.TestRun WHERE SessionId = @SessionId AND Result = 'Failure'),
        SkippedTests = (SELECT COUNT(*) FROM TestLog.TestRun WHERE SessionId = @SessionId AND Result = 'Skipped'),
        ErroredTests = (SELECT COUNT(*) FROM TestLog.TestRun WHERE SessionId = @SessionId AND Result = 'Error'),
        Status = CASE
            WHEN EXISTS (SELECT 1 FROM TestLog.TestRun WHERE SessionId = @SessionId AND Result IN ('Failure', 'Error'))
            THEN 'Completed with Failures'
            ELSE 'Completed Successfully'
        END,
        Notes = @Notes
    WHERE SessionId = @SessionId;
END;
GO

-- =============================================
-- Stored Procedure: LogTestResult
-- Logs an individual test result
-- =============================================
IF OBJECT_ID('TestLog.LogTestResult', 'P') IS NOT NULL
    DROP PROCEDURE TestLog.LogTestResult;
GO

CREATE PROCEDURE TestLog.LogTestResult
    @SessionId INT,
    @TestClass NVARCHAR(255),
    @TestName NVARCHAR(255),
    @Result NVARCHAR(20),
    @DurationMs INT = NULL,
    @ErrorMessage NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO TestLog.TestRun (
        SessionId,
        TestClass,
        TestName,
        Result,
        DurationMs,
        ErrorMessage,
        TestStartTime,
        TestEndTime
    )
    VALUES (
        @SessionId,
        @TestClass,
        @TestName,
        @Result,
        @DurationMs,
        @ErrorMessage,
        DATEADD(MILLISECOND, -ISNULL(@DurationMs, 0), GETDATE()),
        GETDATE()
    );
END;
GO

-- =============================================
-- Stored Procedure: RunTestsWithLogging
-- Runs tests and automatically logs results
-- =============================================
IF OBJECT_ID('TestLog.RunTestsWithLogging', 'P') IS NOT NULL
    DROP PROCEDURE TestLog.RunTestsWithLogging;
GO

CREATE PROCEDURE TestLog.RunTestsWithLogging
    @TestClass NVARCHAR(255) = NULL,
    @SessionId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Command NVARCHAR(500);

    IF @TestClass IS NULL
        SET @Command = 'EXEC tSQLt.RunAll';
    ELSE
        SET @Command = 'EXEC tSQLt.Run ''' + @TestClass + '''';

    EXEC TestLog.StartTestSession @Command, @SessionId OUTPUT;

    TRUNCATE TABLE tSQLt.TestResult;

    BEGIN TRY
        IF @TestClass IS NULL
            EXEC tSQLt.RunAll;
        ELSE
            EXEC tSQLt.Run @TestClass;
    END TRY
    BEGIN CATCH
        UPDATE TestLog.TestSession
        SET Notes = 'Error during test execution: ' + ERROR_MESSAGE()
        WHERE SessionId = @SessionId;
    END CATCH

    INSERT INTO TestLog.TestRun (SessionId, TestClass, TestName, Result, ErrorMessage, TestStartTime, TestEndTime)
    SELECT
        @SessionId,
        Class,
        TestCase,
        Result,
        Msg,
        TestStartTime,
        DATEADD(MILLISECOND, ISNULL(TRY_CAST(SUBSTRING(Result, 1, 10) AS INT), 0), TestStartTime)
    FROM tSQLt.TestResult;

    EXEC TestLog.EndTestSession @SessionId;

    SELECT
        SessionId,
        Command,
        StartTimestamp,
        EndTimestamp,
        DurationMs,
        TotalTests,
        PassedTests,
        FailedTests,
        Status
    FROM TestLog.TestSession
    WHERE SessionId = @SessionId;
END;
GO

-- =============================================
-- View: vw_TestSessionSummary
-- Session summary with pass rate
-- =============================================
IF OBJECT_ID('TestLog.vw_TestSessionSummary', 'V') IS NOT NULL
    DROP VIEW TestLog.vw_TestSessionSummary;
GO

CREATE VIEW TestLog.vw_TestSessionSummary
AS
SELECT
    s.SessionId,
    s.Command,
    s.StartTimestamp,
    s.EndTimestamp,
    s.DurationMs,
    CAST(s.DurationMs / 1000.0 AS DECIMAL(10,2)) AS DurationSeconds,
    s.TotalTests,
    s.PassedTests,
    s.FailedTests,
    s.SkippedTests,
    s.ErroredTests,
    CASE
        WHEN s.TotalTests > 0
        THEN CAST((s.PassedTests * 100.0 / s.TotalTests) AS DECIMAL(5,2))
        ELSE 0
    END AS PassRate,
    s.Status,
    s.ExecutedBy,
    s.MachineName,
    s.Notes
FROM TestLog.TestSession s;
GO

-- =============================================
-- View: vw_TestRunDetails
-- Detailed test results with session info
-- =============================================
IF OBJECT_ID('TestLog.vw_TestRunDetails', 'V') IS NOT NULL
    DROP VIEW TestLog.vw_TestRunDetails;
GO

CREATE VIEW TestLog.vw_TestRunDetails
AS
SELECT
    tr.TestRunId,
    tr.SessionId,
    s.Command AS SessionCommand,
    s.StartTimestamp AS SessionStartTime,
    tr.TestClass,
    tr.TestName,
    tr.Result,
    tr.DurationMs,
    tr.ErrorMessage,
    tr.TestStartTime,
    tr.TestEndTime
FROM TestLog.TestRun tr
INNER JOIN TestLog.TestSession s ON tr.SessionId = s.SessionId;
GO

PRINT 'Test logging schema created successfully!';
GO
