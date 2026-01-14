# Combined Testing Patterns

This skill shows how to combine **tSQLt framework knowledge** with **AbylonRapid specifics** to create effective unit tests.

## Why Both Skills Are Needed

| Skill | Provides |
|-------|----------|
| `tsqlt-core.md` | HOW to write tests (FakeTable, assertions, patterns) |
| `abylon-rapid.md` | WHAT to test (procedures, tables, JSON format, workflows) |

Together they enable Claude to generate **complete, working tests**.

---

## Complete Test Examples

### Example 1: Code Table Save - Happy Path

```sql
/********************************************************************************
UNIT TEST - tst_lana.test_Country_ValidData_ShouldSucceed

Tests that valid country data can be saved without errors.
********************************************************************************/
CREATE OR ALTER PROCEDURE [tst_lana].[test_Country_ValidData_ShouldSucceed]
AS
BEGIN
    SET XACT_ABORT ON;
    SET NOCOUNT ON;

    --========================================
    -- ARRANGE
    --========================================

    -- Fake the target table (tSQLt pattern)
    EXEC tSQLt.FakeTable N'lana_dwh.CT_Country';

    -- Get CodeTableID (AbylonRapid pattern)
    DECLARE @CodeTableID INT = (
        SELECT Id FROM [cfg].[SYS_DW_Table_Mapping]
        WHERE DEY_Key = 'LANA_CT_Country'
    )

    IF @CodeTableID IS NULL
        THROW 50000, 'CodeTableID for Country not found', 1

    -- Prepare JSON data (AbylonRapid format)
    DECLARE @JsonData NVARCHAR(MAX) = N'[
        ["", "", "HU", "Hungary", "HUF", 1],
        ["", "", "SK", "Slovakia", "EUR", 1]
    ]'

    -- Standard test parameters (AbylonRapid convention)
    DECLARE @UserPrincipal NVARCHAR(255) = 'tSQLt\TestUser'
    DECLARE @Language NVARCHAR(10) = 'en'

    --========================================
    -- ACT
    --========================================

    -- Capture results (tSQLt pattern for result sets)
    CREATE TABLE #ActualResult (
        RowNumber INT,
        ErrorMessage NVARCHAR(MAX)
    )

    INSERT INTO #ActualResult
    EXEC [arp].[USP_SaveCodeTableItems]
        @JsonData = @JsonData,
        @CodeTableID = @CodeTableID,
        @UserPrincipal = @UserPrincipal,
        @Language = @Language

    --========================================
    -- ASSERT
    --========================================

    -- Expected: no errors (empty table)
    CREATE TABLE #ExpectedResult (
        RowNumber INT,
        ErrorMessage NVARCHAR(MAX)
    )

    -- tSQLt assertion
    EXEC tSQLt.AssertEqualsTable
        @Expected = '#ExpectedResult',
        @Actual = '#ActualResult',
        @Message = 'Valid country data should save without errors'

    -- Verify data was inserted
    DECLARE @InsertedCount INT = (SELECT COUNT(*) FROM lana_dwh.CT_Country)
    EXEC tSQLt.AssertEquals 2, @InsertedCount, 'Should insert 2 countries'
END
```

### Example 2: Code Table Validation - Duplicate Key

