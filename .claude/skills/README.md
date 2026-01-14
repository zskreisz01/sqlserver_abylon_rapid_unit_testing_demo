# Claude Skills for SQL Server Unit Testing

This folder contains **Claude Skills** - structured knowledge files that provide Claude with domain-specific expertise for creating effective unit tests.

## What are Claude Skills?

Claude Skills are markdown files that encode:
- **Domain knowledge** - specific patterns, conventions, and best practices
- **Code templates** - reusable patterns Claude can apply
- **Context** - framework-specific details Claude needs to generate correct code

Skills are loaded via:
1. **Slash commands** (`/command-name`) - interactive skill invocation
2. **Sub-agent prompts** - programmatic skill loading in multi-step workflows
3. **Direct file references** - including skill content in prompts

## Folder Structure

```
.claude/
├── commands/                    # Slash commands (invoked with /)
│   ├── tsqlt-unit-tests.md     # /tsqlt-unit-tests - Full LANA project patterns
│   └── create-test.md          # /create-test - Quick test creation workflow
│
├── skills/                      # Knowledge files (referenced in prompts)
│   ├── README.md               # This file
│   ├── tsqlt-core.md           # Core tSQLt patterns (generic, reusable)
│   ├── abylon-rapid.md         # AbylonRapid framework specifics
│   ├── combined-patterns.md    # Integration patterns & complete examples
│   └── prompting-guide.md      # How to use skills effectively
│
└── settings.json               # MCP servers and tool configuration
```

## Skill Types

### 1. Generic Skills (Reusable Across Projects)
- `tsqlt-core.md` - Pure tSQLt framework knowledge
- Can be copied to any SQL Server project

### 2. Framework-Specific Skills
- `abylon-rapid.md` - AbylonRapid-specific patterns
- Project-specific conventions and procedures

### 3. Combined Skills
- `combined-patterns.md` - How to combine tSQLt with AbylonRapid
- Integration patterns and complete examples

## How to Use Skills

### Method 1: Slash Commands
```
User: /tsqlt-unit-tests
Claude: [Skill loaded] I can now help you create tSQLt tests...
```

### Method 2: Reference in Prompts
```
User: Using the patterns in @.claude/skills/tsqlt-core.md, create a test for...
```

### Method 3: Sub-Agent with Skill Context
```
User: Run a sub-agent with @.claude/skills/abylon-rapid.md to analyze the CT_Country table
```

### Method 4: Combine Multiple Skills
```
User: Load @.claude/skills/tsqlt-core.md and @.claude/skills/abylon-rapid.md
      then create a validation test for the Currency code table
```

## Creating New Skills

### Skill File Template
```markdown
# Skill Name

Brief description of what this skill provides.

## Quick Reference
| Item | Description |
|------|-------------|
| ... | ... |

## Patterns

### Pattern Name
```sql
-- SQL template
```

## Examples

### Example: Scenario Name
```sql
-- Complete working example
```

## Notes
- Important considerations
- Common pitfalls
```

### Best Practices for Skill Files

1. **Be Specific** - Include exact table names, column names, procedure signatures
2. **Provide Templates** - Give copy-paste-ready code blocks
3. **Include Examples** - Show complete working tests
4. **Document Conventions** - File naming, folder structure, deployment
5. **Reference Documentation** - Link to official docs

## Skill Versioning

Skills should include version information when framework versions matter:
```markdown
## Compatibility
- tSQLt: v1.0.8053.36458
- AbylonRapid: v2.x
- SQL Server: 2019+
```

## See Also

- [tSQLt Official Documentation](https://tsqlt.org/)
- [AbylonRapid Framework Docs](internal-link)
