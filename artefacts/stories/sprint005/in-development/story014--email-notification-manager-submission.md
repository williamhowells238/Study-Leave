# Story 014 — Email Notification to Manager on Request Submission

## User Story

As a **Line Manager**, I want to receive an email notification when one of my direct-report apprentices submits a study leave request, so that I am promptly informed and can review the request in a timely manner.

## Acceptance Criteria

- Given an apprentice submits a new study leave request, when the request status is set to "Pending", then an email notification is sent to the apprentice's direct line manager (identified via the User hierarchy).
- Given the email notification is sent, when the manager opens the email, then it contains the following information: apprentice name, request start date, end date, leave category, calculated business days, and a link or reference to the request record.
- Given the email notification is configured, when the manager's email address is valid and active, then the email is delivered successfully to the manager's inbox.
- Given the email notification is sent, when the manager reads the email, then the subject line and body clearly identify it as a study leave request submission notification.

## Related Parent Epic

[Epic 003 — Approval Workflow and Notifications](../../../artefacts/epics/epic003--approval-workflow-and-notifications.md)

---

## Dependencies

- Dependency Type: Story
- Dependency on: Story 001
- Dependency Justification: The Study_Leave_Request__c object must exist with all fields so the email can include request details (dates, category, business days).

- Dependency Type: Story
- Dependency on: Story 005
- Dependency Justification: The User hierarchy must be configured to identify the manager's email address for notification delivery.

- Dependency Type: Story
- Dependency on: Story 013
- Dependency Justification: The approval process must be configured so that the email notification is triggered when a request enters "Pending" status as part of the submission/approval flow.

## Assumptions

- Assumption Type: Technical Confirmation
- Assumption Description: Email deliverability is configured in the Salesforce org (Setup → Email Deliverability set to "All Email") to allow outbound email notifications.
- Assumption Justification: Scratch orgs and sandboxes often have email deliverability restricted by default. This must be confirmed to ensure notifications are delivered during testing and in production.

- Assumption Type: Business Confirmation
- Assumption Description: The email template content and branding (subject line, body format) will follow a standard plain-text or simple HTML format without requiring custom branded templates.
- Assumption Justification: The acceptance criteria specify required content fields but do not mandate specific branding. If branded templates are required, additional design work is needed.

## Development Estimate

- Story Points: 2
- Justification: This is a simple story involving the creation of an email template containing apprentice name, request dates, leave category, calculated business days, and a link to the record, plus an email alert configured to fire when a request enters Pending status. The implementation leverages standard Salesforce Email Alert functionality triggered by the approval process (Story 013). The effort is largely declarative with minimal complexity. The only consideration is ensuring the email template correctly references all merge fields and the manager recipient is dynamically resolved via the User hierarchy.

## Testing Estimate

- Story Points: 2
- Justification: Testing involves verifying that an email is sent to the correct manager (resolved via the User hierarchy) when a study leave request is submitted, confirming the email content includes all required merge fields (apprentice name, start date, end date, leave category, calculated business days, record link), verifying the subject line clearly identifies the notification type, and confirming delivery to a valid email address. Testing requires email deliverability to be enabled in the org. The scenarios are straightforward with no complex edge cases.

## Solution Plan

### Salesforce Components
- **EPA_ManagerSubmissionNotification_EmailTemplate**
  - Component Type: Email Template (Text/Custom)
  - Purpose: Defines the subject line and body of the email sent to the line manager when an apprentice submits a study leave request. Includes merge fields for apprentice name, start date, end date, leave category, calculated business days, and a link to the request record.

- **EPA_ManagerSubmissionNotification_EmailAlert**
  - Component Type: Workflow Email Alert (on EPA_StudyLeaveRequest__c)
  - Purpose: Sends the email template to the manager (resolved via the User hierarchy Manager field on the submitting user). Referenced by the approval process as an initial submission action.

- **EPA_ManagerApproval_ApprovalProcess** (modify existing)
  - Component Type: Approval Process
  - Purpose: Add the email alert as an initial submission action so the manager is notified when the request enters "Pending" status and the approval process is triggered.

