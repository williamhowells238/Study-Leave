# Story 018 — Manager Dashboard for Study Leave Requests

## User Story

As a **Line Manager**, I want a Salesforce dashboard that consolidates all study leave requests from my direct-report apprentices with statuses and key metrics, so that I can monitor study leave usage and plan team capacity effectively.

## Acceptance Criteria

- Given a manager is logged into Salesforce Lightning Experience, when they navigate to the Study Leave Manager Dashboard, then the dashboard displays data scoped only to the manager's direct-report apprentices (not all apprentices in the organisation).
- Given the dashboard is displayed, when the manager reviews the dashboard, then it shows a breakdown of study leave requests by status (Pending, Approved, Rejected, Cancelled).
- Given the dashboard is displayed, when the manager reviews the metrics, then it shows key metrics including: total number of requests, total approved days, and number of pending requests.
- Given the dashboard uses standard Salesforce Lightning components, when the dashboard is rendered, then all charts, tables, and metrics use standard Salesforce dashboard components only.
- Given the underlying data changes (e.g. a new request is submitted or approved), when the manager refreshes the dashboard, then the updated data is reflected.

## Related Parent Epic

[Epic 004 — Dashboards, Views, and Reporting](../../../artefacts/epics/epic004--dashboards-views-and-reporting.md)

---

## Dependencies

- Dependency Type: Story
- Dependency on: Story 001
- Dependency Justification: The Study_Leave_Request__c object with all fields must exist as the data source for the dashboard.

- Dependency Type: Story
- Dependency on: Story 005
- Dependency Justification: The User hierarchy relationships must be configured to scope the dashboard data to the manager's direct-report apprentices.

- Dependency Type: Story
- Dependency on: Story 021
- Dependency Justification: The supporting reports must be created first, as Salesforce dashboards are built on top of source reports.

- Dependency Type: Story
- Dependency on: Story 026
- Dependency Justification: Record-level security (OWD, sharing rules) must be configured so that the dashboard respects the sharing model and only shows data for the manager's direct reports.

## Assumptions

- Assumption Type: Business Confirmation
- Assumption Description: The key metrics displayed on the dashboard (total requests, total approved days, pending requests count) are confirmed as the complete set of required metrics.
- Assumption Justification: Adding additional metrics after the dashboard is built may require new source reports and dashboard component reconfiguration.

- Assumption Type: Technical Confirmation
- Assumption Description: The dashboard will use standard Salesforce Dynamic Dashboards ("Run as logged-in user") so that each manager sees data scoped to their own direct reports without needing separate dashboards per manager.
- Assumption Justification: Dynamic dashboards respect the running user's sharing access, which is the expected behaviour. This requires confirmation that the org edition supports dynamic dashboards.

## Development Estimate

- Story Points: 5
- Justification: This is a complex story requiring the creation of a Salesforce Lightning Dashboard with multiple components (charts, tables, metrics) that display study leave data scoped to the logged-in manager's direct reports. The dashboard must be configured as a Dynamic Dashboard to leverage the running user's sharing access. Multiple source reports (from Story 021) are required to populate the status breakdown, total requests metric, total approved days metric, and pending requests count. The dependency on four other stories (001, 005, 021, 026) means this story can only be completed late in the delivery schedule. Ensuring the dashboard correctly scopes data via the sharing model and Dynamic Dashboard configuration, plus designing an informative layout with multiple components, warrants a 5-point estimate.

## Testing Estimate

