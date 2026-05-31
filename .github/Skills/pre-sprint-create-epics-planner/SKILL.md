---
name: pre-sprint-create-epics-planner
description: Guide for the Planner agent to create epics for Salesforce Development.
---

## When to use this skill

Use this skill when you have a problem definition that requires the creation of epics. 

## Instructions
1. Review the specified problem definition
2. Read the project conventions and platform scope at `/.github/copilot-instructions.md`.
3. Use the information to create clear and concise epics using the provided template (see `Epic Template`).
4. Ensure the epics are stored in the correct location with the appropriate naming convention (see `Storing the Artifact`).
5. Notify the Orchestrator agent upon completion of the epics.

## EPIC TEMPLATE
Each epic must use the following format:

1. Epic Title
- A clear and concise title that summarizes the epic.
2. Epic Description
- A narrative that provides a detailed explanation of the epic, including the who (actors involved), what (the functionality or feature to be developed), and why (the business value or problem being solved).
3. Scope and Boundaries
- A definition of what is included and excluded from the epic, as well as any assumptions or constraints.
4. Acceptance Criteria
- A set of conditions that must be met for the epic to be considered complete, including any specific requirements or success criteria. 

Related Problem Definition: [reference to related problem definition]

## Storing the Artifact
- Each epic must be saved as a markdown file in the `/artefacts/epics` directory. If it does not already exist, create the directory.
- The file name must follow the format `epic[xxx]--[short-description].md`, where [short-description] is a brief summary of the epic and where [xxx] is a unique identifier for the epic.

## Constraints
- Do not overwrite any details already present on the problem definition, only add the problem definition reference.
- Do not use tabular format for any of the outputted data.
