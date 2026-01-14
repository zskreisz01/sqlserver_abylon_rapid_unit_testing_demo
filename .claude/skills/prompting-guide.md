# Claude Skills Prompting Guide

How to effectively invoke Claude skills for SQL Server unit testing.

---

## Method 1: Slash Commands

The simplest way to load a skill. Place command files in `.claude/commands/`.

### Syntax
```
/<command-name>
```

### Examples

```
User: /tsqlt-unit-tests

Claude: [Skill loaded] I now have access to tSQLt patterns and AbylonRapid
        framework knowledge. What would you like me to test?
```

```
User: /tsqlt-unit-tests Create a test for CT_Currency duplicate validation

Claude: I'll create a test that verifies duplicate currency codes are rejected...
        [Generates complete test using patterns from the skill]
```

---

## Method 2: File References with @

Reference skill files directly in your prompt using `@` notation.

### Syntax
```
@.claude/skills/<filename>.md
```

### Examples

**Single skill:**
```
User: Using @.claude/skills/tsqlt-core.md, explain how to test a stored procedure
      that returns a result set.

Claude: Based on the tSQLt patterns, here's how to test result sets...
```

**Multiple skills:**
```
User: Load @.claude/skills/tsqlt-core.md and @.claude/skills/abylon-rapid.md
      then create a test for the Country code table save functionality.

Claude: I'll combine tSQLt testing patterns with AbylonRapid's code table
        conventions to create this test...
```

**Combining skills with code:**
```
User: Using @.claude/skills/combined-patterns.md as reference, create a test
      for this procedure: @SampleDatabase/StoredProcedures/usp_GetCustomerOrders.sql

Claude: I'll analyze the procedure and create a test following the combined
        patterns...
```

---

## Method 3: Sub-Agents with Skills

Launch sub-agents with specific skills for parallel or complex workflows.

### Basic Sub-Agent

```
User: Run a sub-agent with @.claude/skills/abylon-rapid.md to analyze all
      CT_* tables in the database and list their CodeTableIDs.

Claude: [Launches sub-agent with AbylonRapid knowledge]
        The agent found the following code tables...
```

### Parallel Sub-Agents

```
User: Run these sub-agents in parallel:
      1. Agent with @.claude/skills/tsqlt-core.md to review existing tests for gaps
      2. Agent with @.claude/skills/abylon-rapid.md to map all workflow procedures

Claude: [Launches two parallel agents]
        Agent 1 results: Found 5 test gaps...
        Agent 2 results: Mapped 12 workflow procedures...
```

### Sub-Agent for Research

```
User: Use a sub-agent with @.claude/skills/abylon-rapid.md to find all custom
      validation procedures (USP_Manual_*_CustomValidate) and summarize their rules.

Claude: [Launches exploration agent with framework knowledge]
        Found 8 custom validation procedures...
```

---

## Method 4: Contextual Prompting

Describe what you need and let Claude select appropriate patterns.

### Implicit Skill Loading

```
User: I need to test the CT_Scenario workflow transitions. The scenario starts
      in Active_SG2 and should move to Submitted when user clicks Submit.

Claude: I'll create this test using tSQLt for isolation and AbylonRapid's
        workflow patterns...
        [Claude implicitly applies relevant patterns from both domains]
```

### Describe the Domain

```
User: We use AbylonRapid framework with Excel templates that call SQL procedures.
      Code tables are saved via arp.USP_SaveCodeTableItems with JSON input.
      Create a test for CT_Currency that validates the currency code is unique.

Claude: Based on the framework description, I'll create a validation test...
```

---

## Effective Prompting Patterns

### Pattern 1: Task + Skill + Context

```
[TASK]: Create a unit test
[SKILL]: Using @.claude/skills/combined-patterns.md
[CONTEXT]: for the CT_Country table that validates COUNTRY_CODE is unique
```

**Full prompt:**
```
User: Using @.claude/skills/combined-patterns.md, create a unit test for
      CT_Country that validates COUNTRY_CODE must be unique across all rows.
```

### Pattern 2: Analyze + Skill + Action

