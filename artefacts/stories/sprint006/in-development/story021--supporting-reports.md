# Story 021 — Supporting Reports for Dashboards

## User Story

As a **System Administrator**, I want Salesforce reports that underpin the manager dashboard and provide reusable data views, so that dashboards have accurate data sources and users can run reports independently for ad hoc analysis.

## Acceptance Criteria

- Given the Study Leave Request data model is in place, when the reports are created, then a custom report type is available that joins Study Leave Requests with User (Apprentice) data.
- Given the custom report type exists, when a report is built, then the following reports are available:
  - Study Leave Requests by Status (grouped by status, showing counts and total business days)
  - Study Leave Requests by Apprentice (grouped by apprentice, showing request counts and total approved days)
  - Study Leave Requests by Category (grouped by leave category, showing counts)
  - Pending Requests Awaiting Approval (filtered to Pending status only)
- Given a report is run by a manager, when the report results are displayed, then the data is scoped to the manager's direct-report apprentices only (respecting sharing rules).
- Given the reports exist, when they are used as source reports for the manager dashboard, then the dashboard components display data correctly.
- Given all reports use standard Salesforce functionality, when the reports are inspected, then they use standard or custom report types with no code dependencies.

## Related Parent Epic

[Epic 004 — Dashboards, Views, and Reporting](../../../artefacts/epics/epic004--dashboards-views-and-reporting.md)

---

## Dependencies

- Dependency Type: Story
- Dependency on: Story 001
- Dependency Justification: The Study_Leave_Request__c object must exist as the primary data source for all reports.

- Dependency Type: Story
- Dependency on: Story 002
- Dependency Justification: The Leave_Category__c object must exist for the "Study Leave Requests by Category" report.

- Dependency Type: Story
- Dependency on: Story 005
- Dependency Justification: The object relationships (Apprentice lookup to User) must be configured to create the custom report type joining Study Leave Requests with User data.

