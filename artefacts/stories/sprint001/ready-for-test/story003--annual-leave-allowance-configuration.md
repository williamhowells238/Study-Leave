# Story 003 — Create Annual Study Leave Allowance Configuration

## User Story

As a **System Administrator**, I want a configurable setting to define the annual study leave allowance for apprentices, so that the system can enforce the maximum number of study leave days per calendar year without code changes.

## Acceptance Criteria

- Given the Salesforce Scratch Org has no pre-existing allowance configuration, when the System Administrator deploys the configuration, then a custom object or Custom Setting named "Study_Leave_Allowance__c" (or equivalent) is created with a field to store the annual allowance value in days.
- Given the allowance configuration exists, when the System Administrator views the configuration, then a default value of 20 days is set.
- Given the allowance configuration exists, when a System Administrator updates the allowance value, then the new value is saved successfully and takes effect for all subsequent leave balance calculations.
- Given the allowance configuration exists, when the system retrieves the annual allowance for validation or display, then the correct configured value is returned.

## Related Parent Epic

[Epic 001 — Data Model and Configuration](../../../artefacts/epics/epic001--data-model-and-configuration.md)

---

## Dependencies

- No story dependencies. This is a foundational configuration story that can be developed independently.

## Assumptions

- Assumption Type: Business Confirmation
- Assumption Description: The annual study leave allowance of 20 days is a single global value that applies uniformly to all apprentices, not a per-apprentice or per-department setting.
- Assumption Justification: The acceptance criteria describe a single configurable value. If the allowance varies by apprentice or department, the data model and validation logic (Story 009) would need significant changes.

- Assumption Type: Business Confirmation
- Assumption Description: The allowance is based on a calendar year (January to December), not an academic year or financial year.
- Assumption Justification: Story 009 references "per-calendar-year" validation. If a different year boundary is required, the balance calculation logic would need to be adjusted.

- Assumption Type: Technical Confirmation
- Assumption Description: A Custom Setting (Hierarchy or List) or Custom Metadata Type will be used to store the allowance value, rather than a custom object, to allow easy retrieval in validation rules, Apex, and Flows without SOQL overhead.
- Assumption Justification: Custom Settings and Custom Metadata Types are best practice for application configuration values in Salesforce and provide efficient access in automation contexts.

## Development Estimate

- Story Points: 1
- Justification: This is a very simple configuration story. It involves creating a single Custom Setting or Custom Metadata Type with one field to store the annual allowance value and setting a default of 20 days. There are no dependencies, no automation, and no complex logic. The work is entirely declarative and minimal in scope.

## Testing Estimate

- Story Points: 1
- Justification: Testing is minimal — verify the Custom Setting or Custom Metadata Type exists with the allowance field, confirm the default value is 20 days, validate that the value can be updated by an administrator, and confirm the updated value is retrievable. No dependencies, no complex scenarios, and no edge cases. A straightforward verification of the configuration and its accessibility.

## Solution Plan

### Salesforce Components
- **EPA_StudyLeaveAllowance__mdt**
  - Name: `EPA_StudyLeaveAllowance__mdt`
  - Component Type: Custom Metadata Type
  - Purpose: Stores the configurable annual study leave allowance value. Custom Metadata Type is chosen over Custom Setting because it is deployable via metadata API (fits source-driven development with scratch orgs), can be queried efficiently without counting against SOQL limits when accessed via `getInstance()` patterns, and records are included in deployments — making them ideal for application configuration values.

- **EPA_AnnualAllowanceDays__c**
  - Name: `EPA_AnnualAllowanceDays__c`
  - Component Type: Custom Field (Number) on `EPA_StudyLeaveAllowance__mdt`
  - Purpose: Stores the numeric value representing the maximum number of study leave days an apprentice is entitled to per calendar year. Field type is Number (no decimal places) to ensure whole-day values only.

- **EPA_Default (Custom Metadata Record)**
  - Name: `EPA_Default`
  - Component Type: Custom Metadata Type Record for `EPA_StudyLeaveAllowance__mdt`
  - Purpose: The default configuration record with `EPA_AnnualAllowanceDays__c` set to `20`. This provides the out-of-the-box allowance value as specified in the acceptance criteria. The System Administrator can update this value via Setup without code changes.

### Implementation Logic
1. Create the Custom Metadata Type `EPA_StudyLeaveAllowance__mdt` with label "EPA Study Leave Allowance" and plural label "EPA Study Leave Allowances" in `force-app/main/default/objects/EPA_StudyLeaveAllowance__mdt/`.
2. Create the custom field `EPA_AnnualAllowanceDays__c` (type: Number, length: 3, decimal places: 0, required: true) on `EPA_StudyLeaveAllowance__mdt` in the `fields/` subfolder.
3. Create a default Custom Metadata record `EPA_Default` with `EPA_AnnualAllowanceDays__c = 20` in `force-app/main/default/customMetadata/EPA_StudyLeaveAllowance.EPA_Default.md-meta.xml`.
4. Deploy to the scratch org (`sprint001`) using `sf project deploy start --target-org sprint001` and verify deployment succeeds.
5. Verify in the scratch org that the Custom Metadata Type is visible in Setup, the default record exists with a value of 20 days, and the value can be updated by a System Administrator.

### Risks or Blockers
- No risks or blockers identified. This is a straightforward declarative configuration with no dependencies on other stories or components. The implementation is entirely metadata-driven and requires no Apex, Flows, or UI components.

## Implementation Record

Agent: Developer Agent
Branch: feature/story003
PR: https://github.com/williamhowells238/Study-Leave/pull/3
Summary: Created Custom Metadata Type EPA_StudyLeaveAllowance__mdt with field EPA_AnnualAllowanceDays__c (Number, 3 digits, 0 decimals, required) and a default record EPA_Default with value 20. Deployed successfully to scratch org sprint001 and verified via SOQL query that the record exists with the correct value. No deviations from the solution plan were needed.

## PR Review - story-003: create annual study leave allowance configuration

Result: Approved

### Summary
- All four acceptance criteria are satisfied: the Custom Metadata Type `EPA_StudyLeaveAllowance__mdt` is created with field `EPA_AnnualAllowanceDays__c`, a default record `EPA_Default` is set to 20 days, the value is updatable by a System Administrator, and retrievable for validation/display.
- Naming conventions follow project standards (`EPA_` prefix, CamelCase, correct suffixes).
- Git conventions are correct: branch `feature/story003`, PR title `story-003: ...`, target branch `Dev1`.
- Implementation matches the solution plan exactly with no deviations.
- Metadata XML is well-formed: field type Number, precision 3, scale 0, required true.
- No Apex code is included so no code quality analysis was required — this is a purely declarative change.
- No high-severity issues identified.

### Changes to be made
- None. The implementation meets all acceptance criteria and project conventions.
