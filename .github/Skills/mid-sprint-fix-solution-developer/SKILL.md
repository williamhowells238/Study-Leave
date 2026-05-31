---
name: mid-sprint-fix-solution-developer
description: Guide for the Developer agent to fix a solution after an Architect PR rejection or a QA test failure on a defect story.
---

## When to use this skill

Use this skill when either a defect has failed QA testing or a PR has received Architect review feedback and the solution needs to be fixed.

## Instructions
2. Read the story file, in particular the Architect review findings or QA test failure details section.
3. Read the project conventions and platform scope at `/.github/copilot-instructions.md`.
4. Checkout the existing branch for the story and pull the latest changes.
5. Fix the solution in alignment with the feedback (see `Implementation`).
6. Deploy and verify the solution (see `Deploy and Verify`).
7. If the verification fails, diagnose, fix, and redeploy the implementation. Repeat until verification is passed.
8. Run a code quality check (see `Code Quality Self-Check`).
9. Update the repository (see `Updating the Repository`).
10. Append a fix record to the story file (see `FIX RECORD TEMPLATE`).
11. Notify the Orchestrator agent upon completion of the fix.

## Implementation

### For PR Review Rejections
- Address each item highlighted in the review.

### For QA Test Failures
- Analyse each reported failure against the acceptance criteria.
- Fix the root cause of each failure.

### General Rules
- Follow the solution plan's implementation steps and use component list.
- Follow all naming conventions.
- If there is a need to deviate from the solution plan, do not update the story file, just implement.

### Salesforce Skill Guardrails
- Read the Salesforce skills located in `.github/Skills/`, they are prefixed with `Salesforce` and must be read before writing any code or building any components.
- Follow the guardrails defined in each Salesforce skill throughout the implementation.

## Deploy and Verify
1. Read the available MCP tools in `.sfdx/mcp-tools` to determine which tools to use for deployment and testing.
2. Deploy the solution to the project's Developer-Org.
3. Run relevant tests to verify the deployment.
4. If deployment or tests fail, diagnose the issue, fix it, and redeploy.

## Code Quality Self-Check
1. Read the available MCP tools in `.sfdx/mcp-tools` to determine which tools to use for code analysis.
2. Scan the files created or modified in this story.
3. Review and fix all issues of the highest severity type.
4. Re-deploy and re-test the code after implementing the fixes.

## Updating the Repository
- Commit all changes following the amendment commit convention.
- Push the changes to the existing branch.

## FIX RECORD TEMPLATE

Append the following section to the story file:

```
## Fix Record

Agent: Developer Agent
Branch: [branch name]
PR: [PR link]
Summary: [Short description of the fix]
```

## Constraints
> All actions in this section must follow the project conventions.

- Do not modify existing content on the story file. Only append the fix record.
- Do not merge the pull request.
