# Skill Creation Checklist

Comprehensive checklist for creating and validating Claude Code skills. Complete all items before considering a skill production-ready.

> **Quick Validation:** Run `dart run .claude/skills/skill-create/scripts/validate.dart --skill {name}` to automatically check many of these items.

---

## Quick Status Check

```bash
# Validate skill structure and content
dart run .claude/skills/skill-create/scripts/validate.dart --skill {skill-name}

# Generate detailed report
dart run .claude/skills/skill-create/scripts/validate.dart --skill {skill-name} --report

# Validate all skills
dart run .claude/skills/skill-create/scripts/validate.dart --all
```

---

## Phase 1: Planning

### 1.1 Purpose Definition

- [ ] Core problem identified (1-2 sentences)
- [ ] Target user/scenario defined
- [ ] Success criteria established
- [ ] Category determined (Code-Heavy, Auth, Config, Knowledge, Orchestration)

### 1.2 Scope Definition

- [ ] What skill DOES handle (explicit list)
- [ ] What skill does NOT handle (delegation list)
- [ ] Related skills identified
- [ ] No overlap with existing skills confirmed

### 1.3 Trigger Words

- [ ] Primary keywords identified (3-5 words)
- [ ] Secondary triggers identified (variations, synonyms)
- [ ] User question patterns documented
- [ ] Example invocations listed

---

## Phase 2: Structure

### 2.1 Directory Creation

- [ ] Skill directory created: `.claude/skills/{skill-name}/`
- [ ] SKILL.md file created
- [ ] Appropriate subdirectories created:
  - [ ] `reference/` (if skill generates Dart code)
  - [ ] `templates/` (if skill uses platform configs)
  - [ ] `scripts/` (if skill needs validation)

### 2.2 File Organization

| Category | Required Structure |
|----------|-------------------|
| Code-Heavy | `reference/{models,repositories,providers}/` |
| Auth | `reference/`, `templates/`, guides |
| Config | `templates/`, guides, `scripts/check.dart` |
| Knowledge | guides, `examples.md`, `scripts/check.dart` |
| Orchestration | guides, `templates/` |

### 2.3 Naming Conventions

- [ ] Skill name is lowercase with hyphens only
- [ ] Skill name < 64 characters
- [ ] Skill name is descriptive and unique
- [ ] No reserved words (anthropic, claude)
- [ ] Guide files use `{topic}-guide.md` pattern
- [ ] Reference files use descriptive names

---

## Phase 3: SKILL.md Content

### 3.1 Frontmatter (Required)

```yaml
---
name: skill-name
description: Third person description with trigger words. Use when...
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---
```

**Validation:**
- [ ] `name` matches directory name
- [ ] `name` is valid (lowercase, hyphens, < 64 chars)
- [ ] `description` < 1024 characters
- [ ] `description` is third person ("Generates..." not "I can...")
- [ ] `description` includes trigger words
- [ ] `description` includes "Use when..." clause
- [ ] `allowed-tools` lists only needed tools

### 3.2 Required Sections

- [ ] `# {Skill Name}` - Title with brief description
- [ ] `## When to Use This Skill` - Clear scenarios (3-5 bullets)
- [ ] `## Workflow` - Numbered implementation steps
- [ ] `## Guides` - Table linking to detailed content
- [ ] `## Checklist` - Verification items (> 3 items)
- [ ] `## Related Skills` - Cross-references with brief descriptions

### 3.3 Recommended Sections

- [ ] `## Quick Reference` - Decision tables, key patterns
- [ ] `## Questions to Ask` - Clarifying questions before implementation
- [ ] `## Commands` - CLI invocations
- [ ] `## Common Issues` - Troubleshooting table
- [ ] `## When NOT to Use` - Boundary clarification

### 3.4 Content Quality

- [ ] SKILL.md < 300 lines (ideal: 150-200)
- [ ] No code blocks > 10 lines
- [ ] All internal links resolve to existing files
- [ ] Guides table links are accurate
- [ ] Checklist items are actionable and verifiable

### 3.5 Skill Boundaries

Skills must not include detailed how-to content that belongs to other skills:

- [ ] No "### Localization" or "### Localized Message" sections (delegate to `/i18n`)
- [ ] No "### Custom Colors" or styling instructions (delegate to `/design`)
- [ ] No "### Accessibility" or semantics instructions (delegate to `/a11y`)
- [ ] No "### Unit Tests" or testing code examples (delegate to `/testing`)
- [ ] Simple delegation like "Run `/i18n`" is OK; detailed instructions are NOT

---

## Phase 4: Supporting Files

### 4.1 Guide Files

For each guide file:
- [ ] Clear title and purpose
- [ ] Sections with horizontal rules
- [ ] Code examples use `**See:** reference/path.dart` pattern
- [ ] Short inline code only (< 10 lines)
- [ ] Links to related guides/skills