```sql
/********************************************************************************
UNIT TEST - tst_lana.test_Currency_DuplicateCurrencyCode_ShouldFail

Tests that duplicate currency codes are rejected.
********************************************************************************/
CREATE OR ALTER PROCEDURE [tst_lana].[test_Currency_DuplicateCurrencyCode_ShouldFail]
AS
BEGIN
    SET XACT_ABORT ON;
    SET NOCOUNT ON;

    --========================================
    -- ARRANGE
    --========================================

    EXEC tSQLt.FakeTable N'lana_dwh.CT_Currency';

    DECLARE @CodeTableID INT = (
        SELECT Id FROM [cfg].[SYS_DW_Table_Mapping]
        WHERE DEY_Key = 'LANA_CT_Currency'
    )

    -- JSON with duplicate currency codes
    DECLARE @JsonData NVARCHAR(MAX) = N'[
        ["", "", "EUR", "Euro", "€", 1],
        ["", "", "EUR", "Euro Duplicate", "€", 1]
    ]'

    DECLARE @UserPrincipal NVARCHAR(255) = 'tSQLt\TestUser'
    DECLARE @Language NVARCHAR(10) = 'en'

    --========================================
    -- ACT
    --========================================

    CREATE TABLE #ActualResult (
        RowNumber INT,
        ErrorMessage NVARCHAR(MAX)
    )

    INSERT INTO #ActualResult
    EXEC [arp].[USP_SaveCodeTableItems]
        @JsonData = @JsonData,
        @CodeTableID = @CodeTableID,
        @UserPrincipal = @UserPrincipal,
        @Language = @Language

    --========================================
    -- ASSERT
    --========================================

    -- Should have validation error(s)
    DECLARE @ErrorCount INT = (SELECT COUNT(*) FROM #ActualResult)

    -- Using AssertNotEquals since error count should be > 0
    EXEC tSQLt.AssertNotEquals 0, @ErrorCount,
        'Duplicate currency code should produce validation error'

    -- Verify error mentions duplicate
    DECLARE @HasDuplicateError BIT = CASE
        WHEN EXISTS (
            SELECT 1 FROM #ActualResult
            WHERE ErrorMessage LIKE '%duplicate%'
               OR ErrorMessage LIKE '%already exists%'
        )
        THEN 1 ELSE 0 END

    EXEC tSQLt.AssertEquals 1, @HasDuplicateError,
        'Error message should indicate duplicate key'
END
```

### Example 3: Parameter Cascading

```sql
/********************************************************************************
UNIT TEST - tst_lana.test_DCF_Param_Cascading_Company_FiltersByCountry

Tests that company dropdown filters correctly when country changes.
********************************************************************************/
CREATE OR ALTER PROCEDURE [tst_lana].[test_DCF_Param_Cascading_Company_FiltersByCountry]
AS
BEGIN
    SET XACT_ABORT ON;
    SET NOCOUNT ON;

    --========================================
    -- ARRANGE
    --========================================

    -- Fake all related tables
    EXEC tSQLt.FakeTable N'lana_dwh.CT_Country';
    EXEC tSQLt.FakeTable N'lana_dwh.CT_Company';

    -- Insert test countries
    INSERT INTO lana_dwh.CT_Country (COUNTRY_CODE, COUNTRY_NAME, IS_ACTIVE)
    VALUES ('HU', 'Hungary', 1), ('SK', 'Slovakia', 1);

    -- Insert companies linked to countries
    INSERT INTO lana_dwh.CT_Company (COMPANY_CODE, COMPANY_NAME, COUNTRY_CODE, IS_ACTIVE)
    VALUES
        ('MOL_HU', 'MOL Hungary', 'HU', 1),
        ('MOL_PETROL', 'MOL Petrolkemia', 'HU', 1),
        ('SLOVNAFT', 'Slovnaft', 'SK', 1);

    DECLARE @UserPrincipal NVARCHAR(255) = 'tSQLt\TestUser'
    DECLARE @Language NVARCHAR(10) = 'en'

    --========================================
    -- ACT
    --========================================

    CREATE TABLE #ActualResult (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        PARAM_VALUE NVARCHAR(50),
        PARAM_LABEL NVARCHAR(255)
    )

    INSERT INTO #ActualResult (PARAM_VALUE, PARAM_LABEL)
    EXEC lana_dwh.usp_Template_LANA_DCF_Param_Values_Cascading
        @ParameterKey = 'Company',
        @UserPrincipal = @UserPrincipal,
        @Language = @Language,
        @Country = 'HU'  -- Filter by Hungary

    --========================================
    -- ASSERT
    --========================================

    -- Should return only Hungarian companies
    DECLARE @HungarianCount INT = (
        SELECT COUNT(*) FROM #ActualResult
        WHERE PARAM_VALUE IN ('MOL_HU', 'MOL_PETROL')
    )
    EXEC tSQLt.AssertEquals 2, @HungarianCount,
        'Should return both Hungarian companies'

    -- Should NOT return Slovak company
    DECLARE @HasSlovakCompany BIT = CASE
        WHEN EXISTS (SELECT 1 FROM #ActualResult WHERE PARAM_VALUE = 'SLOVNAFT')
        THEN 1 ELSE 0 END

    EXEC tSQLt.AssertEquals 0, @HasSlovakCompany,
        'Slovak company should NOT appear when filtered by Hungary'
END
```

