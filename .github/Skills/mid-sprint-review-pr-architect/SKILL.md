---
name: mid-sprint-review-pr-architect
description: Guide for the Architect agent to review a Pull Request, run quality checks, and merge on approval.
---

## When to use this skill

Use this skill when a Developer has raised a Pull Request for a feature branch or a defect branch.

## Instructions
1. Read the story file including the acceptance criteria and solution plan.
2. Read the project conventions and platform scope at `/.github/copilot-instructions.md`.
3. Run code quality checks (see `Code Quality Checks`).
4. Append the result to the story file (see `PR REVIEW TEMPLATE`).
5. Return a result: `Approved` or `Rejected`.
6. Only if **Approved**: merge the PR into the target branch and move the story file from `in-development` to `ready-for-test`.
7. If **Rejected**: leave the story file in its current folder.
8. Notify the Orchestrator agent upon completion of the review.

## Code Quality Checks
1. Read the MCP tools in `.sfdx/mcp-tools` and determine which tools to use for code analysis checks.
2. Run the analysis on all the files changed in the PR.
3. Review the analysis, highlighting any issues of a high severity.


## PR REVIEW TEMPLATE

After completing the review, append the following section to the story file:

```
## PR Review - [PR Name]

Result: Approved / Rejected

### Summary
- Brief summary of the review findings.

### Changes to be made
- If Rejected, list the required changes with clear and actionable feedback for the Developer to address.
```

Where [`PR Name`] is the name of the Pull Request.

## Constraints
- Do not modify the codebase. Review only, and merge if approved.
- Move the story file to `ready-for-test` only after a successful merge.
- Do not modify existing content on the story file. Only append the result section.
