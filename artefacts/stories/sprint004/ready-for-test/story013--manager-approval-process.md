# Story 013 — Manager Approval Process with Status Transitions

## User Story

As a **Line Manager**, I want to be able to approve or reject study leave requests submitted by my direct-report apprentices through a structured approval process, so that I can manage my team's study leave in a timely and auditable manner.

## Acceptance Criteria

- Given an apprentice submits a study leave request, when the request is submitted, then the request status is automatically set to "Pending" AND the apprentice's direct line manager is identified via the standard User hierarchy (Manager field).
- Given a manager has a pending study leave request to review, when they view the request, then they can see the full request details including: apprentice name, Start Date, End Date, Leave Category, and Calculated Business Days.
- Given a manager is reviewing a pending request, when they choose to approve it, then the request status is updated to "Approved" AND the approved days are reflected in the apprentice's used allowance.
- Given a manager is reviewing a pending request, when they choose to reject it, then the request status is updated to "Rejected" AND the rejected days do not count against the apprentice's annual allowance.
- Given the approval process is configured, when a request is submitted, then only the apprentice's direct line manager (single-level) can approve or reject — no other users or escalation paths.
- Given a manager receives an approval request, when they take no action, then the request remains in "Pending" status indefinitely (no escalation or timeout).

## Related Parent Epic

[Epic 003 — Approval Workflow and Notifications](../../../artefacts/epics/epic003--approval-workflow-and-notifications.md)

---

## Dependencies

- Dependency Type: Story
- Dependency on: Story 001
- Dependency Justification: The Study_Leave_Request__c object with Status__c field must exist to support status transitions (Pending → Approved/Rejected).

- Dependency Type: Story
- Dependency on: Story 005
- Dependency Justification: The User hierarchy relationships must be configured so the system can identify the apprentice's direct line manager for approval routing.

- Dependency Type: Story
- Dependency on: Story 006
- Dependency Justification: The submission form must exist to set the request status to "Pending" and trigger the approval process.

## Assumptions

- Assumption Type: Business Confirmation
- Assumption Description: The approval process is single-level only (direct line manager). There is no escalation path, no timeout, and no multi-level or parallel approval.
- Assumption Justification: The acceptance criteria explicitly state single-level approval with no escalation or timeout. Business must confirm no additional approval levels are needed.

- Assumption Type: Technical Confirmation
- Assumption Description: The approval process will be implemented using Salesforce Standard Approval Processes (Setup → Approval Processes) rather than a custom Flow-based or Apex-based approval mechanism.
- Assumption Justification: Standard Approval Processes provide native approve/reject actions, email integration, and record locking. A technical decision is needed to confirm this approach meets the requirements.

- Assumption Type: Business Confirmation
- Assumption Description: A manager cannot partially approve a request (e.g. approve fewer days than requested). It is an all-or-nothing approve or reject decision.
- Assumption Justification: The acceptance criteria describe approve/reject as binary actions with no mention of partial approval. If partial approval is needed, the data model and UI would require changes.

## Development Estimate

- Story Points: 5
- Justification: This is a complex story involving the configuration of a Salesforce Standard Approval Process with entry criteria, approval steps, approver assignment (based on the User hierarchy Manager field), and final approval/rejection actions that update the Status field. The approval process must correctly identify the direct line manager, handle status transitions (Pending → Approved or Rejected), and ensure approved days are reflected in the apprentice's used allowance while rejected days are not. Configuration of record locking during approval, final action field updates, and thorough testing of the approval routing across different manager-apprentice relationships adds significant effort. Three dependencies must be in place before this can be fully tested.

## Testing Estimate

- Story Points: 5
- Justification: Testing the approval process requires verifying multiple scenarios: a request is correctly routed to the apprentice's direct line manager (not another manager), the manager can see full request details (apprentice name, dates, category, business days), approval updates the status to Approved and days count toward the used allowance, rejection updates the status to Rejected and days do not count toward the allowance, only the direct line manager can approve or reject (no other users), a request remains in Pending status indefinitely with no escalation or timeout, and record locking behaves correctly during the approval cycle. Testing across multiple manager-apprentice relationship pairs is needed to confirm routing accuracy. The combination of status transitions, approval routing, balance impact, and record-locking verification across three dependencies warrants a 5-point testing estimate.

## Solution Plan

### Salesforce Components

- **EPA_ManagerApproval_ApprovalProcess**
  - Component Type: Approval Process (on EPA_StudyLeaveRequest__c)
  - Purpose: Defines the single-level manager approval workflow. Entry criteria require EPA_Status__c = "Pending". Routes the approval request to the record submitter's manager (User.ManagerId via the standard User hierarchy). On final approval, a field update sets EPA_Status__c to "Approved". On final rejection, a field update sets EPA_Status__c to "Rejected". The record is locked while in the approval cycle. No escalation or timeout is configured — requests remain Pending indefinitely until the manager acts.

- **EPA_StatusApproved_FieldUpdate**
  - Component Type: Field Update (Approval Action)
  - Purpose: Final approval action that updates EPA_Status__c to "Approved" on the EPA_StudyLeaveRequest__c record when the manager approves the request.

- **EPA_StatusRejected_FieldUpdate**
  - Component Type: Field Update (Approval Action)
  - Purpose: Final rejection action that updates EPA_Status__c to "Rejected" on the EPA_StudyLeaveRequest__c record when the manager rejects the request.

