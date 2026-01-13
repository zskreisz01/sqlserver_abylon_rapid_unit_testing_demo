# SQL Database Project Deployment Guide

This document describes how to build and deploy the SampleDatabase SQL Server Database Project using dacpac and sqlpackage.

## Prerequisites

- .NET SDK 10.0+ (for building)
- .NET Runtime 8.0+ (for sqlpackage)
- SQL Server 2025 running (via Docker or other)
- Microsoft.Build.Sql.Templates installed
- Microsoft.SqlPackage tool installed

## Project Structure

```
SampleDatabase/
├── SampleDatabase.sqlproj          # Project file
├── Tables/
│   ├── Customers.sql                # Customer table definition
│   ├── Orders.sql                   # Orders table with foreign key
│   └── Products.sql                 # Products table
├── StoredProcedures/
│   ├── usp_AddCustomer.sql          # Add customer procedure
│   └── usp_GetCustomerOrders.sql    # Get customer orders procedure
├── Views/
│   └── vw_CustomerOrderSummary.sql  # Customer order summary view
└── bin/Debug/
    └── SampleDatabase.dacpac        # Generated dacpac file (after build)
```

## Installation Steps

### 1. Install Required Tools

```bash
# Install SQL Database Project templates
dotnet new install Microsoft.Build.Sql.Templates

# Install sqlpackage CLI tool
dotnet tool install -g Microsoft.SqlPackage

# Install .NET 8 runtime if needed
curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel 8.0 --runtime dotnet
```

### 2. Build the Project

```bash
cd SampleDatabase
dotnet build
```

**Output:** `bin/Debug/SampleDatabase.dacpac` (3.9 KB)

### 3. Deploy Using SqlPackage

```bash
# Set up environment (if .NET 8 was installed locally)
export PATH="$HOME/.dotnet:$PATH"
export DOTNET_ROOT="$HOME/.dotnet"

# Deploy to SQL Server
sqlpackage /Action:Publish \
  /SourceFile:bin/Debug/SampleDatabase.dacpac \
  /TargetConnectionString:"Server=localhost,1433;Database=SampleDatabase;User Id=SA;Password=YourStrong@Passw0rd;TrustServerCertificate=True;"
```

**Deployment Output:**
- Creates database `SampleDatabase` if it doesn't exist
- Creates 3 tables: Customers, Orders, Products
- Creates 2 stored procedures: usp_AddCustomer, usp_GetCustomerOrders
- Creates 1 view: vw_CustomerOrderSummary
- Creates all indexes and foreign key constraints

Time elapsed: ~22 seconds

## Verify Deployment

### Using sqlcmd (from host)

```bash
# Check database
docker exec sqlserver2025 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -d SampleDatabase -C -Q "SELECT DB_NAME() AS CurrentDatabase;"

# List tables
docker exec sqlserver2025 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -d SampleDatabase -C -Q "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE';"

# List stored procedures
docker exec sqlserver2025 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -d SampleDatabase -C -Q "SELECT ROUTINE_NAME FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE';"

# List views
docker exec sqlserver2025 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -d SampleDatabase -C -Q "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS;"
```

### Test Data

```bash
# Insert test customers
docker exec sqlserver2025 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -d SampleDatabase -C -Q "INSERT INTO Customers (FirstName, LastName, Email, PhoneNumber) VALUES ('John', 'Doe', 'john.doe@example.com', '555-1234');"

# Query customers
docker exec sqlserver2025 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -d SampleDatabase -C -Q "SELECT * FROM Customers;"

# Test stored procedure
docker exec sqlserver2025 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -d SampleDatabase -C -Q "EXEC usp_GetCustomerOrders @CustomerId = 1;"

# Test view
docker exec sqlserver2025 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -d SampleDatabase -C -Q "SELECT * FROM vw_CustomerOrderSummary;"
```

## Database Schema

### Tables

**Customers**
- CustomerId (INT, PK, IDENTITY)
- FirstName (NVARCHAR(50))
- LastName (NVARCHAR(50))
- Email (NVARCHAR(100), indexed)
- PhoneNumber (NVARCHAR(20), nullable)
- CreatedDate (DATETIME2)
- ModifiedDate (DATETIME2)

**Orders**
- OrderId (INT, PK, IDENTITY)
- CustomerId (INT, FK to Customers)
- OrderDate (DATETIME2, indexed)
- TotalAmount (DECIMAL(18,2))
- Status (NVARCHAR(20))
- ShippingAddress (NVARCHAR(200), nullable)
- CreatedDate (DATETIME2)

**Products**
- ProductId (INT, PK, IDENTITY)
- ProductName (NVARCHAR(100), indexed)
- Description (NVARCHAR(500), nullable)
- Price (DECIMAL(18,2))
- StockQuantity (INT)
- IsActive (BIT)
- CreatedDate (DATETIME2)
- ModifiedDate (DATETIME2)

### Stored Procedures

- **usp_AddCustomer**: Adds a new customer and returns the CustomerId
- **usp_GetCustomerOrders**: Gets all orders for a specific customer

### Views

- **vw_CustomerOrderSummary**: Aggregates customer order data including total orders, total spent, and last order date

## Rebuilding and Redeploying

The dacpac deployment is idempotent. Running the deployment again will:
- Detect existing objects
- Only apply changes (ALTER statements)
- Not drop existing data

```bash
# Make changes to SQL files
# Rebuild
dotnet build

# Redeploy
sqlpackage /Action:Publish /SourceFile:bin/Debug/SampleDatabase.dacpac /TargetConnectionString:"..."
```

## CI/CD Integration

This project can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Build Database Project
  run: dotnet build SampleDatabase/SampleDatabase.sqlproj

- name: Deploy to SQL Server
  run: |
    sqlpackage /Action:Publish \
      /SourceFile:SampleDatabase/bin/Debug/SampleDatabase.dacpac \
      /TargetConnectionString:"${{ secrets.SQL_CONNECTION_STRING }}"
```

## Troubleshooting

**Issue: SqlPackage requires .NET 8 runtime**
```bash
# Install .NET 8 runtime
curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel 8.0 --runtime dotnet

# Update PATH
export PATH="$HOME/.dotnet:$PATH"
export DOTNET_ROOT="$HOME/.dotnet"
```

**Issue: Duplicate Build items error**
- The SDK automatically includes .sql files
- Remove explicit `<Build Include="...">` items from .sqlproj
- Let the SDK auto-discover SQL files

## References

- [Microsoft Learn - SQL Database Projects](https://learn.microsoft.com/en-us/sql/tools/sql-database-projects/sql-database-projects)
- [Microsoft Learn - Create and Deploy SQL Project](https://learn.microsoft.com/en-us/sql/tools/sql-database-projects/tutorials/create-deploy-sql-project)
- [SqlPackage Documentation](https://learn.microsoft.com/en-us/sql/tools/sqlpackage)
