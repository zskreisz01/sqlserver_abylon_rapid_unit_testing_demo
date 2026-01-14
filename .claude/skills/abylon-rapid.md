# AbylonRapid Framework Skill

Domain knowledge for the AbylonRapid Excel-to-SQL integration framework. Use this skill when testing code tables, workflow procedures, and template parameters.

## Framework Overview

AbylonRapid connects Excel templates to SQL Server:
- **Code Tables** - Master data managed via Excel (CT_Country, CT_Currency, etc.)
- **Templates** - Excel workbooks with parameters, data entry, and workflows
- **Workflows** - State machine for approval processes

---

## Architecture

```
Excel Template
    │
    ├── Parameters → usp_Template_<Name>_Param_Values
    │              → usp_Template_<Name>_Param_Values_Cascading
    │
    ├── Data Grid  → arp.USP_SaveCodeTableItems (code tables)
    │              → custom procedures (data entry)
    │
    └── Workflow   → usp_Template_<Name>_Workflow_Get
                   → usp_Template_<Name>_Workflow_Update
```

---

## Code Table System

### Table Naming Convention

```
<schema_name>.CT_<TableName>
```

Examples: `CT_Country`, `CT_Currency`, `CT_Company`, `CT_Scenario`

### Code Table ID Lookup

Every code table has an ID in configuration:

```sql
DECLARE @CodeTableID INT = (
    SELECT Id
    FROM [cfg].[SYS_DW_Table_Mapping]
    WHERE DEY_Key = '<MODULE_CODE>_CT_<TableName>'  -- e.g., '<MODULE_CODE>_CT_Country'
)

IF @CodeTableID IS NULL
    THROW 50000, 'CodeTableID not found', 1
```

### Save Procedure

All code table saves go through a single procedure:

```sql
EXEC [arp].[USP_SaveCodeTableItems]
    @JsonData = @JsonData,         -- JSON array of rows
    @CodeTableID = @CodeTableID,   -- From cfg.SYS_DW_Table_Mapping
    @UserPrincipal = @UserPrincipal,
    @Language = @Language
```

**Returns:** Table of `(RowNumber INT, ErrorMessage NVARCHAR(MAX))`
- Empty result = success
- Rows with messages = validation errors

### JSON Data Format

Data comes as JSON array. First two elements are system columns:

```json
[
    ["", "", "VALUE1", "Label 1", 2024, 2040, 45658, 46022, 1],
    ["", "", "VALUE2", "Label 2", 2024, 2040, 45810, "", 0]
]
```

| Position | Purpose |
|----------|---------|
| [0] | DWH_ID (empty for new rows) |
| [1] | Row state marker |
| [2+] | Actual column values |

**Date Values:** Use Excel serial numbers, not dates!
- 2025-01-01 = 45658
- 2025-12-31 = 46022

### Custom Validation

Tables can have custom validation via:
```sql
[<schema>].[USP_Manual_<TableName>_CustomValidate]
```

Validation writes errors to `#ErrorMessage` temp table:
```sql
CREATE TABLE #ErrorMessage (
    RowNumber INT,
    ErrorMessage NVARCHAR(MAX)
)
```

---

## Template Parameters

### Parameter Value Procedure

Returns dropdown options when template opens:

```sql
EXEC <schema>.usp_Template_<Name>_Param_Values
    @UserPrincipal = @UserPrincipal,
    @Language = @Language
```

**Returns:** `(PARAM_VALUE, PARAM_LABEL)`

### Cascading Parameters

Filters child dropdown based on parent selection:

```sql
EXEC <schema>.usp_Template_<Name>_Param_Values_Cascading
    @ParameterKey = 'Company',     -- Which param to refresh
    @UserPrincipal = @UserPrincipal,
    @Language = @Language,
    @Country = 'HU'                -- Parent param value
```

### Parameter Types

| Type | Return Columns | Description |
|------|----------------|-------------|
| DropDown | Value, Label | Single selection |
| TreeView | ParentNode, Order, Value, Label | Hierarchical |
| Textbox | n/a (input only) | Free text |

---

## Workflow System

### State Configuration

Workflows are configured in:
- `arp_cfg.StateChange` - Allowed transitions
- `arp.PlanState` - State definitions
- `arp.Role` / `arp.UserRole` - Permissions

### Workflow Get

Returns current status and available actions:

```sql
EXEC <schema>.usp_Template_<Name>_Workflow_Get
    @UserPrincipal = @UserPrincipal,
    @Language = @Language,
    @Scenario = @Scenario,
    @Test = 1                      -- Enables test mode
```

