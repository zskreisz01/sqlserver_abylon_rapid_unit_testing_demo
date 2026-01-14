# SQL Server Types Supported by tSQLt

## Overview

tSQLt is designed to work with Microsoft SQL Server, but not all editions and deployment types are equally supported. This document covers compatibility across different SQL Server environments.

## Fully Supported Environments

### SQL Server On-Premises

| Edition | Supported | Notes |
|---------|-----------|-------|
| Enterprise | Yes | Full support |
| Standard | Yes | Full support |
| Developer | Yes | Full support (recommended for testing) |
| Express | Yes | Full support, but size/resource limits apply |
| Web | Yes | Full support |

**Supported Versions:**
- SQL Server 2005 (with limitations)
- SQL Server 2008 / 2008 R2
- SQL Server 2012
- SQL Server 2014
- SQL Server 2016
- SQL Server 2017
- SQL Server 2019
- SQL Server 2022

### SQL Server in Containers

**Docker/Linux Containers:**
- Fully supported
- Uses SQL Server on Linux
- Great for CI/CD pipelines

```bash
# Example: Running SQL Server in Docker with tSQLt
docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=YourPassword" \
    -p 1433:1433 \
    mcr.microsoft.com/mssql/server:2022-latest
```

### SQL Server on Linux

- Fully supported since SQL Server 2017
- Same feature parity as Windows

## Azure SQL Database

### Standard Azure SQL Database

| Feature | Status | Notes |
|---------|--------|-------|
| Basic support | **Partial** | Requires configuration |
| CLR | **Not available** | Major limitation |
| tSQLt installation | **Modified** | Special Azure version needed |

**Key Limitations:**
- CLR (Common Language Runtime) is not supported in Azure SQL Database
- tSQLt uses CLR for some features
- A special "CLR-free" version exists but with reduced functionality

**What Works:**
- Basic test execution
- Most assertion methods
- Table faking

**What Doesn't Work:**
- `tSQLt.SpyProcedure` (requires CLR)
- Some advanced features

### Azure SQL Managed Instance

| Feature | Status | Notes |
|---------|--------|-------|
| Full support | **Yes** | CLR is available |
| tSQLt installation | **Standard** | Use normal tSQLt |
| All features | **Yes** | Full functionality |

**Azure SQL Managed Instance is the recommended Azure option** for tSQLt because:
- CLR is fully supported
- Near 100% compatibility with on-premises SQL Server
- All tSQLt features work

### Azure Synapse Analytics (formerly SQL DW)

| Feature | Status |
|---------|--------|
| tSQLt support | **No** |

Azure Synapse has a different architecture and doesn't support tSQLt.

## Compatibility Matrix

```
┌─────────────────────────────┬─────────┬─────────┬──────────────────┐
│ Environment                 │ Supported│ CLR    │ Recommendation   │
├─────────────────────────────┼─────────┼─────────┼──────────────────┤
│ SQL Server (all editions)   │    ✓    │   ✓    │ Fully supported  │
│ SQL Server on Linux         │    ✓    │   ✓    │ Fully supported  │
│ SQL Server in Docker        │    ✓    │   ✓    │ Great for CI/CD  │
│ Azure SQL Managed Instance  │    ✓    │   ✓    │ Best Azure option│
│ Azure SQL Database          │   ⚠️    │   ✗    │ Limited support  │
│ Azure Synapse Analytics     │    ✗    │   ✗    │ Not supported    │
│ Amazon RDS for SQL Server   │    ✓    │   ⚠️    │ May require setup│
│ Google Cloud SQL            │    ✓    │   ⚠️    │ May require setup│
└─────────────────────────────┴─────────┴─────────┴──────────────────┘
```

## CLR Dependency Explained

### What is CLR?

CLR (Common Language Runtime) allows SQL Server to execute .NET code. tSQLt uses CLR for:
- String comparison functions
- `SpyProcedure` functionality
- Some internal operations

### Enabling CLR

For on-premises SQL Server:
```sql
-- Enable CLR integration
sp_configure 'clr enabled', 1;
RECONFIGURE;

-- For SQL Server 2017+, you may also need:
sp_configure 'clr strict security', 0;
RECONFIGURE;
```

### Environments Without CLR

If you must use Azure SQL Database (without CLR):
1. Use the tSQLt Azure-compatible version
2. Avoid `SpyProcedure` functionality
3. Use alternative patterns for procedure mocking
4. Consider Azure SQL Managed Instance instead

## Recommendations by Scenario

### Local Development

**Recommended:** SQL Server Developer Edition or Docker

```bash
# Docker setup for local testing
docker run -d --name sqlserver-test \
    -e "ACCEPT_EULA=Y" \
    -e "SA_PASSWORD=StrongPass123!" \
    -p 1433:1433 \
    mcr.microsoft.com/mssql/server:2022-latest
```

### CI/CD Pipeline

**Recommended:** SQL Server in Docker containers

Advantages:
- Consistent environment
- Fast startup
- Disposable (each run starts fresh)
- Easy to integrate with GitHub Actions, Azure DevOps, etc.

### Cloud Production

**If using Azure:**
- **Azure SQL Managed Instance** for full tSQLt support
- **Azure SQL Database** only if CLR features aren't needed

**If using AWS:**
- **Amazon RDS for SQL Server** with CLR enabled

**If using GCP:**
- **Cloud SQL for SQL Server** with appropriate configuration

### Enterprise/Corporate

**Recommended:** Match your production environment

If production is:
- On-premises SQL Server → Test on same version
- Azure SQL Managed Instance → Test on Managed Instance
- Azure SQL Database → Test on Azure SQL Database (with limitations)

## Version-Specific Considerations

### SQL Server 2016 and Earlier

- Full support
- Standard tSQLt installation

### SQL Server 2017+

- Requires CLR strict security configuration
- May need to sign tSQLt assembly

```sql
-- SQL Server 2017+ CLR setup
sp_configure 'clr enabled', 1;
sp_configure 'clr strict security', 0;  -- Or sign the assembly
RECONFIGURE;
```

### SQL Server 2019/2022

- Full support
- Latest features available
- Best performance

## Summary

| If You're Using... | Do This |
|-------------------|---------|
| On-premises SQL Server | Use tSQLt directly, enable CLR |
| Azure SQL Managed Instance | Use tSQLt directly, CLR is available |
| Azure SQL Database | Use Azure-compatible tSQLt, expect limitations |
| Docker/Containers | Great choice for testing, full support |
| Synapse/Data Warehouse | tSQLt is not supported |

**Best Practice:** Run your tests in an environment that matches production as closely as possible, while using Docker containers for fast, isolated CI/CD testing.