### Example 4: Workflow State Transition

```sql
/********************************************************************************
UNIT TEST - tst_lana.test_DCF_Workflow_Submit_TransitionsToSubmitted

Tests that Submit action moves scenario to Submitted state.
********************************************************************************/
CREATE OR ALTER PROCEDURE [tst_lana].[test_DCF_Workflow_Submit_TransitionsToSubmitted]
AS
BEGIN
    SET XACT_ABORT ON;
    SET NOCOUNT ON;

    --========================================
    -- ARRANGE
    --========================================

    -- Fake workflow-related tables
    EXEC tSQLt.FakeTable N'lana_dwh.CT_Scenario';
    EXEC tSQLt.FakeTable N'lana_dwh.CT_Status';
    EXEC tSQLt.FakeTable N'arp.PlanState';
    EXEC tSQLt.FakeTable N'arp_cfg.StateChange';
    EXEC tSQLt.FakeTable N'arp.Role';
    EXEC tSQLt.FakeTable N'arp.UserRole';
    EXEC tSQLt.FakeTable N'lana_dwh.Premise_Locks';

    -- Setup states
    INSERT INTO lana_dwh.CT_Status (STATUS_CODE, STATUS_NAME, IS_ACTIVE)
    VALUES
        ('Active_SG2', 'Active Stage 2', 1),
        ('Submitted_for_Approve_to_SG3', 'Submitted', 1);

    INSERT INTO arp.PlanState (PlanStateId, StateName)
    VALUES (1, 'Active_SG2'), (2, 'Submitted_for_Approve_to_SG3');

    -- Setup allowed transition
    INSERT INTO arp_cfg.StateChange (CurrentStateId, Action, NextStateId, RoleId, ACL_Check)
    VALUES (1, 'Submit', 2, 1, 0);

    -- Setup scenario in Active state
    INSERT INTO lana_dwh.CT_Scenario (
        SCENARIO_CODE, SCENARIO_NAME, STATUS_CODE, CREATED_BY
    )
    VALUES ('SCEN_TEST', 'Test Scenario', 'Active_SG2', 'tSQLt\TestUser');

    DECLARE @UserPrincipal NVARCHAR(255) = 'tSQLt\TestUser'
    DECLARE @Language NVARCHAR(10) = 'en'

    --========================================
    -- ACT
    --========================================

    EXEC lana_dwh.usp_Template_LANA_DCF_Workflow_Update
        @Action = 'Submit',
        @Comment = 'Test submission',
        @UserPrincipal = @UserPrincipal,
        @Language = @Language,
        @Scenario = 'SCEN_TEST'

    --========================================
    -- ASSERT
    --========================================

    DECLARE @NewStatus NVARCHAR(50) = (
        SELECT STATUS_CODE
        FROM lana_dwh.CT_Scenario
        WHERE SCENARIO_CODE = 'SCEN_TEST'
    )

    EXEC tSQLt.AssertEquals
        @Expected = 'Submitted_for_Approve_to_SG3',
        @Actual = @NewStatus,
        @Message = 'Status should transition to Submitted'
END
```

### Example 5: Access Control Test