**Test Mode:** When `@Test = 1`, results go to `#wf_result`:
```sql
CREATE TABLE #wf_result (
    Id INT IDENTITY(1,1),
    WfResult NVARCHAR(MAX)
)
-- Row 1 = Current status
-- Row 2+ = Available actions
```

### Workflow Update

Executes state transition:

```sql
EXEC <schema>.usp_Template_<Name>_Workflow_Update
    @Action = 'Submit',
    @Comment = 'Ready for review',
    @UserPrincipal = @UserPrincipal,
    @Language = @Language,
    @Scenario = @Scenario
```

### Common Workflow States

| State | Description |
|-------|-------------|
| Draft | Initial state, editable |
| Active_SG1/SG2/SG3 | Active at stage group level |
| Submitted_for_Approve | Awaiting approval |
| Approved | Approved, locked |
| Rejected | Sent back for revision |

---

## Common Tables

### CT_Scenario

Central table for workflow state. **Always populate in tests:**

```sql
INSERT INTO <schema_name>.CT_Scenario (
    SCENARIO_CODE,
    SCENARIO_NAME,
    STATUS_CODE,
    MODEL_VERSION_CODE,
    ...
)
VALUES (
    'SCEN_001',
    'Test Scenario',
    'Active_SG2',
    'MV_2024',
    ...
)
```

### CT_Status

Workflow status definitions:

```sql
INSERT INTO <schema_name>.CT_Status (
    STATUS_CODE,
    STATUS_NAME,
    SORT_ORDER,
    IS_ACTIVE
)
VALUES
    ('Draft', 'Draft', 1, 1),
    ('Active_SG2', 'Active (Stage 2)', 2, 1)
```

### CT_ModelVersion

Required for DCF-related tests:

```sql
INSERT INTO <schema_name>.CT_ModelVersion (
    MODEL_VERSION_CODE,
    MODEL_VERSION_NAME,
    MODEL_VERSION_YEAR_FROM,  -- e.g., 2024
    MODEL_VERSION_YEAR_TO     -- e.g., 2040
)
```

---

## UDF Handling

User-Defined Functions appear as:
```sql
SELECT * FROM schema.udf_FunctionName(@param)
```

**Important:** Don't fake UDFs - fake the underlying tables they query.

```sql
-- Wrong: Can't fake UDF
EXEC tSQLt.FakeTable 'schema.udf_GetActiveCountries';  -- Error!

-- Right: Fake the table UDF queries
EXEC tSQLt.FakeTable '<schema_name>.CT_Country';
```

---

## #Message Temp Table

Procedures log messages to shared temp table:

```sql
CREATE TABLE #Message (
    Severity        INT,
    MessageType     NVARCHAR(50),
    Message         NVARCHAR(MAX),
    Occured         DATETIME DEFAULT(GETDATE()),
    Sheet           NVARCHAR(255),
    ColLetter       NVARCHAR(3),
    RowNum          INT,
    Location        NVARCHAR(10),
    Source          NVARCHAR(255) DEFAULT(OBJECT_NAME(@@PROCID)),
    Line            INT
)
```

---

## File Locations

| Resource | Path |
|----------|------|
| Code table mapping | `Modules/<MODULE_CODE>/<MODULE_CODE>.Config/DataModel/PostDeploymentScripts/SYS_DW_Table_Mapping.sql` |
| Template params config | `arp_cfg_TemplateParameter.json` |
| Test deployment | `Modules/<MODULE_CODE>/<MODULE_CODE>.Config/DataModel/PostDeploymentScripts/ZZZ_deploy_tests.sql` |
| Test runner | `Modules/<MODULE_CODE>/<MODULE_CODE>.DB/tst_<MODULE_CODE>/<MODULE_CODE>_tst_TestRunnerScript.sql` |
| Test data samples | `Modules/<MODULE_CODE>/<MODULE_CODE>.Test.Data/CodeTables/` |

---

## Standard Test Parameters

```sql
DECLARE @UserPrincipal NVARCHAR(255) = 'tSQLt\TestUser'
DECLARE @Language NVARCHAR(10) = 'en'
```

---

## Schema Reference

| Schema | Purpose |
|--------|---------|
| `<schema_name>` | Code tables (CT_*) and data |
| `arp` | Core framework procedures |
| `arp_cfg` | Framework configuration |
| `cfg` | System configuration |
| `grp` | Group/company specific |
| `tst_<MODULE_CODE>` | Test procedures |
