#!/bin/bash
# Setup tSQLt Framework for SQL Server Test Environment

set -e  # Exit on error

echo "================================================"
echo "tSQLt Framework Setup Script"
echo "================================================"
echo ""

TSQLT_VERSION="latest"
TSQLT_DIR="tsqlt-framework"
TSQLT_ZIP="tSQLt.zip"

# Step 1: Download tSQLt
echo "[1/5] Downloading tSQLt framework..."
mkdir -p $TSQLT_DIR
cd $TSQLT_DIR

# Download from SourceForge (latest stable version)
if [ ! -f "$TSQLT_ZIP" ]; then
    echo "Downloading tSQLt from SourceForge..."
    curl -L -o $TSQLT_ZIP "https://downloads.sourceforge.net/project/tsqlt/tSQLt.zip"
    echo "✓ Downloaded tSQLt.zip"
else
    echo "✓ tSQLt.zip already exists"
fi
echo ""

# Step 2: Extract tSQLt
echo "[2/5] Extracting tSQLt..."
if [ ! -d "extracted" ]; then
    mkdir -p extracted
    unzip -q $TSQLT_ZIP -d extracted
    echo "✓ Extracted tSQLt files"
else
    echo "✓ tSQLt already extracted"
fi
echo ""

# Step 3: Modify tSQLt.class.sql for Linux/Docker
echo "[3/5] Modifying tSQLt.class.sql for Docker/Linux compatibility..."
if [ -f "extracted/tSQLt.class.sql" ]; then
    # Create a modified version for Docker/Linux
    sed 's/PERMISSION_SET = EXTERNAL_ACCESS/PERMISSION_SET = SAFE/g' extracted/tSQLt.class.sql > extracted/tSQLt.class.docker.sql
    echo "✓ Created tSQLt.class.docker.sql with PERMISSION_SET = SAFE"
else
    echo "⚠ Warning: tSQLt.class.sql not found in expected location"
    echo "Listing extracted contents:"
    ls -la extracted/
fi
echo ""

# Step 4: Create CLR configuration script
echo "[4/5] Creating CLR configuration script..."
cat > enable-clr.sql << 'EOF'
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

-- Show configuration
EXEC sp_configure 'clr enabled';
EXEC sp_configure 'clr strict security';
GO

PRINT 'CLR configuration completed successfully';
GO
EOF
echo "✓ Created enable-clr.sql"
echo ""

# Step 5: Create installation script
echo "[5/5] Creating tSQLt installation script..."
cat > install-tsqlt.sql << 'EOF'
-- Install tSQLt Framework
USE master;
GO

-- Create test database if it doesn't exist
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'SampleDatabase_Test')
BEGIN
    CREATE DATABASE SampleDatabase_Test;
    PRINT 'Created SampleDatabase_Test database';
END
ELSE
BEGIN
    PRINT 'SampleDatabase_Test database already exists';
END
GO

USE SampleDatabase_Test;
GO

PRINT 'Installing tSQLt framework...';
GO
EOF
echo "✓ Created install-tsqlt.sql"
echo ""

cd ..

echo "================================================"
echo "✓ tSQLt setup completed!"
echo "================================================"
echo ""
echo "Next steps:"
echo "1. Start the test SQL Server: docker-compose up -d sqlserver-test"
echo "2. Wait for container to be healthy"
echo "3. Run: ./install-tsqlt-to-server.sh"
echo ""
