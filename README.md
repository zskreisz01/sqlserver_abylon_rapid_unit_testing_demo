# SQL Server 2025 Docker Setup

This project successfully sets up SQL Server 2025 in GitHub Codespaces using Docker Compose with the official Microsoft image.

## Project Structure

### Docker Setup
- [docker-compose.yml](docker-compose.yml) - Docker Compose configuration
- [Dockerfile](Dockerfile) - Custom Dockerfile based on official SQL Server 2025 image
- [test-queries.sql](test-queries.sql) - Sample SQL queries for testing

### SQL Database Project
- [SampleDatabase/](SampleDatabase/) - SQL Server Database Project (.sqlproj)
  - [Tables/](SampleDatabase/Tables/) - Table definitions (Customers, Orders, Products)
  - [StoredProcedures/](SampleDatabase/StoredProcedures/) - Stored procedures
  - [Views/](SampleDatabase/Views/) - Database views
  - [DEPLOYMENT.md](SampleDatabase/DEPLOYMENT.md) - Complete deployment guide
  - [SampleDatabase.sqlproj](SampleDatabase/SampleDatabase.sqlproj) - Project file
  - `bin/Debug/SampleDatabase.dacpac` - Generated dacpac file (after build)

### tSQLt Unit Testing
- [TSQLT_TESTING.md](TSQLT_TESTING.md) - Complete tSQLt testing guide
- [tsqlt-framework/](tsqlt-framework/) - tSQLt framework files
- [deploy-tsqlt-tests.sh](deploy-tsqlt-tests.sh) - Deploy test cases script
- [run-tsqlt-tests.sh](run-tsqlt-tests.sh) - Run all tests script
- Test environment on port 1434 with tSQLt v1.0.8083.3529 installed

## Quick Start

1. Start SQL Server container:
```bash
docker-compose up -d
```

2. Check container status:
```bash
docker ps
```

3. View logs:
```bash
docker logs sqlserver2025
```

4. Run a query:
```bash
docker exec sqlserver2025 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -C -Q "SELECT @@VERSION;"
```

## Connection Details

- **Host**: localhost
- **Port**: 1433
- **Username**: SA
- **Password**: YourStrong@Passw0rd
- **Edition**: Enterprise Developer Edition (64-bit)
- **Version**: SQL Server 2025 (RTM) - 17.0.1000.7

## Stopping the Container

```bash
docker-compose down
```

To remove volumes as well:
```bash
docker-compose down -v
```

## SQL Database Project (DACPAC Deployment)

This project includes a complete SQL Server Database Project with dacpac deployment support.

### Quick Start

1. **Build the project:**
```bash
cd SampleDatabase
dotnet build
```

2. **Deploy using sqlpackage:**
```bash
export PATH="$HOME/.dotnet:$PATH"
export DOTNET_ROOT="$HOME/.dotnet"

sqlpackage /Action:Publish \
  /SourceFile:bin/Debug/SampleDatabase.dacpac \
  /TargetConnectionString:"Server=localhost,1433;Database=SampleDatabase;User Id=SA;Password=YourStrong@Passw0rd;TrustServerCertificate=True;"
```

3. **Verify deployment:**
```bash
docker exec sqlserver2025 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -d SampleDatabase -C -Q "SELECT * FROM Customers;"
```

### Database Schema

**Tables:**
- `Customers` - Customer information with email and phone
- `Orders` - Customer orders with foreign key relationship
- `Products` - Product catalog with pricing and inventory

**Stored Procedures:**
- `usp_AddCustomer` - Add new customer
- `usp_GetCustomerOrders` - Get all orders for a customer

**Views:**
- `vw_CustomerOrderSummary` - Aggregated customer order statistics

For detailed deployment instructions, see [SampleDatabase/DEPLOYMENT.md](SampleDatabase/DEPLOYMENT.md)

## Unit Testing with tSQLt

This project includes a separate test environment with tSQLt framework installed for automated database unit testing.

### Test Environment

- **Test Server**: `sqlserver2025-test` on port 1434
- **Test Database**: `SampleDatabase_Test`
- **tSQLt Version**: 1.0.8083.3529
- **CLR Enabled**: Yes (configured for Linux/Docker)

### Quick Start

1. **Start test server:**
```bash
docker-compose up -d sqlserver-test
```

2. **Deploy test cases:**
```bash
./deploy-tsqlt-tests.sh
```

3. **Run all tests:**
```bash
./run-tsqlt-tests.sh
```

### Test Results Example

```
Test Case Summary: 3 test case(s) executed, 3 succeeded, 0 failed
- CustomerTests: test Customer insertion creates record with all fields ✓
- ProductTests: test Product has correct default values ✓
- ViewTests: test vw_CustomerOrderSummary calculates totals correctly ✓
```

### Available Tests

- **CustomerTests**: Validates customer insertion and stored procedures
- **ProductTests**: Validates product defaults and constraints
- **ViewTests**: Validates view aggregation logic

For complete testing documentation, see [TSQLT_TESTING.md](TSQLT_TESTING.md)

## Official Documentation

### SQL Server & Docker
- Image: `mcr.microsoft.com/mssql/server:2025-latest`
- [Microsoft Learn - SQL Server on Docker](https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker)
- [GitHub - mssql-docker](https://github.com/microsoft/mssql-docker)

### SQL Database Projects
- [Microsoft Learn - SQL Database Projects](https://learn.microsoft.com/en-us/sql/tools/sql-database-projects/sql-database-projects)
- [Microsoft Learn - Create and Deploy SQL Project](https://learn.microsoft.com/en-us/sql/tools/sql-database-projects/tutorials/create-deploy-sql-project)

### tSQLt Unit Testing
- [tSQLt Official Website](https://tsqlt.org/)
- [tSQLt Downloads](https://tsqlt.org/downloads/)
- [tSQLt GitHub Repository](https://github.com/tSQLt-org/tSQLt)
- [SQL Server Unit Testing with tSQLt and Docker](https://www.sqlservercentral.com/blogs/how-to-use-tsqlt-unit-test-framework-with-a-sql-server-database-in-a-docker-container)


