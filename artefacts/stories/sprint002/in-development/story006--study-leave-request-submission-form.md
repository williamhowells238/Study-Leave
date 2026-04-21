# Story 006 — Study Leave Request Submission Form

## User Story

As an **Apprentice**, I want a Salesforce Lightning Experience interface to create a new study leave request by selecting a start date, end date, and leave category, so that I can formally submit my study leave requests through the system.

## Acceptance Criteria

- Given an apprentice is logged into Salesforce Lightning Experience, when they navigate to the Study Leave Request area, then they see an option to create a new study leave request.
- Given the apprentice is on the new request form, when they view the form, then they can select a Start Date, an End Date, and a Leave Category from the available categories (Exam Prep, Classroom Training, Revision).
- Given the apprentice has filled in all required fields (Start Date, End Date, Category), when they submit the form, then a new Study Leave Request record is created with the apprentice automatically set as the requesting user AND the status is set to "Pending".
- Given the apprentice has not filled in all required fields, when they attempt to submit the form, then the form displays appropriate required-field error messages AND the record is not created.
- Given the form is submitted successfully, when the apprentice views the confirmation, then they can see the details of the submitted request including the calculated business days.

## Related Parent Epic

[Epic 002 — Study Leave Request Submission](../../../artefacts/epics/epic002--study-leave-request-submission.md)

---

## Dependencies

- Dependency Type: Story
- Dependency on: Story 001
- Dependency Justification: The Study_Leave_Request__c custom object and all its fields must exist before a submission form can create records.

- Dependency Type: Story
- Dependency on: Story 002
- Dependency Justification: The Leave_Category__c records must exist so that the form can present leave categories for selection.

- Dependency Type: Story
- Dependency on: Story 005
- Dependency Justification: Object relationships must be configured so that the Apprentice__c lookup is auto-populated with the current user and the Category__c lookup is functional.

- Dependency Type: Story
- Dependency on: Story 008
- Dependency Justification: The business day calculation must be in place so that the Calculated Business Days can be shown on the confirmation after submission.

## Assumptions

- Assumption Type: Technical Confirmation
- Assumption Description: The submission form will be implemented using a standard Salesforce Lightning Record Page with a Quick Action or custom Lightning Web Component (LWC), not a Visualforce page.
- Assumption Justification: The acceptance criteria specify "Salesforce Lightning Experience interface". A decision is needed on whether a standard Record Page with field configuration is sufficient or a custom LWC is required for the desired user experience.

- Assumption Type: Business Confirmation
- Assumption Description: On submission, the request status is set directly to "Pending" (skipping "Draft"), meaning there is no separate draft-save workflow.
- Assumption Justification: The acceptance criteria state the status is set to "Pending" on submission. If a draft-save feature is needed, additional UI and logic would be required.

## Development Estimate

- Story Points: 3
- Justification: This story involves building a Lightning Experience interface for study leave submission, which requires either a custom Lightning Record Page with a Quick Action or a Lightning Web Component. The form must auto-populate the Apprentice field with the current user, set the status to Pending on submission, enforce required field validation, and display a confirmation with calculated business days. The UI design, field configuration, and auto-population logic introduce moderate complexity. Multiple dependencies (Stories 001, 002, 005, 008) are involved but do not increase implementation effort for this story directly.

## Testing Estimate

- Story Points: 3
- Justification: Testing requires verifying the full submission workflow in the Lightning Experience UI: form rendering with correct fields, required field validation (testing both valid and missing field scenarios), auto-population of the Apprentice field with the current logged-in user, status set to Pending on submission, and confirmation display showing calculated business days. Integration testing with four dependencies (Stories 001, 002, 005, 008) adds scenarios to verify end-to-end data flow. Edge cases include submitting with missing fields, verifying the correct category options appear, and confirming the business day calculation displays correctly post-submission.

## Solution Plan

### Salesforce Components
- **EPA_StudyLeaveSubmission_Flow**
  - Component Type: Before-Save Record-Triggered Flow
  - Purpose: Automatically sets `EPA_Apprentice__c` to the running user (`$User.Id`) and `EPA_Status__c` to "Pending" when a new `EPA_StudyLeaveRequest__c` record is created. This ensures the apprentice is auto-populated and the status bypasses "Draft" on submission, satisfying AC3.

- **EPA_StudyLeaveRequest__c-Study Leave Request Layout**
  - Component Type: Page Layout
  - Purpose: Defines the field arrangement for the record creation form and record detail view. Displays `EPA_StartDate__c`, `EPA_EndDate__c`, and `EPA_Category__c` as required fields on the creation form. On the detail view, displays all fields including `EPA_CalculatedBusinessDays__c` for the post-submission confirmation (AC5). Hides `EPA_Apprentice__c` and `EPA_Status__c` from the creation form since these are auto-set by the Flow.

