# tSQLt Unit Test Creation Skill

Create tSQLt unit tests for the LANA Planner SQL Server database following established patterns and conventions.

## Quick Reference

| Test Type | Location | Procedure Called |
|-----------|----------|------------------|
| Code Table Save/Load | `tst_lana/Procedures/CodeTables/<TableName>/` | `arp.USP_SaveCodeTableItems` |
| Code Table Validation | `tst_lana/Procedures/CodeTables/<TableName>/` | `arp.USP_SaveCodeTableItems` |
| Param Values | `tst_lana/Procedures/Template/<TemplateName>/Param/` | `<schema>.usp_Template_<Name>_Param_Values` |
| Param Cascading | `tst_lana/Procedures/Template/<TemplateName>/Param/` | `<schema>.usp_Template_<Name>_Param_Values_Cascading` |
| Workflow Get | `tst_lana/Procedures/Template/<TemplateName>/Workflow/` | `<schema>.usp_Template_<Name>_Workflow_Get` |
| Workflow Update | `tst_lana/Procedures/Template/<TemplateName>/Workflow/` | `<schema>.usp_Template_<Name>_Workflow_Update` |

## Documentation References

- Official tSQLt docs: https://tsqlt.org/
- Test creation: https://tsqlt.org/user-guide/test-creation-and-execution/
- Assertions: https://tsqlt.org/user-guide/assertions/
- Expectations: https://tsqlt.org/user-guide/expectations/

## File Naming Convention

```
test_<EntityName>_<Scenario>_<ExpectedOutcome>.sql
```

**Examples:**
- `test_Country_ValidData_ShouldSucceed.sql`
- `test_Currency_DuplicateCurrencyCode_ShouldFail.sql`
- `test_LANA_DCF_Workflow_Get_Active_SG2_ShouldReturnCorrectActions.sql`

## Deployment Requirements

1. Add test to deployment script:
   - `Modules\LANA\LANA.Config\DataModel\PostDeploymentScripts\ZZZ_deploy_tests.sql`

```sql
:r .\Procedures\CodeTables\<TableName>\test_<TestName>.sql
GO
```

2. Add test execution to runner:
   - `Modules\LANA\LANA.DB\tst_lana\lana_tst_TestRunnerScript.sql`

```sql
EXEC tSQLt.Run 'tst_lana.test_<TestName>';
```

3. Set Build Action to **None** in Visual Studio (tests deploy only to dev environment).

---

## Base Test Template

```sql
/********************************************************************************
UNIT TEST - tst_lana.test_<TestName>

-- <Purpose description>

********************************************************************************/
CREATE
OR ALTER
PROCEDURE [tst_lana].[test_<TestName>]

AS

SET XACT_ABORT ON;
SET NOCOUNT ON;

BEGIN

    --================================================================================================
    -- ARRANGE - PREPARE DATA ========================================================================
    --================================================================================================

    -----------------
    -- FAKE TABLES --
    -----------------

    EXEC tSQLt.FakeTable N'<schema>.<TableName>';

    -----------------
    -- TEMP TABLES --
    -----------------

	DROP TABLE IF EXISTS #Message

	CREATE TABLE #Message	-- Called procedures can access #tempTable but not @TableVariables
	(
		Severity		int
		, MessageType	nvarchar(50)
		, Message		nvarchar(max)
		, Occured		datetime DEFAULT(GETDATE())
		, Sheet			nvarchar(255)
		, ColLetter		nvarchar(3)
		, RowNum		int
		, Location		nvarchar(10)
		, Source		nvarchar(255) DEFAULT(OBJECT_NAME(@@PROCID))
		, Line			int
	)

    -----------------
    -- PARAMS ------
    -----------------

    DECLARE @UserPrincipal NVARCHAR(255) = 'tSQLt\TestUser'
    DECLARE @Language NVARCHAR(10) = 'en'

    --================================================================================================
    -- ACT - PERFORM ACTIONS =========================================================================
    --================================================================================================


    --================================================================================================
    -- ASSERTION =====================================================================================
    --================================================================================================


END
```

