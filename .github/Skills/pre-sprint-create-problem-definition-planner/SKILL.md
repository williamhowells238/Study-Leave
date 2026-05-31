---
name: pre-sprint-create-problem-definition-planner
description: Guide for the Planner agent to create problem definitions for Salesforce Development.
---

## When to use this skill

Use this skill when you have a business problem that requires the creation of problem definitions. 

## Instructions
1. Review the business problem provided
2. Read the project conventions and platform scope at `/.github/copilot-instructions.md`.
3. Read the Project-Implementation document to understand the current project context.
4. Read the latest Clarifications document to understand any clarifications that have been made regarding the problem.
4. Use the information to create a clear and concise problem definition using the provided template (see `Problem Definition Template`).
5. Ensure the problem definition is stored in the correct location with the appropriate naming convention (see `Storing the Artifact`).
6. Notify the Orchestrator agent upon completion of the problem definition.

## PROBLEM DEFINITION TEMPLATE
The problem definition must use the following format:

1. Problem Definition
-  A specific and measurable statement that clearly defines the problem to be solved. 

2. Problem Background
- A brief overview of the context and circumstances surrounding the problem inlcuding its current state.

3. Problem Scope
- A definition of what is and isn't included in the problem as well as highlighting any assumptions or constraints.

4. Problem Impact
- An analysis of the potential consequences and effects of the problem on the business, users, and other stakeholders.

5. Affected Stakeholders
- Identification of the individuals, groups, or organizations that are impacted by the problem.

## Storing the Artifact
- The problem definition must be saved as a markdown file in the `/artefacts/problem-definitions` directory. If it does not already exist, create the directory.
- The file name must follow the format `problem-definition-[short-description].md`, where [short-description] is a brief summary of the problem.

## Constraints
- Do not overwrite any details already present on the stories, only add the testing estimates.
- Do not use tabular format for any of the outputted data.