### 4.2 Reference Files (Code-Heavy/Auth skills)

For each reference file:
- [ ] Standard header comment:
  ```dart
  // Template: {Brief description}
  //
  // Location: lib/features/{feature}/data/...
  //
  // Usage:
  // 1. Copy to target location
  // 2. Rename placeholders
  // 3. Run build_runner if using Freezed
  ```
- [ ] Complete, runnable code
- [ ] Follows project conventions (final classes, private functions)
- [ ] No hardcoded values (uses placeholders)
- [ ] Proper imports

### 4.3 Template Files (Config skills)

For each template file:
- [ ] Correct file extension
- [ ] Placeholders clearly marked (e.g., `{{APP_NAME}}`, `YOUR_VALUE_HERE`)
- [ ] Comments explaining required customizations
- [ ] Valid syntax for target platform

### 4.4 Validation Script (scripts/check.dart)

- [ ] Script exists and runs without error
- [ ] Help text via `--help`
- [ ] Feature filtering via `--feature {name}`
- [ ] Clear output with categorized issues
- [ ] Exit code 0 if pass, 1 if issues found
- [ ] JSON output option for CI: `--json`
- [ ] Auto-fix option where appropriate: `--fix`

---

## Phase 5: Validation

### 5.1 Automated Validation

```bash
dart run .claude/skills/skill-create/scripts/validate.dart --skill {skill-name}
```

**Checks:**
- [ ] Structure check passes
- [ ] Frontmatter check passes
- [ ] Content check passes
- [ ] Links check passes
- [ ] References check passes

### 5.2 Manual Validation

- [ ] Read SKILL.md end-to-end
- [ ] All workflows make sense
- [ ] Checklist is complete and actionable
- [ ] Cross-references are accurate
- [ ] No typos or unclear language

### 5.3 Functional Testing

- [ ] Invoke skill with typical request
- [ ] Verify Claude finds correct reference files
- [ ] Verify workflow produces expected output
- [ ] Test with edge cases
- [ ] Verify error handling in check script

---

## Phase 6: Integration

### 6.1 SKILL_STRUCTURE.md Updates

- [ ] Add to "Complete Skill Reference" table:
  ```markdown
  | `/skill-name` | Category | Purpose | Run After |
  ```
- [ ] Add to "Skill Flow Diagram" if it affects main flows
- [ ] Add to "What Each Skill Should NOT Do" table if delegating
- [ ] Add to "Skill Sequences" if part of common workflows

### 6.2 Cross-Skill References

- [ ] Related skills' "Related Skills" sections updated
- [ ] Delegation from other skills documented
- [ ] Handoff patterns documented in "Next Steps"

### 6.3 CLAUDE.md Updates

If skill is user-invocable:
- [ ] Add to "Available Skills" table in CLAUDE.md
- [ ] Description matches SKILL.md frontmatter
- [ ] Workflow reference is accurate

---

## Phase 7: Quality Assurance

### 7.1 Content Review

- [ ] No duplicate content with other skills
- [ ] Consistent terminology with other skills
- [ ] Follows project conventions
- [ ] No over-engineering

### 7.2 Security Review (if applicable)

- [ ] No secrets in templates
- [ ] Security considerations documented
- [ ] Sensitive file patterns documented

### 7.3 Accessibility Review (if UI-related)

- [ ] Accessibility considerations noted
- [ ] References to /a11y skill for details

---

## Quality Gates Summary

### Required (Must Pass)

| Gate | Criteria |
|------|----------|
| Structure | SKILL.md exists, valid directory structure |
| Frontmatter | Valid name, description < 1024 chars, tools listed |
| Content | All required sections present |
| Links | All internal links resolve |

### Recommended (Should Pass)

| Gate | Criteria |
|------|----------|
| Length | SKILL.md < 300 lines |
| Code | No inline blocks > 10 lines |
| References | Header comments on all reference files |
| Validation | check.dart exists and passes |
| Integration | Registered in SKILL_STRUCTURE.md |

---

## Common Issues

| Issue | Fix |
|-------|-----|
| Description too long | Shorten to < 1024 chars, move details to guides |
| Missing trigger words | Add "Use when..." clause with keywords |
| Broken links | Verify file paths, use relative links |
| Workflow unclear | Number steps, add phase headers |
| Checklist too vague | Make items specific and verifiable |
| Too much inline code | Move to `reference/` files |
| Missing delegation | Add "Next Steps" section with related skills |
| Not registered | Update SKILL_STRUCTURE.md tables |

---

## Automated Check

Run the validation script:

```bash
dart run .claude/skills/skill-create/scripts/validate.dart --skill {skill-name}
```

This validates:
- Directory structure
- SKILL.md frontmatter
- Required sections
- Internal links
- Reference file headers
- Line count limits
