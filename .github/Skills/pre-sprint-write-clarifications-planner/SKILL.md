---
name: pre-sprint-write-clarifications-planner
description: Guide for the Planner agent to record the User's responses to clarification questions into the clarifications document.
---

## When to use this skill

Use this skill when the Orchestrator has finished collecting the User's responses to the clarification questions and passes them back to you to be recorded.

## Instructions
1. Review the clarifications document and the responses provided by the Orchestrator.
3. Record each of the User's responses against the corresponding question (see `Recording Responses`).
4. Ensure the updated document is saved in the correct location (see `Storing the Artifact`).
5. Notify the Orchestrator agent upon completion.

## Recording Responses
Each response must be written directly below its corresponding question using the following format:
```
**Answer:** [User's response]
```
## Storing the Artifact
- The updated clarifications document must be saved back to its original location in the `/artefacts/clarifications` directory.

## Constraints
- Do not reformat, reorder, or remove any questions.
- Do not use tabular format for any of the outputted data.
- Only write the raw answer, do not paraphrase or summarise the given responses.