- **EPA_StudyLeaveRequest_FlexiPage**
  - Component Type: Lightning Record Page (FlexiPage)
  - Purpose: Custom Lightning Record Page for the `EPA_StudyLeaveRequest__c` object. Provides a clear confirmation view after submission showing all request details including Start Date, End Date, Category, Status (Pending), Apprentice, and Calculated Business Days (AC5). Assigned as the default record page for the object.

- **EPA_CategoryRequired_ValidationRule**
  - Component Type: Validation Rule on `EPA_StudyLeaveRequest__c`
  - Purpose: Prevents record creation when the `EPA_Category__c` lookup is blank. The lookup field itself is not required at the field level (`required=false`), so this validation rule enforces the AC2/AC4 requirement that Category is mandatory on submission and displays an appropriate error message.

### Implementation Logic
1. **Create the Validation Rule** — Add `EPA_CategoryRequired_ValidationRule` on `EPA_StudyLeaveRequest__c` with the condition `ISBLANK(EPA_Category__c)` and an error message displayed on the `EPA_Category__c` field. This, combined with the existing field-level required on `EPA_StartDate__c` and `EPA_EndDate__c`, satisfies AC4 (required field validation).
2. **Create the Before-Save Flow** — Build `EPA_StudyLeaveSubmission_Flow` as a Before-Save Record-Triggered Flow on `EPA_StudyLeaveRequest__c`, entry condition: `ISNEW()` (or record is created). Add two Assignment elements: set `EPA_Apprentice__c = {!$User.Id}` and set `EPA_Status__c = "Pending"`. No DML is needed as this is a before-save flow. This satisfies AC3.
3. **Create the Page Layout** — Define the `EPA_StudyLeaveRequest__c` page layout with the following sections:
   - **Request Details section**: `EPA_StartDate__c`, `EPA_EndDate__c`, `EPA_Category__c` (all required on layout).
   - **Record Information section**: `Name` (auto-number), `EPA_Apprentice__c` (read-only), `EPA_Status__c` (read-only), `EPA_CalculatedBusinessDays__c` (read-only).
   - Mark `EPA_Apprentice__c` and `EPA_Status__c` as read-only on the layout since they are auto-populated.
4. **Create the Lightning Record Page** — Build `EPA_StudyLeaveRequest_FlexiPage` using the standard Record Detail component and optionally a Highlights Panel showing key fields (Status, Calculated Business Days). Assign as the org default for `EPA_StudyLeaveRequest__c`. After submission, the user is redirected to this page showing the full confirmation (AC5).
5. **Verify the existing trigger** — The `EPA_BusinessDayCalculation_Trigger` (before insert, before update) already invokes `EPA_BusinessDayCalculation_Class.calculateBusinessDays()`, which will fire on the same transaction as the Flow. Confirm the order of execution: before-save Flow runs first (sets Apprentice and Status), then the before-save trigger runs (calculates business days). Both complete before the record is committed, so `EPA_CalculatedBusinessDays__c` will be populated on the saved record.
6. **Test end-to-end** — Navigate to the Study Leave Request tab, click New, fill in Start Date, End Date, and Category, and submit. Verify the record is created with Apprentice = current user, Status = Pending, and Calculated Business Days populated. Verify required field errors appear when fields are left blank.

### Risks or Blockers
- **Order of Execution**: Before-save Flows execute before before-save triggers in the Salesforce order of execution. This means the Flow will set Apprentice and Status before the trigger calculates business days. This is the correct order and poses no risk.
- **Assumption — Standard UI is sufficient**: The problem definition and clarifications (Q14) confirm that standard Salesforce Lightning Experience pages and components are the required approach (no custom LWC). The standard record creation modal and record page provide the submission form and confirmation view. If a more tailored UX is later required, this could be enhanced with a Screen Flow or LWC in a future story.
- **Assumption — No Draft state on submission**: The acceptance criteria explicitly state the status is set to "Pending" on submission, skipping "Draft". The Flow enforces this. The "Draft" picklist value remains available for potential future use but is not used in this workflow.
- **Category lookup field not required at field level**: The `EPA_Category__c` field is defined as `required=false` at the field level. A validation rule is needed to enforce this at submission time rather than changing the field definition, which could impact other automation.

## Implementation Record

Agent: Developer Agent
Branch: feature/story006
PR: https://github.com/williamhowells238/Study-Leave/pull/8
Summary: Implemented the study leave request submission form using four declarative components: a Before-save Record-Triggered Flow (EPA_StudyLeaveSubmission_Flow) to auto-set Apprentice and Status on creation, a Validation Rule (EPA_CategoryRequired_ValidationRule) to enforce Category as required, a Page Layout with Request Details and Record Information sections, and a Lightning Record Page (EPA_StudyLeaveRequest_FlexiPage) for the confirmation view. Updated EPA_BusinessDayCalculation_TestClass to include a test Leave Category in TestSetup and populate EPA_Category__c on all test records. Initial deployment required a fix to the FlexiPage (removed invalid relatedListComponentOverride property). All 12 Apex tests pass at 100% on scratch org sprint002.