### Implementation Logic
1. Create the email template `EPA_ManagerSubmissionNotification_EmailTemplate` for the `EPA_StudyLeaveRequest__c` object with the following content:
   - Subject: `Study Leave Request Submitted — {!EPA_StudyLeaveRequest__c.Name}`
   - Body includes merge fields: `{!EPA_StudyLeaveRequest__c.EPA_Apprentice__c}` (apprentice name), `{!EPA_StudyLeaveRequest__c.EPA_StartDate__c}` (start date), `{!EPA_StudyLeaveRequest__c.EPA_EndDate__c}` (end date), `{!EPA_StudyLeaveRequest__c.EPA_Category__c}` (leave category), `{!EPA_StudyLeaveRequest__c.EPA_CalculatedBusinessDays__c}` (business days), and a link to the record.
2. Create the workflow email alert `EPA_ManagerSubmissionNotification_EmailAlert` on `EPA_StudyLeaveRequest__c`:
   - Template: `EPA_ManagerSubmissionNotification_EmailTemplate`
   - Recipient: The submitting user's manager (via User hierarchy — the approval process already resolves this).
3. Modify the existing approval process `EPA_ManagerApproval_ApprovalProcess` to add the email alert as an initial submission action (`initialSubmissionActions`).
4. Deploy all components to the `sprint005` scratch org using `sf project deploy start --target-org sprint005`.
5. Verify email deliverability is set to "All Email" in the scratch org.
6. Test by submitting a study leave request and confirming the manager receives the email with correct content.

### Risks or Blockers
- Email deliverability must be set to "All Email" in the scratch org for notifications to be delivered during testing. Scratch orgs default to "System Email Only" — this will need to be manually configured.
- The `EPA_Apprentice__c` field is a lookup to User. The merge field syntax for displaying the apprentice's name in the email template will need to reference the related User's Name field (e.g., `{!EPA_StudyLeaveRequest__c.EPA_Apprentice__r.Name}` or equivalent depending on template type).
- No custom code (Apex) is required — the solution is fully declarative using standard Salesforce email template, email alert, and approval process configuration.

## Implementation Record

Agent: Developer Agent
Branch: feature/014
PR: https://github.com/williamhowells238/Study-Leave/pull/15
Summary: Created a text email template (EPA_ManagerSubmissionNotification_EmailTemplate) in the EPA_StudyLeave folder containing apprentice name, start/end dates, leave category, calculated business days, and a record link. Modified the existing approval process (EPA_ManagerApproval_ApprovalProcess) to use this template via the emailTemplate property, which sends the notification to the assigned approver (manager via User hierarchy) on submission. Deviated from the solution plan by not creating a separate Workflow Email Alert, as Salesforce email alerts cannot resolve the manager dynamically without an Email-type field — the approval process built-in emailTemplate is the standard pattern for this use case.

## PR Review - story-014: email notification to manager on study leave request submission

Result: Approved

### Summary
- All four changed files reviewed: email template (.email + .email-meta.xml), email folder metadata, and approval process modification.
- Naming conventions follow the `EPA_CamelCaseName_Suffix` pattern defined in project conventions.
- Email template contains all merge fields required by the acceptance criteria: apprentice name, start date, end date, leave category, calculated business days, and a record link.
- Subject line clearly identifies the notification as a study leave request submission.
- The deviation from the solution plan (using the approval process `emailTemplate` property instead of a separate Workflow Email Alert) is architecturally sound. Salesforce Workflow Email Alerts require Email-type recipient fields, which cannot dynamically resolve the manager via the User hierarchy. The approval process `emailTemplate` property is the standard Salesforce pattern for sending notifications to the assigned approver on submission.
- The approval process change is minimal and clean — a single property addition with no impact on existing approval logic.
- No Apex code in scope — no governor limit, sharing model, or security concerns apply.
- Git conventions (branch naming, PR title, target branch) all comply with project standards.

### Changes to be made
- None. PR is approved as-is.
