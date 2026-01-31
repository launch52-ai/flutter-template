---
name: l52-base
description: Shared rules for all l52-* Flutter skills
user-invocable: false
disable-model-invocation: true
---

# Base Rules for All l52 Skills

## Completion Behavior

- After completing a skill, STOP and summarize what was done
- Do NOT automatically chain to the next skill
- Wait for explicit user instruction before proceeding

## Session Continuations

- After context compaction, only complete the specific task in progress
- "Pending tasks" in summaries are NOT instructions to proceed
- If unsure what was asked, ask the user

## Before Any Implementation

Always check:
1. Project's `CLAUDE.md` for project-specific rules
2. Existing code patterns in the codebase

## Code Style (Flutter)

- Classes: `final class`
- Functions: `private` where possible (`_functionName`)
- Variables: `final` where possible
- No hardcoded strings - use `AppStrings.*`
- No hardcoded colors - use `AppColors.*`
- Text fields: always `autocorrect: false`

## File Organization

- Screen files: 100-200 lines max
- Extract widgets to `widgets/` folder when file grows
- One class per file (except small helper widgets)

## When to Ask vs Proceed

ASK when:
- Multiple valid approaches exist
- Requirements are unclear
- Changing existing patterns

PROCEED when:
- User gave specific instructions
- Following established patterns
- Single obvious solution
