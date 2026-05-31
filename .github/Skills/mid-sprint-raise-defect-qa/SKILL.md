---
name: mid-sprint-raise-defect-qa
description: Guide for the QA agent to raise a defect story when a user story fails testing.
---

## When to use this skill

Use this skill when a user story has failed QA testing and the QA agent needs to raise a defect for the Developer to fix.

## Instructions
1. Read the original story file and determine the failed acceptance criteria.
2. Read the project conventions and platform scope at `/.github/copilot-instructions.md`.
3. Determine the next available story number by checking existing story and defect files in both the current sprint and the full backlog folders.
4. Create the defect file (see `DEFECT TEMPLATE`).
5. Place the defect in the sprint's `in-development` folder.
6. Append a defect record to the **original** story file (see `DEFECT RECORD TEMPLATE`).
7. Leave the original story file in `in-test`.
8. Notify the Orchestrator agent that a defect has been raised.

## DEFECT TEMPLATE

Create a new file following the defect file naming convention:

```
# Defect [XXX] - [Short description of the defect]

## Original Story
- Story: [link/reference to the original story file]
- Story Title: [original story title]

## Defect Description
[Description of what is failing, based on the test results from the original story]

## Failed Acceptance Criteria
[List each AC from the original story that failed, with the failure details and evidence from the test results]

```

## DEFECT RECORD TEMPLATE

Append the following section to the **original** story file:

```
## Defect Record

Agent: QA Agent
Defect Story: [defect story file name]
Summary: [Brief summary of the raised defect].
```

## Constraints
> All actions in this section must follow the project conventions.

- Do not modify existing content on the original story file. Only append the `defect record template`.
- Do not move the original story file — it must remain in `in-test`.
- The defect story file must reference the original story - that is the story the defect is raised from.
