# MCP Server Setup for SQL Server Docker Containers

This document describes the Model Context Protocol (MCP) server configuration for interacting with both SQL Server Docker containers in this project.

## Overview

MCP servers have been configured to provide seamless access to both SQL Server containers:
- **sql-server-dev**: Development container (port 1433)
- **sql-server-test**: Test container with tSQLt framework (port 1434)

## Configuration Location

The MCP configuration is stored in:
```
/home/codespace/.claude/settings.json
```

## MCP Servers

### 1. SQL Server Development Container (`sql-server-dev`)

**Container**: `sqlserver2025`
**Port**: 1433
**Purpose**: Primary development database

**Connection Details**:
- Host: localhost (via docker exec)
- Username: SA
- Password: YourStrong@Passw0rd
- Trust Server Certificate: Yes (-C flag)

**Command**:
```bash
docker exec -i sqlserver2025 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -C
```

### 2. SQL Server Test Container (`sql-server-test`)

**Container**: `sqlserver2025-test`
**Port**: 1434
**Purpose**: Testing environment with tSQLt framework

**Connection Details**:
- Host: localhost (via docker exec)
- Username: SA
- Password: YourStrong@Passw0rd
- Trust Server Certificate: Yes (-C flag)
- tSQLt Version: 1.0.8083.3529

**Command**:
```bash
docker exec -i sqlserver2025-test /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -C
```

## Permissions

The configuration includes automatic approval for `docker exec` commands, allowing agents to interact with SQL Server containers without requiring manual permission for each command.

**Allowed Commands**:
```json
{
  "command": "docker",
  "args": ["exec", "*"],
  "description": "Allow docker exec commands for SQL Server containers"
}
```

## Usage Examples

### Using MCP Servers with Claude Code

Agents can now execute SQL commands directly against either container:

#### Query Development Container:
```bash
docker exec -i sqlserver2025 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -C -Q "SELECT * FROM sys.databases;"
```

#### Query Test Container:
```bash
docker exec -i sqlserver2025-test /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -C -Q "SELECT * FROM sys.databases;"
```

#### Run tSQLt Tests (Test Container Only):
```bash
docker exec -i sqlserver2025-test /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -C -d SampleDatabase_Test -Q "EXEC tSQLt.RunAll;"
```

### Interactive SQL Sessions

You can also start interactive sqlcmd sessions:

```bash
docker exec -it sqlserver2025 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -C
```

## Container Status

Check if containers are running:
```bash
docker ps --filter "name=sqlserver2025"
```

Expected output:
```
NAMES                STATUS                       PORTS
sqlserver2025-test   Up (healthy)                 0.0.0.0:1434->1433/tcp
sqlserver2025        Up                           0.0.0.0:1433->1433/tcp
```

## Common Tasks

### 1. List Databases

**Dev Container**:
```bash
docker exec sqlserver2025 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -C -Q "SELECT name, database_id, create_date FROM sys.databases ORDER BY name;"
```

**Test Container**:
```bash
docker exec sqlserver2025-test /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -C -Q "SELECT name, database_id, create_date FROM sys.databases ORDER BY name;"
```

### 2. Check tSQLt Installation (Test Container)

```bash
docker exec sqlserver2025-test /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -C -Q "SELECT OBJECT_ID('tSQLt.Version') AS tSQLtInstalled;"
```

### 3. Execute Script Files

**Dev Container**:
```bash
docker exec -i sqlserver2025 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -C -i /path/to/script.sql
```

**Test Container**:
```bash
docker exec -i sqlserver2025-test /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -C -i /path/to/script.sql
```

## Security Considerations

### Current Configuration
- SA account is used with a strong password
- Containers run on localhost only
- Trust Server Certificate is enabled for development

### Production Recommendations
For production environments, consider:
1. Use Azure AD authentication instead of SA account
2. Enable SSL/TLS with valid certificates
3. Implement least-privilege access with specific user accounts
4. Use Azure Key Vault or similar for secret management
5. Enable SQL Server audit logging
6. Restrict docker exec access to specific containers

## Troubleshooting

### Container Not Running
```bash
docker-compose up -d
docker ps
```

### Connection Failed
```bash
# Check container logs
docker logs sqlserver2025
docker logs sqlserver2025-test

# Verify SQL Server is ready
docker exec sqlserver2025 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStrong@Passw0rd' -C -Q "SELECT 1;"
```

### Permission Denied
Ensure the MCP configuration is in place:
```bash
cat /home/codespace/.claude/settings.json
```

## Related Documentation

- [README.md](README.md) - Project overview and quick start
- [TSQLT_TESTING.md](TSQLT_TESTING.md) - tSQLt testing framework guide
- [SampleDatabase/DEPLOYMENT.md](SampleDatabase/DEPLOYMENT.md) - Database deployment guide
- [TEST_LOGGING.md](TEST_LOGGING.md) - Test logging system documentation

## MCP Server Configuration

The complete MCP server configuration is managed in `/home/codespace/.claude/settings.json`:

```json
{
  "mcpServers": {
    "sql-server-dev": {
      "command": "docker",
      "args": [
        "exec",
        "-i",
        "sqlserver2025",
        "/opt/mssql-tools18/bin/sqlcmd",
        "-S",
        "localhost",
        "-U",
        "SA",
        "-P",
        "YourStrong@Passw0rd",
        "-C"
      ],
      "description": "MCP server for SQL Server 2025 development container (port 1433)"
    },
    "sql-server-test": {
      "command": "docker",
      "args": [
        "exec",
        "-i",
        "sqlserver2025-test",
        "/opt/mssql-tools18/bin/sqlcmd",
        "-S",
        "localhost",
        "-U",
        "SA",
        "-P",
        "YourStrong@Passw0rd",
        "-C"
      ],
      "description": "MCP server for SQL Server 2025 test container with tSQLt (port 1434)"
    }
  },
  "allowedBashCommands": [
    {
      "command": "docker",
      "args": ["exec", "*"],
      "description": "Allow docker exec commands for SQL Server containers"
    }
  ]
}
```

## Support

For issues or questions:
- Check container logs: `docker logs <container-name>`
- Review Docker Compose configuration: [docker-compose.yml](docker-compose.yml)
- Verify containers are healthy: `docker ps`
