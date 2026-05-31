---
name: mid-sprint-start-sprint-planner
description: Guide for the Planner agent to start a sprint by creating the folder structure and moving stories into the sprint.
---

## When to use this skill

Use this skill when a sprint plan has been created and the sprint needs to be started.

## Instructions
1. Read the sprint plan to identify the sprint number and the stories selected for the sprint.
2. Create the sprint folder structure (see `Create Sprint Folder Structure`).
3. Move each selected story from the backlog into the sprint (see `Move Stories`).
4. Verify all stories listed in the sprint plan are present in `ready-for-dev/`.
5. Create and configure the scratch org for this sprint (see `Create Scratch Org`).
6. Notify the Orchestrator agent upon completion of the sprint setup.

## Create Scratch Org
1. Determine the sprint number from the sprint plan filename (e.g., `001`).
2. Create a scratch org according to the project conventions, using the following command:
   ```
   sf org create scratch --definition-file=config/project-scratch-def.json --alias=sprint[XXX] --duration-days=30
   ```
3. Verify the scratch org was created successfully and is accessible.

## Create Sprint Folder Structure
1. Determine the sprint number from the sprint plan filename.
2. Create the sprint folder at `/artefacts/stories/sprint[XXX]`, where [XXX] is a unique identifier matching the sprint plan number.
3. Include the following subfolders:
   - `ready-for-dev`
   - `in-development`
   - `ready-for-test`
   - `in-test`
   - `complete`

## Move Stories
- Move each selected story file from `/artefacts/stories/backlog` into `/artefacts/stories/sprint[XXX]/ready-for-dev`.
- Only move stories that are listed in the sprint plan.
- Do not move stories that are not in the sprint plan.

## Constraints
> All actions in this section must follow the project conventions.

- Do not modify the content of any story files.
- Do not modify the sprint plan.
- Do not create or delete any stories.
