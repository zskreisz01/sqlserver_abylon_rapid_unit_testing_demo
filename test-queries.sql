-- SQL Server 2025 Test Queries
-- Run these queries to verify the SQL Server installation

-- 1. Get SQL Server version
SELECT @@VERSION AS SQLServerVersion;

-- 2. Get current date/time and server info
SELECT
    GETDATE() AS CurrentDateTime,
    @@SERVERNAME AS ServerName,
    SERVERPROPERTY('Edition') AS Edition,
    SERVERPROPERTY('ProductVersion') AS ProductVersion,
    SERVERPROPERTY('ProductLevel') AS ProductLevel;

-- 3. List all databases
SELECT
    name AS DatabaseName,
    database_id AS DatabaseID,
    create_date AS CreatedDate,
    state_desc AS State
FROM sys.databases
ORDER BY name;

-- 4. Simple calculation test
SELECT
    1 + 1 AS SimpleAddition,
    10 * 5 AS Multiplication,
    POWER(2, 10) AS PowerOfTwo;

-- 5. String manipulation test
SELECT
    'Hello, SQL Server 2025!' AS Greeting,
    LEN('SQL Server') AS StringLength,
    UPPER('hello world') AS UpperCase,
    LOWER('HELLO WORLD') AS LowerCase;
