-- Enable CLR for tSQLt (Required for Linux/Docker)
USE master;
GO

-- Enable advanced options
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
GO

-- Enable CLR
EXEC sp_configure 'clr enabled', 1;
RECONFIGURE;
GO

-- Disable CLR strict security (Required for Linux)
EXEC sp_configure 'clr strict security', 0;
RECONFIGURE;
GO

-- Verify configuration
PRINT 'Verifying CLR configuration...';
EXEC sp_configure 'clr enabled';
EXEC sp_configure 'clr strict security';
GO

PRINT 'CLR configuration completed successfully';
GO
