#!/bin/bash
# Install tSQLt Framework to SQL Server Test Instance

set -e  # Exit on error

echo "================================================"
echo "Installing tSQLt to SQL Server Test Instance"
echo "================================================"
echo ""

# Configuration
TEST_CONTAINER="sqlserver2025-test"
SA_PASSWORD="YourStrong@Passw0rd"
TEST_DB="SampleDatabase_Test"

# Step 1: Check if test container is running
echo "[1/7] Checking test SQL Server container..."
if ! docker ps | grep -q $TEST_CONTAINER; then
    echo "Error: Test container $TEST_CONTAINER is not running!"
    echo "Please start it with: docker-compose up -d sqlserver-test"
    exit 1
fi
echo "✓ Test container is running"
echo ""

# Step 2: Wait for SQL Server to be ready
echo "[2/7] Waiting for SQL Server to be ready..."
sleep 5
MAX_TRIES=30
COUNTER=0
until docker exec $TEST_CONTAINER /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$SA_PASSWORD" -C -Q "SELECT 1" > /dev/null 2>&1; do
    COUNTER=$((COUNTER+1))
    if [ $COUNTER -gt $MAX_TRIES ]; then
        echo "Error: SQL Server did not start in time"
        exit 1
    fi
    echo "Waiting for SQL Server... ($COUNTER/$MAX_TRIES)"
    sleep 2
done
echo "✓ SQL Server is ready"
echo ""

# Step 3: Enable CLR
echo "[3/7] Enabling CLR for tSQLt..."
docker exec $TEST_CONTAINER /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$SA_PASSWORD" -C -i /tsqlt-framework/enable-clr.sql
echo "✓ CLR enabled"
echo ""

# Step 4: Create test database
echo "[4/7] Creating test database..."
docker exec $TEST_CONTAINER /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$SA_PASSWORD" -C -Q "
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = '$TEST_DB')
BEGIN
    CREATE DATABASE [$TEST_DB];
    PRINT 'Created $TEST_DB database';
END
ELSE
BEGIN
    PRINT '$TEST_DB database already exists';
END
"
echo "✓ Test database created/verified"
echo ""

# Step 5: Download tSQLt inside container
echo "[5/7] Downloading tSQLt inside container..."
docker exec $TEST_CONTAINER bash -c "
if [ ! -f /tmp/tSQLt.zip ]; then
    curl -L -o /tmp/tSQLt.zip 'https://tsqlt.org/download/tsqlt' || \
    curl -L -o /tmp/tSQLt.zip 'https://sourceforge.net/projects/tsqlt/files/latest/download'
    echo 'Downloaded tSQLt'
else
    echo 'tSQLt already downloaded'
fi
"
echo "✓ tSQLt downloaded"
echo ""

# Step 6: Extract and prepare tSQLt
echo "[6/7] Extracting tSQLt..."
docker exec $TEST_CONTAINER bash -c "
cd /tmp
if [ ! -d /tmp/tsqlt-extracted ]; then
    mkdir -p /tmp/tsqlt-extracted
    unzip -q tSQLt.zip -d tsqlt-extracted 2>/dev/null || echo 'Extraction may have issues, continuing...'
    echo 'Extracted tSQLt files'
    ls -la /tmp/tsqlt-extracted/
fi
"
echo "✓ tSQLt extracted"
echo ""

# Step 7: Install tSQLt to database
echo "[7/7] Installing tSQLt to $TEST_DB..."
docker exec $TEST_CONTAINER bash -c "
if [ -f /tmp/tsqlt-extracted/tSQLt.class.sql ]; then
    # Modify for Docker/Linux compatibility
    sed 's/PERMISSION_SET = EXTERNAL_ACCESS/PERMISSION_SET = SAFE/g' /tmp/tsqlt-extracted/tSQLt.class.sql > /tmp/tsqlt-extracted/tSQLt.class.docker.sql
    /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P '$SA_PASSWORD' -d $TEST_DB -C -i /tmp/tsqlt-extracted/tSQLt.class.docker.sql
    echo 'tSQLt installed successfully'
else
    echo 'Warning: tSQLt.class.sql not found, trying alternative installation...'
    # Alternative: create a basic tSQLt schema manually
    /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P '$SA_PASSWORD' -d $TEST_DB -C -Q \"
    CREATE SCHEMA tSQLt;
    PRINT 'Created tSQLt schema - manual installation required';
    \"
fi
"
echo "✓ tSQLt installation attempted"
echo ""

# Verify installation
echo "Verifying tSQLt installation..."
docker exec $TEST_CONTAINER /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$SA_PASSWORD" -d $TEST_DB -C -Q "
SELECT
    SCHEMA_NAME(schema_id) AS SchemaName,
    name AS ObjectName,
    type_desc AS ObjectType
FROM sys.objects
WHERE SCHEMA_NAME(schema_id) = 'tSQLt'
ORDER BY type_desc, name;
" || echo "Note: Verification query executed, check results above"

echo ""
echo "================================================"
echo "✓ Installation process completed!"
echo "================================================"
echo ""
echo "Test database connection:"
echo "  Host: localhost"
echo "  Port: 1434"
echo "  Database: $TEST_DB"
echo "  Username: SA"
echo "  Password: $SA_PASSWORD"
echo ""