---

## Code Table Testing

### Getting CodeTable ID

Always retrieve the CodeTableID from configuration:

```sql
DECLARE @CodeTableID INT = (
    SELECT Id
    FROM [cfg].[SYS_DW_Table_Mapping]
    WHERE DEY_Key = 'LANA_CT_<TableName>'  -- e.g., 'LANA_CT_ModelVersion'
)

IF @CodeTableID IS NULL
    THROW 50000, 'ERROR: CodeTableID for <TableName> not found in cfg.SYS_DW_Table_Mapping', 1
```

**DEY_Key lookup locations:**
- SQL: `Modules\LANA\LANA.Config\DataModel\PostDeploymentScripts\SYS_DW_Table_Mapping.sql`
- JSON: `Modules\LANA\LANA.Config\DataModel\PostDeploymentScripts\config_json\SYS_DW_Table_Mapping.json`

### JSON Data Format

Code tables receive data in JSON format matching UI input. **Important:** Date values use Excel serial numbers, not actual dates.

**Excel date conversion:**
- 2025-Jan-1 = 45658
- 2025-Dec-31 = 46022

**Example JSON structure:**
```json
[
    ["", "", "REF_CODE", "Display Name", 2024, 2040, 45658, 46022, 1],
    ["", "", "REF_CODE2", "Display Name 2", 2024, 2040, 45810, "", 0]
]
```

First two empty strings are for DWH_ID and row state markers.

### Code Table Save Test Pattern

```sql
-----------------
-- ARRANGE ------
-----------------

EXEC tSQLt.FakeTable N'lana_dwh.CT_<TableName>';

-- Insert existing data if testing updates
INSERT INTO lana_dwh.CT_<TableName> (columns...)
VALUES (...)

DECLARE @CodeTableID INT = (
    SELECT Id FROM [cfg].[SYS_DW_Table_Mapping]
    WHERE DEY_Key = 'LANA_CT_<TableName>'
)

DECLARE @JsonData NVARCHAR(MAX) = N'[
    ["", "", "TEST_REF", "Test Name", 2024, 2040, 45658, 46022, 1]
]'

DECLARE @UserPrincipal NVARCHAR(255) = 'tSQLt\TestUser'
DECLARE @Language NVARCHAR(10) = 'en'

-----------------
-- ACT ----------
-----------------

DROP TABLE IF EXISTS #ActualResult
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

-----------------
-- ASSERT -------
-----------------

-- For happy path: expect no errors
DROP TABLE IF EXISTS #ExpectedResult
CREATE TABLE #ExpectedResult (
    RowNumber INT,
    ErrorMessage NVARCHAR(MAX)
)
-- Leave empty for success case

EXEC tSQLt.AssertEqualsTable
    @Expected = '#ExpectedResult',
    @Actual = '#ActualResult',
    @Message = 'Should have no validation errors for valid data.'
```

### Code Table Validation Test Pattern

For testing custom validation rules that should reject invalid data:

```sql
-----------------
-- ARRANGE ------
-----------------

EXEC tSQLt.FakeTable N'lana_dwh.CT_<TableName>';

-- Prepare invalid data (e.g., duplicate keys, invalid ranges)
DECLARE @JsonData NVARCHAR(MAX) = N'[
    ["", "", "DUPLICATE", "First Row", 2024, 2040, 45658, 46022, 1],
    ["", "", "DUPLICATE", "Second Row", 2024, 2040, 45658, 46022, 1]
]'

-----------------
-- ACT ----------
-----------------

DROP TABLE IF EXISTS #ActualResult
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

-----------------
-- ASSERT -------
-----------------

DROP TABLE IF EXISTS #ExpectedResult
CREATE TABLE #ExpectedResult (
    RowNumber INT,
    ErrorMessage NVARCHAR(MAX)
)
INSERT INTO #ExpectedResult (RowNumber, ErrorMessage)
VALUES
    (0, 'Duplicate key error'),
    (1, 'Duplicate key error')

EXEC tSQLt.AssertEqualsTable
    @Expected = '#ExpectedResult',
    @Actual = '#ActualResult',
    @Message = 'Should return duplicate key errors for both rows.'
```