- Story Points: 5
- Justification: Testing the manager dashboard requires verifying data scoping (a manager sees only their direct reports' requests, not all apprentices), metrics accuracy (total requests, total approved days, pending requests count match the underlying data), status breakdown correctness (Pending, Approved, Rejected, Cancelled counts), Dynamic Dashboard behaviour (running as the logged-in user), and refresh behaviour (updated data appears after dashboard refresh). Testing must be performed with multiple manager-apprentice hierarchies to confirm scoping works correctly. The four dependencies (Stories 001, 005, 021, 026) require extensive test data setup. The cross-dependency verification, multi-component layout testing, and scoping validation across different user contexts warrant a 5-point testing estimate.

---

## Solution Plan

### Salesforce Components

| Name | Component Type | Purpose |
|---|---|---|
| `EPA_ManagerDashboards` | Dashboard Folder | Container folder for manager-facing dashboards. Required to deploy the dashboard via SFDX metadata. |
| `EPA_ManagerStudyLeaveDashboard` | Dashboard (Lightning, Dynamic) | The primary manager dashboard. Configured as a Dynamic Dashboard (`dashboardType = LoggedInUser`) so that each manager's data is scoped to their own direct-report apprentices via the sharing model. Contains four components: a status breakdown chart, total requests metric, total approved days metric, and pending requests metric. |

**Source Reports (pre-existing from Story 021 — no changes required):**

| Name | Component Type | Purpose in Dashboard |
|---|---|---|
| `EPA_StudyLeaveByStatus` | Report (Summary) | Drives the status breakdown donut chart and the total requests metric. Grouped by `EPA_Status__c` with a grand total record count and sum of `EPA_CalculatedBusinessDays__c`. |
| `EPA_StudyLeaveByApprentice` | Report (Summary) | Drives the total approved days metric. Filtered to Approved records; sums `EPA_CalculatedBusinessDays__c`. |
| `EPA_PendingRequestsAwaitingApproval` | Report (Tabular) | Drives the pending requests count metric. Pre-filtered to Pending status; grand total record count provides the pending count. |

---

### Implementation Logic

1. **Create the Dashboard Folder metadata file** at `force-app/main/default/dashboards/EPA_ManagerDashboards-meta.xml`.  
   Set the folder name to `EPA_ManagerDashboards`, type `Dashboard`, access level `HideFromPublicListViews`, and share with the `Manager` role or equivalent permission set so that managers can access the dashboard.

2. **Create the Dashboard metadata directory** at `force-app/main/default/dashboards/EPA_ManagerDashboards/`.

3. **Create the Dashboard metadata file** at `force-app/main/default/dashboards/EPA_ManagerDashboards/EPA_ManagerStudyLeaveDashboard.dashboard-meta.xml`.

4. **Configure the Dashboard as a Dynamic Dashboard** by setting `<dashboardType>LoggedInUser</dashboardType>`. This ensures the dashboard runs as the logged-in user and respects the org sharing model, so each manager sees only their direct-report apprentices' data.

5. **Add Component 1 — Status Breakdown Donut Chart** using `EPA_StudyLeaveByStatus` as the source report.
   - Chart type: `Donut`
   - Measure: Record count grouped by `EPA_Status__c`
   - Title: "Requests by Status"

6. **Add Component 2 — Total Requests Metric** using `EPA_StudyLeaveByStatus` as the source report.
   - Component type: `Metric`
   - Measure: Grand total record count (all statuses)
   - Title: "Total Requests"

7. **Add Component 3 — Total Approved Days Metric** using `EPA_StudyLeaveByApprentice` as the source report.
   - Component type: `Metric`
   - Measure: Grand total sum of `EPA_CalculatedBusinessDays__c` (report is pre-filtered to Approved only)
   - Title: "Total Approved Days"

8. **Add Component 4 — Pending Requests Count Metric** using `EPA_PendingRequestsAwaitingApproval` as the source report.
   - Component type: `Metric`
   - Measure: Grand total record count (report is pre-filtered to Pending only)
   - Title: "Pending Requests"

9. **Deploy to the `sprint007` scratch org** using `sf project deploy start` and verify the dashboard is visible in the org under the `EPA_ManagerDashboards` folder.

10. **Verify Dynamic Dashboard scoping** by logging into the scratch org as a manager user and confirming that only direct-report apprentice records are shown on the dashboard.

---

### Risks or Blockers

- **Dynamic Dashboard edition limit**: Dynamic Dashboards require Enterprise Edition or above (or Developer Edition scratch orgs). The project scratch org definition should support this — no blocker expected, but confirm if deployment fails with an edition error.
- **Sharing model dependency**: The dashboard data scoping relies entirely on the sharing rules configured in Story 026. If those sharing rules are not deployed to the scratch org, the Dynamic Dashboard will not scope correctly. Ensure Story 026 metadata is present in the `sprint007` scratch org before testing.
- **No `dashboards` folder exists yet**: The `force-app/main/default/dashboards/` directory does not exist; it will be created as part of this story.
- **Source report folder path in dashboard metadata**: The dashboard XML must reference source reports by their developer name within the `EPA_StudyLeaveReports` folder. Verify developer names match the deployed report API names exactly.
- **Assumption — existing reports are sufficient**: The four components can be satisfied by the three existing source reports from Story 021. No new reports need to be created. If the acceptance criteria is later expanded, additional source reports may be needed.

## Implementation Record

Agent: Developer Agent
Branch: feature/018
PR: https://github.com/williamhowells238/Study-Leave/pull/26
Summary: Created the EPA_ManagerDashboards folder and EPA_ManagerStudyLeaveDashboard dynamic dashboard with four components (Donut chart for status breakdown, and three Metric components for total requests, total approved days, and pending requests count). Iteratively resolved five XML validation errors (invalid elements per component type: expandOtherItems, indicatorBreakpointValues, showPicturesOnCharts, chartAxisRange not valid for Metric; indicator colours required for Metric; autoselectColumnsFromReport mode). The sprint007 scratch org was freshly created so a full project deploy was required before deploying the dashboard. Deployment verified with SOQL query confirming the dashboard exists in org.

---

## PR Review - story-018: create EPA_ManagerStudyLeaveDashboard dynamic dashboard

Result: Rejected

### Summary

The PR correctly implements the Dynamic Dashboard with `dashboardType=LoggedInUser`, all four required components (Donut chart for status breakdown and three Metric components), correct source report references, and naming conventions that comply with project standards. However, two issues were identified that must be resolved before merge: (1) the `<runningUser>` element contains a scratch org alias rather than a valid Salesforce username — this will cause deployment failures in any subsequent org; and (2) the dashboard folder is shared with all internal users rather than the Manager role as specified in the solution plan, which is a security deviation.

### Changes to be made

1. **Fix `<runningUser>` in `EPA_ManagerStudyLeaveDashboard.dashboard-meta.xml`** — The `<runningUser>sprint007</runningUser>` element contains a scratch org alias, not a valid Salesforce username. Replace this value with a valid org user's username (e.g. the scratch org admin username such as `test-xyz@example.com`). For a `LoggedInUser` dynamic dashboard, the `<runningUser>` field still requires a valid username reference in the metadata. Using a CLI org alias will cause a deployment error when this metadata is deployed to any other org.

2. **Fix folder sharing in `EPA_ManagerDashboards-meta.xml`** — The `<sharedTo>` element uses `<allInternalUsers>true</allInternalUsers>`, sharing the folder with every user in the org including apprentices. The solution plan specifies the folder should be shared with the Manager role or equivalent permission set only. Update the `<sharedTo>` element to reference the appropriate role (e.g. `<role>Manager</role>`) or the Manager permission set so that apprentices cannot access the manager dashboard folder.

---

## Fix Record

Agent: Developer Agent
Branch: feature/018
PR: https://github.com/williamhowells238/Study-Leave/pull/26
Summary: Fixed two architect PR rejection issues. (1) Replaced `<runningUser>sprint007</runningUser>` with the actual scratch org admin username `test-plwtvmcy6ksf@example.com` in EPA_ManagerStudyLeaveDashboard.dashboard-meta.xml. (2) Replaced `<allInternalUsers>true</allInternalUsers>` folder sharing in EPA_ManagerDashboards-meta.xml with `<folderShares>` targeting the new `EPA_LineManager` custom role with `View` access — `PermissionSet` is not a valid FolderSharedToType for DashboardFolder in this org edition, so a custom UserRole (`EPA_LineManager`) was created and deployed. All three components (Dashboard, DashboardFolder, Role) deployed successfully to sprint007.
