# Create Unit Test Command

Create tSQLt unit tests combining framework patterns with project-specific knowledge.

## Skills Loaded

This command combines:
- **tSQLt Core** - Generic testing framework patterns
- **AbylonRapid** - Project-specific procedures and conventions
- **Combined Patterns** - Integration examples

## Available Test Types

| Type | Description | Example |
|------|-------------|---------|
| Code Table Save | Test valid data saves successfully | `test_Country_ValidData_ShouldSucceed` |
| Code Table Validation | Test invalid data is rejected | `test_Currency_DuplicateCode_ShouldFail` |
| Param Values | Test dropdown options load correctly | `test_DCF_Param_Country_ReturnsActiveCountries` |
| Param Cascading | Test child dropdowns filter by parent | `test_DCF_Param_Company_FiltersByCountry` |
| Workflow Get | Test available workflow actions | `test_DCF_Workflow_Active_ShowsSubmit` |
| Workflow Update | Test state transitions | `test_DCF_Workflow_Submit_TransitionsState` |
| Access Control | Test permission restrictions | `test_DCF_Workflow_Viewer_CannotSubmit` |

## Usage

Tell me:
1. **What to test** - Table name, procedure, or feature
2. **Test scenario** - Happy path, validation, edge case
3. **Expected outcome** - Should succeed, should fail, should return X

## Examples

**Create a happy path test:**
```
Create a test for CT_Country that verifies valid country data saves successfully
```

**Create a validation test:**
```
Create a test for CT_Currency that verifies duplicate currency codes are rejected
```

**Create a workflow test:**
```
Create a test for DCF workflow that verifies Submit action transitions from
Active_SG2 to Submitted_for_Approve_to_SG3
```

**Create an access control test:**
```
Create a test that verifies users with Viewer role cannot see Submit action
```

## Output

I will generate:
1. Complete test procedure with AAA pattern
2. Appropriate FakeTable calls for isolation
3. Test data setup
4. Assertions matching expected outcome
5. Deployment instructions (where to add the test)

## Related Skills

For detailed patterns, reference:
- @.claude/skills/tsqlt-core.md - tSQLt framework details
- @.claude/skills/abylon-rapid.md - AbylonRapid conventions
- @.claude/skills/combined-patterns.md - Complete examples
- @.claude/skills/prompting-guide.md - How to prompt effectively
