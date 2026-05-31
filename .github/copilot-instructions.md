# Project Conventions
---

## 1. Naming Standards

All Salesforce custom components must be prefixed with `EPA_` followed by a descriptive CamelCase name and a component type suffix.

The pattern is: `EPA_CamelCaseName_Suffix`

### Custom Objects
- Pattern: `EPA_CamelCaseName__c`

### Custom Fields
- Pattern: `EPA_CamelCaseName__c`

### Custom Metadata Types
- Pattern: `EPA_CamelCaseName__mdt`

### Apex Classes
- Pattern: `EPA_CamelCaseName_Class`

### Apex Test Classes
- Pattern: `EPA_CamelCaseName_TestClass`

### Apex Triggers
- Pattern: `EPA_CamelCaseName_Trigger`

### LWC Components
- Pattern: `epa_CamelCaseName_LWC`
** Note LWC names must start with a lowercase letter **

### Flows
- Pattern: `EPA_CamelCaseName_Flow`

### Validation Rules
- Pattern: `EPA_CamelCaseName_ValidationRule`

### Permission Sets
- Pattern: `EPA_CamelCaseName_PermissionSet`

### Email Templates
- Pattern: `EPA_CamelCaseName_EmailTemplate`

### Record Types
- Pattern: `EPA_CamelCaseName_RecordType`

---

## 2. Flowerboxing Standards

All Apex classes and triggers must include a flowerbox comment at the top of the file.

### Class Flowerbox
All Apex classes should include this flowerbox header. 
```
/**
 * @description: Brief description of the class
 * @author: Agent name
 * @date: YYYY-MM-DD
 */
```

### Method Flowerbox
All Apex methods must include a flowerbox comment.
```
/**
 * @description: Brief description of the method
 * @param paramName Description of the parameter
 * @return Description of the returned data
 */
```
---
## 3. Git Standards

### Branches
- Feature: `feature/[XXX]`, where [XXX] is the story number
- Defect: `defect/[XXX]`, where [XXX] is the story number
- Base branch: `DEV2`
- If a branch already exists, create a new branch with suffix `-v2` or greater.
** Note: Reuse the same branch for all changes on the same story **

### Commits
- Story: `story-[XXX]: short description`, where [XXX] is the story number
- Amendment: `amendment-[XXX]: short description`, where [XXX] is the story number
- Defect: `defect-[XXX]: short description`, where [XXX] is the story number

### Pull Requests

#### Story PRs
- Title: `story-[XXX]: short description`, where [XXX] is the story number
- Body: Summary of the implementation.
- Target: `DEV2`

#### Defect PRs
- Title: `defect-[XXX]: short description`, where [XXX] is the story number
- Body: Summary of the defect fix, referencing the original story and which failures are addressed.
- Target: `DEV2`

### Story Files
- Story: `story[XXX]--short-description.md`, where [XXX] is the story number
- Defect: `defect[XXX]--short-description.md`, where [XXX] is the story number
>Story and Defect Numbers are sequential and dependant on each other.

### Salesforce Org
- Developer-Org: `EPA-DEV` Username: `wgh238w.5c7fd5840fac@agentforce.com`
- Scratch Org Definition: `config/project-scratch-def.json` - use this to build the scratch org
- Scratch Org: `sprint[XXX]` created at the start of each sprint.
- **All development and deployment takes place in the sprint's scratch org, do not deploy into the Dev Hub.**

---

## 4. Git Staging Rules

- Only stage files inside `force-app/` for commits. Use `git add force-app/` and **NEVER ** `git add -A` or `git add .`.
- Never commit artefact files (`/artefacts/`) to the repository via git staging. Artefact files are managed separately.
- Always run `git status` after staging to verify that only `force-app/` files are included before committing.

---

## 5. Platform Scope

- This project targets **Salesforce Core Cloud** only (Sales Cloud, Service Cloud, Platform).
- The MVP is built on a **Developer Edition org** with limited full Salesforce user licences.
- Every solution must be delivered as a **self-contained Salesforce application**: one app, multiple tabs, with all core functionality accessible from a single navigation experience.
- Solutions should demonstrate **security and access-control concepts** (profiles, permission sets, object/field access, tab visibility) using a small user set appropriate for a Developer Edition org.
- No external integrations, multi-org architectures, or Experience Cloud sites are in scope for the MVP.