### Code Table Constraint Test Pattern

For testing database-level constraints:

```sql
-- Test foreign key constraint
EXEC tSQLt.FakeTable N'lana_dwh.CT_Country';
EXEC tSQLt.FakeTable N'lana_dwh.CT_Currency';

-- Don't insert required reference data
-- Try to save data with invalid reference

-- Assert error message mentions constraint violation
```

### Custom Validation Procedure Pattern

Custom validation is implemented via `[<schema>].[USP_Manual_<TableName>_CustomValidate]`:

```sql
-- Validation errors are inserted into #ErrorMessage temp table
CREATE TABLE #ErrorMessage
(
    RowNumber INT,
    ErrorMessage NVARCHAR(MAX)
)

-- Example validation procedure structure:
CREATE PROCEDURE [grp].[USP_Manual_PC_CustomValidate]
AS
BEGIN
    INSERT INTO #ErrorMessage (RowNumber, ErrorMessage)
    SELECT _RowNum, 'ReportingCurrency AND FunctionalCurrency is mandatory for RapidRelevant PCs'
    FROM #Source S
    WHERE
        CAST(RapidRelevant AS BIT) = 1
        AND (
            ISNULL(FunctionalCurrency, '') = ''
            OR
            ISNULL(ReportingCurrency, '') = ''
        )
END
```

---

## Rapid Excel Template Testing

### Param Values Test Pattern

Tests default parameter values loaded when template opens:

```sql
-----------------
-- ARRANGE ------
-----------------

-- Fake all referenced code tables
EXEC tSQLt.FakeTable N'lana_dwh.CT_Country';
EXEC tSQLt.FakeTable N'lana_dwh.CT_Company';
EXEC tSQLt.FakeTable N'lana_dwh.CT_Project';
EXEC tSQLt.FakeTable N'lana_dwh.CT_Scenario';

-- Insert test data
INSERT INTO lana_dwh.CT_Country (COUNTRY_CODE, COUNTRY_NAME, ...)
VALUES ('HU', 'Hungary', ...), ('SK', 'Slovakia', ...)

-- Create result capture table
DROP TABLE IF EXISTS #Result
CREATE TABLE #Result (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    PARAM_VALUE NVARCHAR(50),
    PARAM_LABEL NVARCHAR(255)
)

-----------------
-- ACT ----------
-----------------

INSERT INTO #Result(PARAM_VALUE, PARAM_LABEL)
EXEC lana_dwh.usp_Template_<TemplateName>_Param_Values
    @UserPrincipal = @UserPrincipal,
    @Language = @Language

-----------------
-- ASSERT -------
-----------------

-- Verify specific values exist
DECLARE @AllExists BIT = CASE
    WHEN EXISTS (SELECT 1 FROM #Result WHERE PARAM_VALUE = '_ALL')
    THEN 1 ELSE 0 END

EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @AllExists,
    @Message = '_ALL option should be available'

-- Verify ordering
DECLARE @FirstValue NVARCHAR(50) = (SELECT TOP 1 PARAM_VALUE FROM #Result ORDER BY ID)
EXEC tSQLt.AssertEquals @Expected = 'HU', @Actual = @FirstValue,
    @Message = 'Hungary should be first in the list'
```

### Param Values Cascading Test Pattern

Tests parameter filtering when parent parameter changes:

```sql
-----------------
-- ARRANGE ------
-----------------

-- Fake tables and insert hierarchical data
EXEC tSQLt.FakeTable N'lana_dwh.CT_Country';
EXEC tSQLt.FakeTable N'lana_dwh.CT_Company';

INSERT INTO lana_dwh.CT_Country (COUNTRY_CODE, ...) VALUES ('HU', ...)
INSERT INTO lana_dwh.CT_Company (COMPANY_CODE, COUNTRY_CODE, ...)
VALUES
    ('MOL_HU', 'HU', ...),
    ('SLOVNAFT_SK', 'SK', ...)

DROP TABLE IF EXISTS #ActualResult
CREATE TABLE #ActualResult (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    PARAM_VALUE NVARCHAR(50),
    PARAM_LABEL NVARCHAR(255)
)

-----------------
-- ACT ----------
-----------------

INSERT INTO #ActualResult
EXEC lana_dwh.usp_Template_<TemplateName>_Param_Values_Cascading
    @ParameterKey = 'Company',      -- Which param to refresh
    @UserPrincipal = @UserPrincipal,
    @Language = @Language,
    @Country = 'HU'                 -- Filter by Hungary

-----------------
-- ASSERT -------
-----------------

-- Should only return Hungarian companies
DECLARE @HasSlovakCompany BIT = CASE
    WHEN EXISTS (SELECT 1 FROM #ActualResult WHERE PARAM_VALUE = 'SLOVNAFT_SK')
    THEN 1 ELSE 0 END

EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @HasSlovakCompany,
    @Message = 'Slovak company should NOT appear when filtered by Hungary'
```

**Parameter Types (from `arp_cfg_TemplateParameter.json`):**
- **DropDown**: Returns Value-Label pairs
- **Textbox**: Input only, no SP output
- **TreeView**: Returns 4 columns: ParentNode, Order, Value, Label

### Workflow Get Test Pattern

Tests workflow state and available actions:

```sql
-----------------
-- ARRANGE ------
-----------------

-- Fake workflow-related tables
EXEC tSQLt.FakeTable N'lana_dwh.CT_Scenario';
EXEC tSQLt.FakeTable N'lana_dwh.CT_Status';
EXEC tSQLt.FakeTable N'arp.PlanState';
EXEC tSQLt.FakeTable N'arp_cfg.StateChange';
EXEC tSQLt.FakeTable N'arp.Role';

-- Insert current state and allowed transitions
INSERT INTO lana_dwh.CT_Scenario (SCENARIO_CODE, STATUS_CODE, ...)
VALUES ('SCEN_001', 'Active_SG2', ...)

INSERT INTO arp_cfg.StateChange (CurrentStateId, Action, NextStateId, RoleId, ACL_Check)
VALUES (1, 'Submit', 2, 1, 1)

-- Create result capture table (special for workflow)
DROP TABLE IF EXISTS #wf_result
CREATE TABLE #wf_result (
    Id INT IDENTITY(1,1),
    WfResult NVARCHAR(MAX)
)

-----------------
-- ACT ----------
-----------------

-- Use @Test = 1 to capture results in temp table
EXEC lana_dwh.usp_Template_<TemplateName>_Workflow_Get
    @UserPrincipal = @UserPrincipal,
    @Language = @Language,
    @Country = @Country,
    @Scenario = @Scenario,
    @Test = 1                       -- IMPORTANT: Enable test mode

-----------------
-- ASSERT -------
-----------------

-- Row 1 = Current Status, Row 2+ = Available Actions
DECLARE @CurrentStatus NVARCHAR(MAX) = (SELECT WfResult FROM #wf_result WHERE Id = 1)

EXEC tSQLt.AssertLike
    @ExpectedPattern = '%Active%',
    @Actual = @CurrentStatus,
    @Message = 'Current status should contain Active'

-- Verify action exists
DECLARE @HasSubmitAction BIT = CASE
    WHEN EXISTS (SELECT 1 FROM #wf_result WHERE Id > 1 AND WfResult LIKE '%Submit%')
    THEN 1 ELSE 0 END

EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @HasSubmitAction,
    @Message = 'Submit action should be available in Active_SG2 state'
```

### Workflow Update Test Pattern

Tests state transitions:

```sql
-----------------
-- ARRANGE ------
-----------------

-- Setup initial state
EXEC tSQLt.FakeTable N'lana_dwh.CT_Scenario';
EXEC tSQLt.FakeTable N'lana_dwh.Premise_Locks';

INSERT INTO lana_dwh.CT_Scenario (SCENARIO_CODE, STATUS_CODE, ...)
VALUES ('SCEN_001', 'Active_SG2', ...)

DECLARE @Action NVARCHAR(50) = 'Submit'
DECLARE @Comment NVARCHAR(MAX) = 'Test submission'

-----------------
-- ACT ----------
-----------------

EXEC lana_dwh.usp_Template_<TemplateName>_Workflow_Update
    @Action = @Action,
    @Comment = @Comment,
    @UserPrincipal = @UserPrincipal,
    @Language = @Language,
    @Scenario = 'SCEN_001'

-----------------
-- ASSERT -------
-----------------

-- Verify state transition occurred
DECLARE @NewStatus NVARCHAR(50) = (
    SELECT STATUS_CODE
    FROM lana_dwh.CT_Scenario
    WHERE SCENARIO_CODE = 'SCEN_001'
)

EXEC tSQLt.AssertEquals
    @Expected = 'Submitted_for_Approve_to_SG3',
    @Actual = @NewStatus,
    @Message = 'Status should transition to Submitted state'
```

### Access Control Test Pattern

Tests permission-based restrictions:

```sql
-----------------
-- ARRANGE ------
-----------------

EXEC tSQLt.FakeTable N'arp.Role';
EXEC tSQLt.FakeTable N'arp.UserRole';
EXEC tSQLt.FakeTable N'arp_cfg.StateChange';

-- User without permission
DECLARE @UnauthorizedUser NVARCHAR(255) = 'unauthorized@mol.hu'

-- Setup role that doesn't have submit permission
INSERT INTO arp.Role (RoleId, RoleName) VALUES (1, 'Viewer')
INSERT INTO arp.UserRole (UserPrincipal, RoleId) VALUES (@UnauthorizedUser, 1)

-- StateChange requires RoleId = 2 for Submit
INSERT INTO arp_cfg.StateChange (CurrentStateId, Action, NextStateId, RoleId, ACL_Check)
VALUES (1, 'Submit', 2, 2, 1)

-----------------
-- ACT ----------
-----------------

DROP TABLE IF EXISTS #wf_result
CREATE TABLE #wf_result (Id INT IDENTITY(1,1), WfResult NVARCHAR(MAX))

EXEC lana_dwh.usp_Template_<TemplateName>_Workflow_Get
    @UserPrincipal = @UnauthorizedUser,
    @Test = 1

-----------------
-- ASSERT -------
-----------------

-- Verify Submit action is NOT available
DECLARE @HasSubmitAction BIT = CASE
    WHEN EXISTS (SELECT 1 FROM #wf_result WHERE WfResult LIKE '%Submit%')
    THEN 1 ELSE 0 END

EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @HasSubmitAction,
    @Message = 'Unauthorized user should NOT see Submit action'
```

---

## Important Notes

### UDF Handling

When you see `SELECT ... FROM schema.udf_SomeName(@param)`:
- UDFs are inline table-valued functions
- **Don't fake the UDF** - fake the underlying tables it queries
- UDF parameters may have defaults but always provide values when calling

### Mock Data Sources

- **Code tables test data:** `Modules\LANA\LANA.Test.Data\CodeTables\CodeTables_Test_data_v20250830.sql`
- **Local database:** `localhost - AbylonRapidCatalog_LANA` (MCP server configured)
- Query existing data to create realistic test scenarios

### Common Assertions

```sql
-- Compare tables
EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual'

-- Compare values
EXEC tSQLt.AssertEquals @Expected = 'value', @Actual = @variable

-- Pattern matching
EXEC tSQLt.AssertLike @ExpectedPattern = '%pattern%', @Actual = @variable

-- Expect exception
EXEC tSQLt.ExpectException @ExpectedMessage = 'Error message'
```

### CT_Scenario Table

Always populate CT_Scenario for template tests - it holds workflow state. Also include CT_Status, CT_ProjectStatus with mock data.

### Model Version Requirements

For DCF-related tests, CT_ModelVersion needs:
- MODEL_VERSION_YEAR_FROM (e.g., 2024)
- MODEL_VERSION_YEAR_TO (e.g., 2040)
