#!/bin/bash
# Complete SQL Server Database Project Deployment and Test Script

set -e  # Exit on error

echo "================================================"
echo "SQL Server 2025 Database Project Deployment"
echo "================================================"
echo ""

# Step 1: Ensure SQL Server is running
echo "[1/6] Checking SQL Server status..."
docker ps | grep sqlserver2025 || {
    echo "Error: SQL Server container is not running!"
    echo "Please start it with: docker-compose up -d"
    exit 1
}
echo "✓ SQL Server is running"
echo ""

# Step 2: Build the SQL Database Project
echo "[2/6] Building SQL Database Project..."
cd SampleDatabase
dotnet build
echo "✓ Build completed - dacpac generated"
echo ""

# Step 3: Set up .NET environment for sqlpackage
echo "[3/6] Setting up .NET environment..."
export PATH="$HOME/.dotnet:$PATH"
export DOTNET_ROOT="$HOME/.dotnet"
echo "✓ Environment configured"
echo ""

# Step 4: Deploy using sqlpackage
echo "[4/6] Deploying database using sqlpackage..."
sqlpackage /Action:Publish \
  /SourceFile:bin/Debug/SampleDatabase.dacpac \
  /TargetConnectionString:"Server=localhost,1433;Database=SampleDatabase;User Id=SA;Password=YourStrong@Passw0rd;TrustServerCertificate=True;"
echo "✓ Database deployed successfully"
echo ""

# Step 5: Insert test data
echo "[5/6] Inserting test data..."
docker exec sqlserver2025 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -d SampleDatabase -C -Q "
INSERT INTO Customers (FirstName, LastName, Email, PhoneNumber) VALUES
('John', 'Doe', 'john.doe@example.com', '555-1234'),
('Jane', 'Smith', 'jane.smith@example.com', '555-5678'),
('Bob', 'Johnson', 'bob.johnson@example.com', '555-9999');

INSERT INTO Products (ProductName, Description, Price, StockQuantity) VALUES
('Laptop', 'High-performance laptop', 1299.99, 50),
('Mouse', 'Wireless mouse', 29.99, 200),
('Keyboard', 'Mechanical keyboard', 89.99, 150);

INSERT INTO Orders (CustomerId, TotalAmount, Status, ShippingAddress) VALUES
(1, 1299.99, 'Completed', '123 Main St'),
(2, 29.99, 'Pending', '456 Oak Ave'),
(1, 89.99, 'Completed', '123 Main St');
" > /dev/null
echo "✓ Test data inserted"
echo ""

# Step 6: Run verification queries
echo "[6/6] Running verification queries..."
echo ""

echo "--- Customers Table ---"
docker exec sqlserver2025 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -d SampleDatabase -C -Q "SELECT CustomerId, FirstName, LastName, Email FROM Customers;"
echo ""

echo "--- Products Table ---"
docker exec sqlserver2025 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -d SampleDatabase -C -Q "SELECT ProductId, ProductName, Price, StockQuantity FROM Products;"
echo ""

echo "--- Orders Table ---"
docker exec sqlserver2025 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -d SampleDatabase -C -Q "SELECT OrderId, CustomerId, TotalAmount, Status FROM Orders;"
echo ""

echo "--- Customer Order Summary View ---"
docker exec sqlserver2025 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -d SampleDatabase -C -Q "SELECT CustomerId, FirstName, LastName, TotalOrders, TotalSpent FROM vw_CustomerOrderSummary;"
echo ""

echo "--- Testing Stored Procedure (Customer ID 1) ---"
docker exec sqlserver2025 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -d SampleDatabase -C -Q "EXEC usp_GetCustomerOrders @CustomerId = 1;"
echo ""

echo "================================================"
echo "✓ Deployment and verification completed!"
echo "================================================"
echo ""
echo "Database 'SampleDatabase' is ready to use."
echo "Connection string: Server=localhost,1433;Database=SampleDatabase;User Id=SA;Password=YourStrong@Passw0rd;TrustServerCertificate=True"
