# Story 001 — Create Study Leave Request Custom Object

## User Story

As a **System Administrator**, I want a custom object to store Study Leave Requests with all required fields, so that the application has a structured place to capture and manage apprentice study leave data.

## Acceptance Criteria

- Given the Salesforce Scratch Org has no pre-existing Study Leave Request object, when the System Administrator deploys the data model, then a custom object named "Study_Leave_Request__c" is created.
- Given the Study Leave Request object is created, when the object is inspected, then it contains the following fields:
  - Start_Date__c (Date, required)
  - End_Date__c (Date, required)
  - Calculated_Business_Days__c (Number, read-only/formula or populated by automation)
  - Status__c (Picklist with values: Draft, Pending, Approved, Rejected, Cancelled)
  - Category__c (Lookup or Picklist — linked to Leave Category)
  - Apprentice__c (Lookup to User object, required)
- Given the object and fields are created, when a System Administrator creates a test record, then the record is saved successfully with all field values populated.
- Given the Status__c field exists, when a new record is created, then the default status value is "Draft".

## Related Parent Epic

[Epic 001 — Data Model and Configuration](../../../artefacts/epics/epic001--data-model-and-configuration.md)

---

## Dependencies

- No story dependencies. This is a foundational story that must be completed before any other stories can proceed.

## Assumptions

- Assumption Type: Business Confirmation
- Assumption Description: The Status picklist values (Draft, Pending, Approved, Rejected, Cancelled) are confirmed as the complete and final set of statuses required.
- Assumption Justification: The status values drive the approval workflow, notifications, and reporting logic across multiple epics. Any changes to these values would have a cascading impact.

- Assumption Type: Technical Confirmation
- Assumption Description: The Calculated_Business_Days__c field will be populated by automation (Apex trigger or Flow) rather than a formula field, as formula fields cannot query related Public Holiday records.
- Assumption Justification: The business day calculation requires querying the Public_Holiday__c object to exclude public holidays, which cannot be achieved with a standard formula field.

- Assumption Type: Business Confirmation
- Assumption Description: The Category__c field on the Study Leave Request object will be implemented as a Lookup relationship to the Leave_Category__c object (not a Picklist).
- Assumption Justification: A Lookup relationship allows categories to be maintained as records by administrators without requiring metadata deployments to add or modify picklist values.

## Development Estimate

- Story Points: 3
- Justification: This is a foundational story involving the creation of a custom object with multiple field types (Date, Number, Picklist, Lookup). While custom object creation is largely declarative, the moderately complex field configuration — including a read-only Calculated_Business_Days__c field that requires automation to populate, a Status picklist with a specific default value, and a Lookup to both User and Leave Category — introduces enough scope and edge cases to warrant a 3-point estimate. No Apex is written in this story, but careful field configuration and validation of default values and field properties is required.

## Testing Estimate

- Story Points: 2
- Justification: Testing involves verifying the custom object creation, confirming all field types and properties are correct (Date, Number, Picklist, Lookup), validating that the Status__c picklist contains all five values (Draft, Pending, Approved, Rejected, Cancelled), confirming the default status value is "Draft" on new record creation, and ensuring required fields enforce correctly. While the testing is largely declarative verification, the number of fields and field property checks (required constraints, read-only behaviour of Calculated_Business_Days__c, lookup targets) require systematic validation across multiple test scenarios.

## Solution Plan

### Salesforce Components
- **EPA_StudyLeaveRequest__c**
  - Component Type: Custom Object
  - Purpose: Core custom object to store all apprentice study leave request records. Acts as the foundational data entity for the entire application.

- **EPA_StartDate__c**
  - Component Type: Custom Field (Date, Required)
  - Purpose: Captures the start date of the study leave request.

- **EPA_EndDate__c**
  - Component Type: Custom Field (Date, Required)
  - Purpose: Captures the end date of the study leave request.

- **EPA_CalculatedBusinessDays__c**
  - Component Type: Custom Field (Number(3,0))
  - Purpose: Stores the calculated number of business days for the leave period (excluding weekends and public holidays). This field is not editable by users; it will be populated by automation in Story 008.

- **EPA_Status__c**
  - Component Type: Custom Field (Picklist)
  - Purpose: Tracks the lifecycle status of the leave request. Values: Draft, Pending, Approved, Rejected, Cancelled. Default value: Draft.

- **EPA_Apprentice__c**
  - Component Type: Custom Field (Lookup to User, Required)
  - Purpose: Links the study leave request to the apprentice (User record) who submitted it.

### Implementation Logic
1. Create the custom object metadata directory at `force-app/main/default/objects/EPA_StudyLeaveRequest__c/` with the object definition XML (`EPA_StudyLeaveRequest__c.object-meta.xml`).
2. Configure the object with label "Study Leave Request", plural label "Study Leave Requests", and a suitable Name field (Auto Number format: SLR-{0000}).
3. Create the `EPA_StartDate__c` field metadata XML as a Date field with `required=true`.
4. Create the `EPA_EndDate__c` field metadata XML as a Date field with `required=true`.
5. Create the `EPA_CalculatedBusinessDays__c` field metadata XML as a Number(3,0) field. Leave it non-required as it will be populated by automation (Story 008).
6. Create the `EPA_Status__c` field metadata XML as a Picklist with values: Draft, Pending, Approved, Rejected, Cancelled. Set the default value to "Draft".
7. Create the `EPA_Apprentice__c` field metadata XML as a Lookup to the standard User object with `required=true`. Configure the relationship label as "Study Leave Requests".
8. Deploy the object and fields to the scratch org (`sprint001`) using `sf project deploy start`.
9. Verify the deployment by creating a test record in the scratch org to confirm all fields save correctly and the default Status value is "Draft".

### Risks or Blockers
- **Category__c field excluded from this story**: The acceptance criteria lists a Category__c lookup to Leave_Category__c. However, the Leave_Category__c target object does not exist until Story 002 is completed. Story 005 (Object Relationships and Lookups) explicitly depends on both Story 001 and Story 002 and is responsible for configuring this relationship. The Category__c lookup field will be created as part of Story 005.
- **Naming convention deviation**: The acceptance criteria references `Study_Leave_Request__c` as the object API name, but the project conventions require an `EPA_` prefix (`EPA_StudyLeaveRequest__c`). The solution follows the project conventions. All field API names also follow the `EPA_CamelCaseName__c` convention.
- **Calculated_Business_Days__c will have no automation in this story**: The field is created as a placeholder. The automation to populate it is delivered in Story 008 (Business Day Calculation).

## Implementation Record

Agent: Developer Agent
Branch: feature/story001
PR: https://github.com/williamhowells238/Study-Leave/pull/new/feature/story001
Summary: Created the EPA_StudyLeaveRequest__c custom object with Auto Number name field (SLR-{0000}) and five custom fields: EPA_StartDate__c (Date, required), EPA_EndDate__c (Date, required), EPA_CalculatedBusinessDays__c (Number(3,0), placeholder for Story 008 automation), EPA_Status__c (Picklist: Draft/Pending/Approved/Rejected/Cancelled, default Draft), and EPA_Apprentice__c (Lookup to User). Added Admin profile FLS for non-required fields. Deployed successfully to scratch org sprint001 and verified with a test record confirming all fields save correctly and Status defaults to "Draft". EPA_Apprentice__c was set to non-required at metadata level because Salesforce does not support required + deleteConstraint on User lookups. PR creation was blocked by GitHub authentication (Enterprise Managed User) — PR needs to be created manually via the GitHub URL.