```sql
/********************************************************************************
UNIT TEST - tst_lana.test_DCF_Workflow_UnauthorizedUser_CannotSubmit

Tests that users without Submit permission don't see Submit action.
********************************************************************************/
CREATE OR ALTER PROCEDURE [tst_lana].[test_DCF_Workflow_UnauthorizedUser_CannotSubmit]
AS
BEGIN
    SET XACT_ABORT ON;
    SET NOCOUNT ON;

    --========================================
    -- ARRANGE
    --========================================

    EXEC tSQLt.FakeTable N'lana_dwh.CT_Scenario';
    EXEC tSQLt.FakeTable N'arp.PlanState';
    EXEC tSQLt.FakeTable N'arp_cfg.StateChange';
    EXEC tSQLt.FakeTable N'arp.Role';
    EXEC tSQLt.FakeTable N'arp.UserRole';

    -- Setup roles: Editor (1) can submit, Viewer (2) cannot
    INSERT INTO arp.Role (RoleId, RoleName)
    VALUES (1, 'Editor'), (2, 'Viewer');

    -- Submit action requires Editor role (RoleId = 1)
    INSERT INTO arp_cfg.StateChange (CurrentStateId, Action, NextStateId, RoleId, ACL_Check)
    VALUES (1, 'Submit', 2, 1, 1);  -- ACL_Check = 1 means check permissions

    -- Give test user only Viewer role
    DECLARE @UnauthorizedUser NVARCHAR(255) = 'viewer@company.com'
    INSERT INTO arp.UserRole (UserPrincipal, RoleId)
    VALUES (@UnauthorizedUser, 2);

    INSERT INTO lana_dwh.CT_Scenario (SCENARIO_CODE, STATUS_CODE)
    VALUES ('SCEN_TEST', 'Active_SG2');

    INSERT INTO arp.PlanState (PlanStateId, StateName)
    VALUES (1, 'Active_SG2');

    --========================================
    -- ACT
    --========================================

    CREATE TABLE #wf_result (
        Id INT IDENTITY(1,1),
        WfResult NVARCHAR(MAX)
    )

    EXEC lana_dwh.usp_Template_LANA_DCF_Workflow_Get
        @UserPrincipal = @UnauthorizedUser,
        @Language = 'en',
        @Scenario = 'SCEN_TEST',
        @Test = 1

    --========================================
    -- ASSERT
    --========================================

    DECLARE @HasSubmitAction BIT = CASE
        WHEN EXISTS (SELECT 1 FROM #wf_result WHERE WfResult LIKE '%Submit%')
        THEN 1 ELSE 0 END

    EXEC tSQLt.AssertEquals 0, @HasSubmitAction,
        'Viewer should NOT see Submit action'
END
```

---

## Test Creation Workflow

### Step 1: Identify Test Type

| If Testing... | Use Pattern From |
|---------------|------------------|
| Code table CRUD | Example 1, 2 |
| Custom validation | Example 2 |
| Parameter dropdowns | Example 3 |
| Workflow transitions | Example 4 |
| Access control | Example 5 |

### Step 2: Identify Tables to Fake

1. Target table being tested
2. Referenced tables (FKs)
3. Configuration tables
4. Security tables (if testing ACL)

### Step 3: Prepare Test Data

1. JSON format for code table input
2. Excel serial numbers for dates
3. Existing data for update scenarios
4. Role assignments for security tests

### Step 4: Write Assertions

| Goal | Assertion |
|------|-----------|
| No errors | `AssertEqualsTable` with empty expected |
| Specific error | `AssertLike` on error message |
| Row count | `AssertEquals` on COUNT(*) |
| State change | `AssertEquals` on status column |

---

## Deployment Checklist

1. **Add test file** to test folder:
   ```
   tst_lana/Procedures/CodeTables/<TableName>/test_<Name>.sql
   ```

2. **Add to deployment script**:
   ```sql
   -- In ZZZ_deploy_tests.sql
   :r .\Procedures\CodeTables\<TableName>\test_<Name>.sql
   GO
   ```

3. **Add to test runner**:
   ```sql
   -- In lana_tst_TestRunnerScript.sql
   EXEC tSQLt.Run 'tst_lana.test_<Name>';
   ```

4. **Set Build Action** to None (Visual Studio)