```
[ANALYZE]: Review the procedure at @path/to/procedure.sql
[SKILL]: Using @.claude/skills/tsqlt-core.md
[ACTION]: Generate comprehensive test cases
```

**Full prompt:**
```
User: Using @.claude/skills/tsqlt-core.md, review
      @SampleDatabase/StoredProcedures/usp_AddCustomer.sql and generate
      comprehensive test cases covering happy path and edge cases.
```

### Pattern 3: Debug + Skill + Error

```
[DEBUG]: My test is failing
[SKILL]: Based on @.claude/skills/tsqlt-core.md patterns
[ERROR]: <paste error message>
```

**Full prompt:**
```
User: Based on @.claude/skills/tsqlt-core.md patterns, my test is failing with:
      "Cannot insert into fake table - column 'ModifiedDate' does not allow nulls"

      Here's my test code: [paste code]
```

### Pattern 4: Compare + Skills + Recommend

```
[COMPARE]: Different testing approaches
[SKILLS]: From @.claude/skills/tsqlt-core.md
[RECOMMEND]: Best approach for my scenario
```

**Full prompt:**
```
User: From @.claude/skills/tsqlt-core.md, compare using FakeTable vs SpyProcedure
      for testing a procedure that sends emails. Which is better for my case
      where I only need to verify the email was called, not the content?
```

---

## Real-World Prompt Examples

### Example 1: Create Code Table Test

```
User: /tsqlt-unit-tests

Create a test for CT_ModelVersion that validates:
1. MODEL_VERSION_YEAR_FROM must be less than MODEL_VERSION_YEAR_TO
2. MODEL_VERSION_CODE must be unique

Include both passing and failing test cases.
```

### Example 2: Test Workflow with ACL

```
User: Using @.claude/skills/combined-patterns.md, create tests for the
      DCF workflow that verify:

      1. User with "Editor" role CAN see Submit action
      2. User with "Viewer" role CANNOT see Submit action
      3. Submitting actually changes the status

      The workflow procedure is usp_Template_LANA_DCF_Workflow_Get
```

### Example 3: Debug Failing Test

```
User: My test keeps failing. Using @.claude/skills/tsqlt-core.md, help me fix it:

CREATE PROCEDURE [Tests].[test_Something]
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo.Orders';

    INSERT INTO dbo.Orders (OrderId, CustomerId, OrderDate)
    VALUES (1, 100, GETDATE());

    -- Fails here: "Foreign key constraint violation"
END

The Orders table has FK to Customers.
```

### Example 4: Batch Test Generation

```
User: Run a sub-agent to:

1. Load @.claude/skills/combined-patterns.md
2. Read all CT_* table definitions from the database
3. Generate a test plan listing which validations each table needs
4. Create tests for the top 3 most critical tables

Prioritize tables with custom validation procedures.
```

### Example 5: Test Review

```
User: Using @.claude/skills/tsqlt-core.md and @.claude/skills/abylon-rapid.md,
      review these test files and identify:

      1. Missing edge cases
      2. Incorrect assertions
      3. Tables that should be faked but aren't
      4. Non-standard naming

      Files: @test-init/sample-tsqlt-tests.sql
```

---

## Tips for Better Results

### Do:
- Reference specific skill files when you need consistent patterns
- Combine skills when testing involves multiple domains
- Provide table/procedure names explicitly
- Include error messages when debugging
- Specify expected behavior clearly

### Don't:
- Assume Claude remembers previous skill context (re-reference if needed)
- Mix multiple unrelated requests in one prompt
- Skip the context - always explain what you're testing
- Forget to mention custom validation requirements

---

## Quick Reference Card

| Goal | Prompt Format |
|------|---------------|
| Load skill | `/command-name` or `@.claude/skills/file.md` |
| Create test | `Using @skill, create test for <table/proc>` |
| Debug test | `Using @skill, my test fails with: <error>` |
| Analyze code | `Using @skill, analyze @path/to/code.sql` |
| Batch work | `Run sub-agent with @skill to <task>` |
| Compare approaches | `From @skill, compare <A> vs <B> for <scenario>` |
