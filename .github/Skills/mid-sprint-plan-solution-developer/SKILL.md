---
name: mid-sprint-plan-solution-developer
description: Guide for the Developer agent to plan a solution for a user story.
---

## When to use this skill

Use this skill when you have been assigned a user story from the sprint plan and need to plan the technical solution before implementation.

## Instructions
1. Read the assigned user story.
2. Read the project conventions and platform scope at `/.github/copilot-instructions.md`.
3. Examine the existing codebase in `force-app/main/default`.
4. Determine the appropriate method of implementation (see `Implementation Knowledge`).
5. Produce a solution plan and append it to the story file (see `SOLUTION PLAN TEMPLATE`).
6. Move the story file from `ready-for-dev` to `in-development` within the sprint folder.
7. Notify the Orchestrator agent upon completion of the solution plan.

## Implementation Knowledge
Read the following skill files to understand Salesforce implementation conventions:
- `salesforce-apex-quality`
- `salesforce-component-standards`
- `salesforce-flow-design`

Use the knowledge from these skills to determine the correct approach for the user story. 
> Ensure declarative approaches are chosen over code unless the requirement cannot be met declaratively.

## SOLUTION PLAN TEMPLATE

Append the following section to the end of the story file:

```
## Solution Plan

### Salesforce Components
- List each component to be created or modified.
- For each component you work on, list the following: 
  - Name
  - Component Type
  - Purpose

### Implementation Logic
- Ordered list of steps the developer will follow to build the solution.

### Risks or Blockers
- Any risks or blockers identified.
```

## Constraints
> All actions in this section must follow the project conventions.

- Do not modify any part of the existing story content, you may only append the solution plan.
- Follow all naming conventions.
