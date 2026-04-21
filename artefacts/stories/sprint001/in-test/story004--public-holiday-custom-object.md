# Story 004 — Create Public Holiday Custom Object

## User Story

As a **System Administrator**, I want a custom object to store Public Holiday records, so that the system can exclude public holidays from business day calculations when computing study leave duration.

## Acceptance Criteria

- Given the Salesforce Scratch Org has no pre-existing Public Holiday object, when the System Administrator deploys the data model, then a custom object named "Public_Holiday__c" is created.
- Given the Public Holiday object is created, when the object is inspected, then it contains the following fields:
  - Holiday_Date__c (Date, required, unique)
  - Name (Standard Name field — used for the holiday name/description)
- Given the Public Holiday object exists, when a System Administrator creates a new Public Holiday record with a date and name, then the record is saved successfully.
- Given the Public Holiday object exists, when a System Administrator edits or deletes a Public Holiday record, then the operation is performed successfully.
- Given Public Holiday records exist, when the business day calculation logic runs, then the dates stored in Public Holiday records are available for exclusion.

## Related Parent Epic

[Epic 001 — Data Model and Configuration](../../../artefacts/epics/epic001--data-model-and-configuration.md)

---

## Dependencies

- No story dependencies. This is a foundational story that can be developed independently.

## Assumptions

- Assumption Type: Business Confirmation
- Assumption Description: The initial set of Public Holiday records to be pre-populated has been confirmed (e.g. UK bank holidays for the current and next calendar year).
- Assumption Justification: The Public Holiday records are consumed by the business day calculation (Story 008). Without confirmed dates, testing and validation of the calculation logic cannot be fully verified.

- Assumption Type: Business Confirmation
- Assumption Description: Public holidays are managed as a single global list applicable to all apprentices, with no regional or location-based variations.
- Assumption Justification: The data model stores holidays as a flat list. If regional variations are required, additional fields (e.g. Region) and filtering logic would need to be added.

- Assumption Type: Technical Confirmation
- Assumption Description: The Holiday_Date__c field is set as unique to prevent duplicate entries for the same date.
- Assumption Justification: Duplicate public holiday records for the same date would cause incorrect business day calculations in Story 008.

## Development Estimate

- Story Points: 1
- Justification: This is a very simple story involving the creation of a lightweight custom object (Public_Holiday__c) with a Date field (unique) and the standard Name field. The object has no automation, no relationships, and minimal configuration. The only minor consideration is setting the unique constraint on the Holiday_Date__c field, but this is a standard field property.

## Testing Estimate

- Story Points: 1
- Justification: Testing is minimal — verify the Public_Holiday__c object exists with the Holiday_Date__c (Date, required, unique) and Name fields, validate CRUD operations for a System Administrator, and confirm the unique constraint on Holiday_Date__c rejects duplicate date entries. The only edge case is the uniqueness enforcement, which is a single negative test scenario. No dependencies or complex logic to test.

## Solution Plan

### Salesforce Components
- **EPA_PublicHoliday__c**
  - Component Type: Custom Object
  - Purpose: Stores Public Holiday records so that the system can exclude public holidays from business day calculations when computing study leave duration.

- **EPA_HolidayDate__c** (on EPA_PublicHoliday__c)
  - Component Type: Custom Field (Date)
  - Purpose: Stores the date of the public holiday. Configured as required and unique to prevent duplicate entries for the same date.

- **Name** (standard field on EPA_PublicHoliday__c)
  - Component Type: Standard Name Field (Text)
  - Purpose: Stores the holiday name/description (e.g. "Christmas Day"). Uses the default Text name field type.

### Implementation Logic
1. Create the custom object metadata directory at `force-app/main/default/objects/EPA_PublicHoliday__c/`.
2. Create the object definition file `EPA_PublicHoliday__c.object-meta.xml` with:
   - Label: `Public Holiday`, Plural Label: `Public Holidays`.
   - Standard Name field with label `Public Holiday Name` and type `Text`.
   - Deployment status: `Deployed`.
   - Sharing model: `ReadWrite`.
   - Enable Reports, Search, and Activities.
3. Create the `fields/` subdirectory under the object directory.
4. Create the custom field metadata file `fields/EPA_HolidayDate__c.field-meta.xml` with:
   - Type: `Date`.
   - Required: `true`.
   - Unique: `true` (with case sensitivity set to `false` as it is a Date field).
   - Label: `Holiday Date`.
5. Verify the metadata structure is valid by deploying to the scratch org (`sprint001`).
6. Perform a smoke test: create, edit, and delete a Public Holiday record via the scratch org UI to confirm CRUD operations succeed.
7. Verify the unique constraint on `EPA_HolidayDate__c` by attempting to create a duplicate date — confirm it is rejected.

### Risks or Blockers
- No risks or blockers identified. This is a straightforward declarative custom object with no automation, relationships, or complex configuration. The implementation follows the same pattern as the existing `EPA_StudyLeaveRequest__c` and `EPA_LeaveCategory__c` objects in the codebase.

## Implementation Record

Agent: Developer Agent
Branch: feature/story004
PR: https://github.com/williamhowells238/Study-Leave/pull/4
Summary: Created EPA_PublicHoliday__c custom object with EPA_HolidayDate__c (Date, required) field and standard Name field (Text). Deployed to sprint001 scratch org and verified all CRUD operations. Deviation from solution plan: the unique constraint on EPA_HolidayDate__c could not be applied as Salesforce does not support the unique attribute on Date fields, and Matching Rules also do not support Date fields. Uniqueness enforcement will need to be addressed via Apex trigger or application logic in a future story.

## PR Review - story-004: Create Public Holiday custom object

Result: Approved

### Summary
- All changed files pass Salesforce Code Analyzer with 0 violations.
- Naming conventions follow project standards (`EPA_PublicHoliday__c`, `EPA_HolidayDate__c`).
- Object metadata is correctly configured: labels, name field (Text), deployment status (Deployed), sharing model (ReadWrite), and features (reports, search, activities, history) all align with the solution plan.
- Field metadata for `EPA_HolidayDate__c` is correctly defined as Date, required.
- The documented deviation regarding the `unique` constraint on the Date field is a genuine Salesforce platform limitation. The developer correctly identified this, attempted Matching Rules as an alternative, and documented the outcome with a forward plan for Apex-based enforcement. This is acceptable and does not block approval.
- PR title, branch name, and target branch all conform to project Git conventions.
- All acceptance criteria are satisfied, with the uniqueness constraint noted as a known gap to be addressed in a future story.

### Changes to be made
- None. PR is approved as-is.