- **EPA_ManagerApprovalSubmit_Flow**
  - Component Type: Record-Triggered Flow (After Save, on Create)
  - Purpose: Automatically submits newly created EPA_StudyLeaveRequest__c records for approval when the status is "Pending". This is required because the existing before-save flow (EPA_StudyLeaveSubmission_Flow) sets the status to "Pending" but cannot submit for approval in a before-save context. This after-save flow fires on record creation, checks that EPA_Status__c = "Pending", and uses the Submit for Approval action element to route the record into the approval process.

### Implementation Logic

1. **Create the Approval Process metadata** — Define `EPA_ManagerApproval_ApprovalProcess` on the EPA_StudyLeaveRequest__c object with entry criteria: `EPA_Status__c EQUALS "Pending"`. Set initial submitters to include the record creator. Enable record locking on submission.
2. **Configure the Approval Step** — Add a single approval step that routes to the submitter's manager (Manager field on the User object). Since the before-save flow sets `EPA_Apprentice__c` to `$User.Id`, the apprentice is always the submitter, so the submitter's manager is the correct approver. No escalation or timeout rules are configured.
3. **Create the Final Approval field update** — `EPA_StatusApproved_FieldUpdate` sets `EPA_Status__c` to "Approved". Attach as a final approval action on the approval process. No additional logic is needed for allowance tracking because the existing `EPA_AnnualAllowanceValidation_Class` already counts both "Approved" and "Pending" records toward the used allowance.
4. **Create the Final Rejection field update** — `EPA_StatusRejected_FieldUpdate` sets `EPA_Status__c` to "Rejected". Attach as a final rejection action. Rejected records are already excluded from allowance calculations by the existing validation class.
5. **Create the auto-submit flow** — Build `EPA_ManagerApprovalSubmit_Flow` as an after-save Record-Triggered Flow on EPA_StudyLeaveRequest__c, firing on record creation only. Entry condition: `EPA_Status__c = "Pending"`. The flow contains a single Submit for Approval action element targeting `$Record.Id`. Add a fault connector on the submit action to handle any submission errors gracefully.
6. **Activate the approval process** — Deploy and activate the approval process in the scratch org.
7. **Activate the auto-submit flow** — Deploy the flow as Active so that newly created requests are automatically submitted for approval.
8. **Verify automation density** — Confirm no conflicting automations on EPA_StudyLeaveRequest__c for the after-save create context. The existing `EPA_StudyLeaveSubmission_Flow` is a before-save flow so there is no conflict.

### Risks or Blockers

- **User hierarchy dependency**: The Manager field on User records must be populated for apprentice users in the scratch org (Story 005 dependency). If test users do not have the Manager field set, the approval routing will fail with no assigned approver.
- **Approval process metadata format**: Salesforce Approval Processes are retrievable via the Metadata API but must be carefully structured in source. The approval process, field updates, and approval step will be created directly in the scratch org and retrieved to source, or authored as metadata XML in the `approvalProcesses` directory.
- **Record locking**: While the record is locked in the approval cycle, the apprentice will not be able to edit or cancel the request. This is expected behaviour per the acceptance criteria but should be noted for downstream stories (Story 010 — Edit, Story 011 — Cancel) which may need to account for locked records.

## Implementation Record

Agent: Developer Agent
Branch: feature/013
PR: https://github.com/williamhowells238/Study-Leave/pull/12
Summary: Implemented all four solution plan components as Salesforce metadata XML. Created the EPA_ManagerApproval_ApprovalProcess (standard approval process with single-level manager routing via User hierarchy, entry criteria EPA_Status__c = Pending, record locking enabled), EPA_StatusApproved_FieldUpdate and EPA_StatusRejected_FieldUpdate (workflow field updates for final approval/rejection actions), and EPA_ManagerApprovalSubmit_Flow (after-save record-triggered flow on create that auto-submits records for approval when status is Pending, with fault handling). All components deployed successfully to the sprint003 scratch org. All 21 existing Apex tests pass with 94% org-wide coverage. No conflicting automations detected on EPA_StudyLeaveRequest__c.

## PR Review - story-013: Manager Approval Process with Status Transitions

Result: Approved

### Summary
- **Acceptance Criteria**: All 6 acceptance criteria are fully met by the implementation. The approval process correctly routes to the submitter's manager via the User hierarchy, displays all required fields on the approval page (apprentice name, dates, category, business days), performs status transitions to Approved/Rejected via field updates, enforces single-level approval with no delegation, and has no escalation or timeout configured.
- **Naming Conventions**: All four components follow the `EPA_CamelCaseName_Suffix` naming standard: `EPA_ManagerApproval_ApprovalProcess`, `EPA_StatusApproved_FieldUpdate`, `EPA_StatusRejected_FieldUpdate`, `EPA_ManagerApprovalSubmit_Flow`.
- **Git Conventions**: Branch `feature/013` targets `Dev1` with correct PR title format `story-013: ...`.
- **Solution Plan Alignment**: Implementation matches the solution plan exactly — 4 components delivered as specified.
- **Code Quality (Salesforce Code Analyzer)**: 5 low-severity violations found (all `MissingDescription` on flow elements). No high-severity issues. These are documentation best-practice recommendations and are non-blocking.
- **Architecture**: Approval process correctly locks records during approval (`recordEditability: AdminOnly`), unlocks on rejection (`finalRejectionRecordLock: false`), keeps locked on approval (`finalApprovalRecordLock: true`). The after-save flow includes a fault connector for error handling. No automation conflicts on the object.
- **Test Results**: All 21 Apex tests pass at 94% org-wide coverage.

### Changes to be made
- None required. The 5 low-severity MissingDescription findings on flow elements are informational and do not warrant rejection.