- Dependency Type: Story
- Dependency on: Story 026
- Dependency Justification: Record-level security and sharing rules must be in place so that report results are scoped correctly (managers see only direct reports' data).

## Assumptions

- Assumption Type: Technical Confirmation
- Assumption Description: A Custom Report Type must be created that joins Study_Leave_Request__c with User (via the Apprentice__c lookup) to enable reporting across both objects.
- Assumption Justification: Standard report types do not include custom object to User joins. A custom report type is required and must be created before the reports can be built.

- Assumption Type: Business Confirmation
- Assumption Description: The four reports listed in the acceptance criteria are the minimum required set. Additional ad hoc reports can be created by administrators as needed.
- Assumption Justification: Defining the report set upfront ensures the dashboard (Story 018) has all required source reports available.

## Development Estimate

- Story Points: 3
- Justification: This is a moderately complex story requiring the creation of a Custom Report Type (joining Study_Leave_Request__c with User via the Apprentice__c lookup) and four separate reports: by Status, by Apprentice, by Category, and Pending Requests awaiting approval. Each report requires appropriate groupings, summary fields, and filters. The Custom Report Type creation is straightforward but must be done before any reports can be built. Ensuring that reports respect the sharing model (managers see only direct reports' data) requires verification with the record-level security configuration. The overall effort is moderate due to the number of reports and the Custom Report Type prerequisite.

## Testing Estimate

- Story Points: 3
- Justification: Testing involves verifying the Custom Report Type is correctly configured (joining Study_Leave_Request__c with User via Apprentice__c), and then validating each of the four reports: requests by Status (correct groupings, counts, total business days), requests by Apprentice (correct groupings, request counts, total approved days), requests by Category (correct groupings, counts), and Pending Requests (filtered to Pending status only). Data scoping must be verified — a manager running a report should only see their direct reports' data per the sharing model. Report compatibility with the manager dashboard (Story 018) must also be confirmed. The four reports with distinct groupings and the sharing model verification warrant a 3-point estimate.

## Solution Plan

### Salesforce Components
- **EPA_StudyLeaveWithApprentice_ReportType**
  - Name: `EPA_StudyLeaveWithApprentice`
  - Component Type: Custom Report Type
  - Purpose: Joins `EPA_StudyLeaveRequest__c` (primary) with `User` (via `EPA_Apprentice__c` lookup) to enable reporting across study leave request data and apprentice user details. Also exposes the `EPA_LeaveCategory__c` relationship via `EPA_Category__c` lookup.

- **EPA_StudyLeaveByStatus_Report**
  - Name: `EPA_StudyLeaveByStatus`
  - Component Type: Report (Summary format)
  - Purpose: Groups study leave requests by `EPA_Status__c`. Displays record count and sum of `EPA_CalculatedBusinessDays__c` per status group.

- **EPA_StudyLeaveByApprentice_Report**
  - Name: `EPA_StudyLeaveByApprentice`
  - Component Type: Report (Summary format)
  - Purpose: Groups study leave requests by `EPA_Apprentice__c` (Apprentice full name). Displays record count and sum of `EPA_CalculatedBusinessDays__c` (total approved days) per apprentice. Filtered to Approved status for the "total approved days" summary.

- **EPA_StudyLeaveByCategory_Report**
  - Name: `EPA_StudyLeaveByCategory`
  - Component Type: Report (Summary format)
  - Purpose: Groups study leave requests by `EPA_Category__c` (Leave Category name). Displays record count per category.

- **EPA_PendingRequestsAwaitingApproval_Report**
  - Name: `EPA_PendingRequestsAwaitingApproval`
  - Component Type: Report (Tabular format)
  - Purpose: Filtered to `EPA_Status__c = 'Pending'` only. Shows apprentice name, start date, end date, category, and calculated business days for all pending requests.

- **EPA_StudyLeaveReports_ReportFolder**
  - Name: `EPA_StudyLeaveReports`
  - Component Type: Report Folder
  - Purpose: Organises all study leave reports in a dedicated folder for manager and admin access.

### Implementation Logic
1. Create the report folder `EPA_StudyLeaveReports` in `force-app/main/default/reports/` to house all study leave reports.
2. Create the Custom Report Type `EPA_StudyLeaveWithApprentice` in `force-app/main/default/reportTypes/`:
   - Primary object: `EPA_StudyLeaveRequest__c`.
   - Related object (B): `User` via `EPA_Apprentice__c` lookup (B record may or may not exist — outer join).
   - Expose fields: `EPA_Status__c`, `EPA_StartDate__c`, `EPA_EndDate__c`, `EPA_CalculatedBusinessDays__c`, `EPA_Category__c`, and relevant User fields (Full Name, Manager).
3. Create the `EPA_StudyLeaveByStatus` report in `force-app/main/default/reports/EPA_StudyLeaveReports/`:
   - Report type: `EPA_StudyLeaveWithApprentice`.
   - Format: Summary, grouped by `EPA_Status__c`.
   - Summary fields: Record Count, SUM of `EPA_CalculatedBusinessDays__c`.
4. Create the `EPA_StudyLeaveByApprentice` report:
   - Report type: `EPA_StudyLeaveWithApprentice`.
   - Format: Summary, grouped by `EPA_Apprentice__c` (Apprentice name).
   - Summary fields: Record Count, SUM of `EPA_CalculatedBusinessDays__c`.
5. Create the `EPA_StudyLeaveByCategory` report:
   - Report type: `EPA_StudyLeaveWithApprentice`.
   - Format: Summary, grouped by `EPA_Category__c` (Category name).
   - Summary fields: Record Count.
6. Create the `EPA_PendingRequestsAwaitingApproval` report:
   - Report type: `EPA_StudyLeaveWithApprentice`.
   - Format: Tabular.
   - Filter: `EPA_Status__c EQUALS Pending`.
   - Columns: Apprentice name, Start Date, End Date, Category, Calculated Business Days.
7. Deploy all metadata to the `sprint006` scratch org using `sf project deploy start --target-org sprint006`.
8. Verify each report renders correctly and the Custom Report Type is available in Report Builder.
9. Confirm sharing model scoping — run reports as a manager user to verify only direct-report data is visible.

### Risks or Blockers
- **Dependency on Story 026 (Sharing Rules):** The acceptance criteria require that report results are scoped to a manager's direct-report apprentices. If record-level sharing rules from Story 026 are not yet deployed to the scratch org, sharing-based scoping cannot be verified during development. Reports will be built to rely on standard Salesforce sharing enforcement (no code-based filtering), but full verification depends on Story 026 completion.
- **Custom Report Type with User object:** Salesforce Custom Report Types joining a custom object to the User object via a lookup require the lookup relationship to be correctly configured. The `EPA_Apprentice__c` lookup to `User` is confirmed in the existing metadata, so this is low risk.
- **Report metadata format:** Reports retrieved/deployed via Salesforce CLI may require the scratch org to have the report type deployed first. The deployment order must ensure the Custom Report Type is deployed before the reports that reference it.

## Implementation Record

Agent: Developer Agent
Branch: feature/021-v2
PR: https://github.com/williamhowells238/Study-Leave/pull/25
Summary: Created Custom Report Type (EPA_StudyLeaveWithApprentice) joining EPA_StudyLeaveRequest__c to User via EPA_Apprentice__c lookup, a report folder (EPA_StudyLeaveReports), and 4 reports: EPA_StudyLeaveByStatus (summary grouped by status), EPA_StudyLeaveByApprentice (summary grouped by apprentice), EPA_StudyLeaveByCategory (summary grouped by category), and EPA_PendingRequestsAwaitingApproval (tabular filtered to Pending status). All declarative — no Apex code. Deployed successfully to sprint006 scratch org; 27/28 Apex tests pass (1 pre-existing bulk failure unrelated to this story).

## PR Review - story-021: supporting reports for study leave data

Result: Rejected

### Summary
- All 6 metadata components (1 Custom Report Type, 1 Report Folder, 4 Reports) are present and follow the `EPA_` naming convention.
- Report Type correctly uses `EPA_StudyLeaveRequest__c` as the base object and exposes the required fields.
- EPA_StudyLeaveByStatus, EPA_StudyLeaveByCategory, and EPA_PendingRequestsAwaitingApproval reports are correctly implemented per the solution plan and acceptance criteria.
- Report folder sharing is set to AllInternalUsers with Manage access — appropriate for the use case.
- PR title and branch name follow project Git conventions.
- Two issues require changes before approval.

### Changes to be made
1. **Remove `scripts/temp_query_rt.apex` from the PR.** This is a temporary development/debug script (HTTP callout to the Reports API) that is not part of the solution deliverables. Remove it from the branch before re-submitting.
2. **Add a status filter to `EPA_StudyLeaveByApprentice` report.** The acceptance criteria specifies "total approved days per apprentice" and the solution plan states "Filtered to Approved status for the 'total approved days' summary." The current report has no filter on `EPA_Status__c`, so it sums business days across all statuses. Add a filter: `EPA_Status__c EQUALS Approved` to ensure the summary reflects only approved leave days.
