# Story 016 — Email Notification to Apprentice on Approval or Rejection

## User Story

As an **Apprentice**, I want to receive an email notification when my study leave request is approved or rejected by my manager, so that I am informed of the decision without having to manually check the system.

## Acceptance Criteria

- Given a manager approves a study leave request, when the request status changes to "Approved", then an email notification is sent to the apprentice who submitted the request.
- Given a manager rejects a study leave request, when the request status changes to "Rejected", then an email notification is sent to the apprentice who submitted the request.
- Given an approval email is sent, when the apprentice opens the email, then it clearly states the request has been approved AND contains the request details: start date, end date, leave category, and calculated business days.
- Given a rejection email is sent, when the apprentice opens the email, then it clearly states the request has been rejected AND contains the request details: start date, end date, leave category, and calculated business days.
- Given the email notifications are configured, when the apprentice's email address is valid and active, then the emails are delivered successfully.

## Related Parent Epic

[Epic 003 — Approval Workflow and Notifications](../../../artefacts/epics/epic003--approval-workflow-and-notifications.md)

---

## Dependencies

- Dependency Type: Story
- Dependency on: Story 001
- Dependency Justification: The Study_Leave_Request__c object must exist with all fields so the email can include request details.

- Dependency Type: Story
- Dependency on: Story 013
- Dependency Justification: The manager approval process must be configured with status transitions to "Approved" and "Rejected" so the email notification can be triggered on these status changes.

## Assumptions

- Assumption Type: Technical Confirmation
- Assumption Description: Email deliverability is configured in the Salesforce org to allow outbound email notifications to apprentices.
- Assumption Justification: Same as Story 014 — scratch orgs and sandboxes may have restricted email deliverability that must be enabled.

- Assumption Type: Business Confirmation
- Assumption Description: Separate email templates are required for approval and rejection notifications (not a single template with conditional content).
- Assumption Justification: The acceptance criteria describe distinct content for approval and rejection emails. Business must confirm whether two separate templates or one conditional template is preferred.

## Development Estimate

- Story Points: 2
- Justification: This is a simple story similar in nature to Story 014, but requiring two email templates (one for approval, one for rejection) and two corresponding email alerts triggered by the approval process final actions (Approve and Reject). The implementation is declarative using standard Salesforce Email Alerts on the approval process. Each template must include request details (dates, category, business days) and a clear indication of the decision. The effort is straightforward with no custom code required.

## Testing Estimate

- Story Points: 2
- Justification: Testing involves verifying two separate email notifications: one sent on approval (status change to Approved) and one on rejection (status change to Rejected). For each, the email must be delivered to the apprentice, the content must clearly state the decision (approved or rejected), and all request details (start date, end date, leave category, calculated business days) must be present and accurate. Testing requires triggering both the approve and reject paths of the approval process and verifying the distinct email content for each. The scenarios are well-defined and straightforward.

## Solution Plan

### Salesforce Components
- **EPA_ApprenticeApprovalNotification_EmailTemplate**
  - Component Type: Email Template (Text)
  - Purpose: Notifies the apprentice that their study leave request has been approved. Includes request details: start date, end date, leave category, and calculated business days.

- **EPA_ApprenticeRejectionNotification_EmailTemplate**
  - Component Type: Email Template (Text)
  - Purpose: Notifies the apprentice that their study leave request has been rejected. Includes request details: start date, end date, leave category, and calculated business days.

- **EPA_ApprenticeApprovalNotification_EmailAlert**
  - Component Type: Workflow Email Alert
  - Purpose: Sends the approval email template to the record owner (the apprentice who submitted the request) when the approval process final approval action fires.

- **EPA_ApprenticeRejectionNotification_EmailAlert**
  - Component Type: Workflow Email Alert
  - Purpose: Sends the rejection email template to the record owner (the apprentice who submitted the request) when the approval process final rejection action fires.

- **EPA_ManagerApproval_ApprovalProcess** (modification)
  - Component Type: Approval Process
  - Purpose: Add the approval email alert to `finalApprovalActions` and the rejection email alert to `finalRejectionActions`, so the apprentice is notified on each decision.

### Implementation Logic
1. Create the approval email template `EPA_ApprenticeApprovalNotification_EmailTemplate` in the `EPA_StudyLeave` folder. Use text type, with subject line referencing the request name and body clearly stating approval with merge fields for start date, end date, leave category, and calculated business days.
2. Create the rejection email template `EPA_ApprenticeRejectionNotification_EmailTemplate` in the `EPA_StudyLeave` folder. Same structure as approval but clearly stating rejection.
3. Create the workflow email alert `EPA_ApprenticeApprovalNotification_EmailAlert` on `EPA_StudyLeaveRequest__c`. Set the recipient to the record owner (CreatedBy or OwnerId — the apprentice). Reference the approval email template.
4. Create the workflow email alert `EPA_ApprenticeRejectionNotification_EmailAlert` on `EPA_StudyLeaveRequest__c`. Set the recipient to the record owner. Reference the rejection email template.
5. Modify the approval process `EPA_ManagerApproval_ApprovalProcess` to add `EPA_ApprenticeApprovalNotification_EmailAlert` as an Alert action under `finalApprovalActions`.
6. Modify the approval process to add `EPA_ApprenticeRejectionNotification_EmailAlert` as an Alert action under `finalRejectionActions`.
7. Deploy all components to the `sprint005` scratch org and verify email delivery on both approve and reject paths.

### Risks or Blockers
- Email deliverability must be enabled in the scratch org (Access Level set to "All Email") for outbound emails to be sent. This is a known scratch org limitation and was also flagged in Story 014.
- The recipient is set to the record owner. This assumes the apprentice who submits the request is the record owner — this is consistent with the current approval process design where the submitter owns the record.

## Implementation Record

Agent: Developer Agent
Branch: feature/016
PR: https://github.com/williamhowells238/Study-Leave/pull/16
Summary: Created two text email templates (approval and rejection) in the EPA_StudyLeave folder with merge fields for request details. Created two corresponding workflow email alerts targeting the record owner. Modified the EPA_ManagerApproval_ApprovalProcess to add the approval email alert to finalApprovalActions and the rejection email alert to finalRejectionActions. All 9 components deployed successfully to the sprint005 scratch org and verified via SOQL query.
