# SQL Server Unit Testing with tSQLt - Educational Documentation

Welcome to the educational documentation for SQL Server unit testing using tSQLt. This collection of documents will guide you through the fundamentals of database unit testing, from basic concepts to practical implementation.

## Documentation Index

### Foundational Concepts

1. **[Why Unit Testing?](01-why-unit-testing.md)**
   - The purpose and benefits of unit testing
   - Testing data vs. functionality
   - The testing mindset

2. **[Test Types Comparison](02-test-types-comparison.md)**
   - Unit tests vs. integration tests vs. E2E tests
   - The testing pyramid
   - When to use each test type

3. **[Database vs. Application Testing](03-database-vs-application-testing.md)**
   - Unique challenges of database testing
   - State persistence and isolation
   - How tSQLt addresses these challenges

### The AAA Pattern and tSQLt

4. **[The AAA Pattern](04-aaa-pattern.md)**
   - Arrange, Act, Assert explained
   - Complete examples in tSQLt
   - Common anti-patterns to avoid

5. **[tSQLt Tools and Framework](05-tsqlt-tools-and-framework.md)**
   - Tools for each AAA phase
   - FakeTable, SpyProcedure, assertions
   - Why frameworks matter

### Implementation

6. **[Supported SQL Server Types](06-supported-sql-server-types.md)**
   - On-premises SQL Server editions
   - Azure SQL Database and Managed Instance
   - Docker and Linux containers
   - CLR requirements

7. **[Running Tests and Deployment](07-running-tests-and-deployment.md)**
   - How to execute tSQLt tests
   - CI/CD integration examples
   - Deployment strategies and best practices

## Quick Start

If you're new to tSQLt, we recommend reading the documents in order:

```
Start Here
    │
    ▼
[01] Why Unit Testing? ─────────────────┐
    │                                    │
    ▼                                    │  Foundational
[02] Test Types ────────────────────────┤  Understanding
    │                                    │
    ▼                                    │
[03] Database vs. App Testing ──────────┘
    │
    ▼
[04] AAA Pattern ───────────────────────┐
    │                                    │  tSQLt
    ▼                                    │  Specifics
[05] tSQLt Tools ───────────────────────┘
    │
    ▼
[06] Supported Environments ────────────┐
    │                                    │  Practical
    ▼                                    │  Implementation
[07] Running & Deployment ──────────────┘
```

## Key Takeaways

| Topic | Key Point |
|-------|-----------|
| Why test? | Catch bugs early, enable safe refactoring |
| Test types | Unit tests are fast and cheap; use the testing pyramid |
| DB testing | Requires isolation strategies unlike app testing |
| AAA pattern | Structure tests: Arrange → Act → Assert |
| tSQLt tools | FakeTable, SpyProcedure, AssertEquals, etc. |
| Environments | Managed Instance has full support; Azure SQL DB is limited |
| Deployment | Integrate with CI/CD, fail builds on test failures |

## Additional Resources

- [tSQLt Official Documentation](https://tsqlt.org/user-guide/)
- [tSQLt GitHub Repository](https://github.com/tSQLt-org/tSQLt)
- [SQL Server Documentation](https://docs.microsoft.com/en-us/sql/sql-server/)

---

*This documentation is part of an educational project demonstrating SQL Server unit testing with tSQLt.*
