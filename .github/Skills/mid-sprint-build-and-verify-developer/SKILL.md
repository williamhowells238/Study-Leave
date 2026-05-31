---
name: mid-sprint-build-and-verify-developer
description: Guide for the Developer agent to implement a solution, deploy to scratch org, verify, and create a PR.
---

## When to use this skill

Use this skill when you need to implement a solution based on the solution plan in a user story..

## Instructions
1. Read the user story file.
2. Read the project conventions and platform scope at `/.github/copilot-instructions.md`.
3. Create a feature branch from the target branch (see `Branch Management`).
4. Implement the solution (see `Implementation`).
5. Deploy and verify the solution (see `Deploy and Verify`).
6. If the verification fails, diagnose, fix, and redeploy the implementation. Repeat until it verification is passed.
7. Run a code quality check (see `Code Quality Check`).
8. Create a Pull Request into the target branch (see `Create Pull Request`).
9. Append an implementation record to the story file (see `IMPLEMENTATION RECORD TEMPLATE`).
10. Notify the Orchestrator agent upon completion of the Pull Request.

## Branch Management
- Checkout the target branch.
- Pull the latest changes.
- Create the new feature branch following the branch naming and conflict resolution rules.

## Implementation

### General Rules
- Follow the solution plan's implementation steps and use component list.
- Follow all naming conventions.
- If there is a need to deviate from the solution plan, do not update the user story file, just implement.

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

## Create Pull Request
- Commit all changes following the commit conventions.
- Push the feature branch to the repository.
- Create a Pull Request following the Pull Request conventions.

## IMPLEMENTATION RECORD TEMPLATE

Append the following section to the story file:

```
## Implementation Record

Agent: Developer Agent
Branch: [branch name]
PR: [PR link]
Summary: [Brief description of the implementation journey]
```

## Constraints
> All actions in this section must follow the project conventions.

- Do not modify existing content on the story file. Only append the implementation record.
- Do not merge the pull request.
- Do NOT move the story file to `ready-for-test`. It must remain in `in-development` until the Architect merges the PR and moves it.