# Story 024 — Configure Object-Level Security

## User Story

As a **System Administrator**, I want object-level security configured on all custom objects so that each role has the appropriate Create, Read, Update, and Delete permissions, ensuring users can only interact with objects relevant to their function.

## Acceptance Criteria

- Given the Apprentice role, when object-level permissions are inspected, then apprentices have:
  - Study Leave Request: Create, Read, Edit (own records only — record-level handled separately)
  - Leave Category: Read only
  - Public Holiday: Read only
  - Study Leave Allowance: Read only
- Given the Line Manager role, when object-level permissions are inspected, then managers have:
  - Study Leave Request: Read (direct report records — record-level handled separately)
  - Leave Category: Read only
  - Public Holiday: Read only
  - Study Leave Allowance: Read only
- Given the System Administrator role, when object-level permissions are inspected, then administrators have:
  - Study Leave Request: Full CRUD (Create, Read, Update, Delete)
  - Leave Category: Full CRUD
  - Public Holiday: Full CRUD
  - Study Leave Allowance: Full CRUD
- Given object-level security is configured, when a user without the required permission attempts to access an object, then the system denies access.

## Related Parent Epic

[Epic 005 — Security and Access Control](../../../artefacts/epics/epic005--security-and-access-control.md)

---

## Dependencies

- Dependency Type: Story
- Dependency on: Story 001
- Dependency Justification: The Study_Leave_Request__c object must exist to configure CRUD permissions.

- Dependency Type: Story
- Dependency on: Story 002
- Dependency Justification: The Leave_Category__c object must exist to configure CRUD permissions.

- Dependency Type: Story
- Dependency on: Story 003
- Dependency Justification: The Study_Leave_Allowance__c configuration must exist to configure CRUD permissions.

- Dependency Type: Story
- Dependency on: Story 004
- Dependency Justification: The Public_Holiday__c object must exist to configure CRUD permissions.

- Dependency Type: Story
- Dependency on: Story 022
- Dependency Justification: User Profiles must be configured as the vehicle through which object-level permissions are granted.

- Dependency Type: Story
- Dependency on: Story 023
- Dependency Justification: Permission Sets must be created as an additional vehicle for granting object-level permissions beyond the profile baseline.

## Assumptions

- Assumption Type: Business Confirmation
- Assumption Description: The CRUD permission matrix per role (as defined in the acceptance criteria) is confirmed as the final specification.
- Assumption Justification: Object-level permissions are foundational to the security model. Changes to the CRUD matrix after implementation could require rework across profiles, permission sets, and testing.

- Assumption Type: Technical Confirmation
- Assumption Description: Object-level security will be configured on both Profiles and Permission Sets, with Profiles providing a restrictive baseline and Permission Sets granting additional access as needed.
- Assumption Justification: This is Salesforce best practice for security layering — restrictive profiles with additive permission sets.

## Development Estimate

- Story Points: 2
- Justification: This is a simple story involving the configuration of CRUD permissions on Profiles and Permission Sets for four custom objects across three roles. The CRUD matrix is clearly defined in the acceptance criteria, making the implementation straightforward. The work is entirely declarative — setting Create, Read, Update, and Delete checkboxes on each Profile and Permission Set for each object. The effort is low but methodical, requiring careful verification that each role has exactly the specified permissions.

## Testing Estimate

- Story Points: 3
- Justification: Testing requires verifying the full CRUD matrix across three roles and four custom objects (12 role-object combinations), with both positive testing (confirming permitted operations succeed) and negative testing (confirming denied operations are blocked). Specifically: apprentices can Create, Read, and Edit Study Leave Requests but only Read Leave Categories, Public Holidays, and Study Leave Allowance; managers can Read Study Leave Requests and Read the configuration objects; administrators have full CRUD on all objects. Each denied operation must be tested to confirm the system blocks access. The systematic nature of 12+ test scenarios with both positive and negative cases warrants a 3-point estimate.

## Solution Plan

### Salesforce Components

- **EPA Apprentice.profile-meta.xml**
  - Component Type: Profile
  - Purpose: Add Read-only object permissions for `EPA_PublicHoliday__c`. Confirm existing permissions on `EPA_StudyLeaveRequest__c` (Create, Read, Edit) and `EPA_LeaveCategory__c` (Read) are correct.

- **EPA Line Manager.profile-meta.xml**
  - Component Type: Profile
  - Purpose: Add Read-only object permissions for `EPA_PublicHoliday__c`. Confirm existing permissions on `EPA_StudyLeaveRequest__c` (Read) and `EPA_LeaveCategory__c` (Read) are correct.

- **EPA System Administrator.profile-meta.xml**
  - Component Type: Profile
  - Purpose: Add Full CRUD object permissions for `EPA_PublicHoliday__c` (already present — verify). No changes expected as existing permissions already cover Study Leave Request, Leave Category, and Public Holiday with full CRUD.

- **EPA_StudyLeaveApprentice_PermissionSet.permissionset-meta.xml**
  - Component Type: Permission Set
  - Purpose: Add Read-only object permissions for `EPA_PublicHoliday__c` and `EPA_StudyLeaveAllowance__mdt`. Confirm existing permissions on `EPA_StudyLeaveRequest__c` (Create, Read, Edit) and `EPA_LeaveCategory__c` (Read) are correct.

- **EPA_StudyLeaveManager_PermissionSet.permissionset-meta.xml**
  - Component Type: Permission Set
  - Purpose: Add Read-only object permissions for `EPA_PublicHoliday__c` and `EPA_StudyLeaveAllowance__mdt`. Confirm existing permissions on `EPA_StudyLeaveRequest__c` (Read) and `EPA_LeaveCategory__c` (Read) are correct.

- **EPA_StudyLeaveAdministrator_PermissionSet.permissionset-meta.xml**
  - Component Type: Permission Set
  - Purpose: No changes required — already has Full CRUD + ViewAll/ModifyAll on all four objects including `EPA_StudyLeaveAllowance__mdt`. Verify only.

### Implementation Logic

1. **Audit current state against acceptance criteria** — Map the CRUD matrix from the acceptance criteria against existing Profile and Permission Set XML files to confirm the gap analysis:
   - Apprentice Profile/PermSet: Missing Read on `EPA_PublicHoliday__c` and `EPA_StudyLeaveAllowance__mdt`.
   - Manager Profile/PermSet: Missing Read on `EPA_PublicHoliday__c` and `EPA_StudyLeaveAllowance__mdt`.
   - Admin Profile: Missing `EPA_StudyLeaveAllowance__mdt` (note: Custom Metadata Type permissions on profiles are limited — see Risks).
   - Admin PermSet: Already complete.

2. **Update EPA Apprentice Profile** — Add `objectPermissions` block for `EPA_PublicHoliday__c` with `allowRead=true` and all other CRUD flags set to `false`.

3. **Update EPA Line Manager Profile** — Add `objectPermissions` block for `EPA_PublicHoliday__c` with `allowRead=true` and all other CRUD flags set to `false`.

4. **Update EPA_StudyLeaveApprentice_PermissionSet** — Add two `objectPermissions` blocks:
   - `EPA_PublicHoliday__c` with `allowRead=true`, all others `false`.
   - `EPA_StudyLeaveAllowance__mdt` with `allowRead=true`, all others `false`.

5. **Update EPA_StudyLeaveManager_PermissionSet** — Add two `objectPermissions` blocks:
   - `EPA_PublicHoliday__c` with `allowRead=true`, all others `false`.
   - `EPA_StudyLeaveAllowance__mdt` with `allowRead=true`, all others `false`.

6. **Verify EPA System Administrator Profile** — Confirm existing Full CRUD on `EPA_StudyLeaveRequest__c`, `EPA_LeaveCategory__c`, and `EPA_PublicHoliday__c`. No changes needed for custom objects. CMDT permissions are handled via the Admin Permission Set.

7. **Verify EPA_StudyLeaveAdministrator_PermissionSet** — Confirm all four objects have Full CRUD + ViewAll/ModifyAll. No changes expected.

8. **Deploy to scratch org** — Push the updated metadata to the `sprint003` scratch org using `sf project deploy start`.

9. **Verify deployment** — Confirm successful deployment with no errors. Spot-check one Profile and one Permission Set in the org to validate the permissions are correctly applied.

### Risks or Blockers

- **Custom Metadata Type permissions on Profiles:** Salesforce Profiles have limited support for setting object permissions on Custom Metadata Types (`__mdt`). Read access to CMDT records is generally available to all authenticated users by default. Full CRUD on CMDTs requires the "Customize Application" system permission or Metadata API access, which is already handled through the Admin Permission Set. Therefore, `EPA_StudyLeaveAllowance__mdt` permissions will be configured on Permission Sets only, not on Profiles. This satisfies the acceptance criteria since Permission Sets are the primary vehicle for granting access (per Story 023 assumptions).
- **No blockers identified:** All dependency stories (001, 002, 003, 004, 022, 023) are complete. The four custom objects and three Permission Sets already exist in the codebase.

## Implementation Record

Agent: Developer Agent
Branch: feature/024
PR: https://github.com/williamhowells238/Study-Leave/pull/13
Summary: Audited existing Profile and Permission Set XML files against the acceptance criteria CRUD matrix. Identified four gaps: EPA_PublicHoliday__c Read access missing from Apprentice Profile, Line Manager Profile, Apprentice PermSet, and Manager PermSet; EPA_StudyLeaveAllowance__mdt Read access missing from Apprentice and Manager PermSets. Added the required objectPermissions blocks to all four files. Admin Profile and Admin PermSet were verified as already complete — no changes needed. Deployed successfully to sprint003 scratch org (Deploy ID: 0AfC300000BtrADKAZ, 7/7 components). All 21 Apex tests passed with 100% pass rate. No code quality scan required as changes are purely declarative XML metadata.

## PR Review - story-024: configure object-level security on profiles and permission sets

Result: Rejected

### Summary
- **Acceptance Criteria (CRUD Matrix)**: All four acceptance criteria are fully satisfied by the implementation. The CRUD matrix was verified against every Profile and Permission Set XML file:
  - **Apprentice** — Profile: Create/Read/Edit on `EPA_StudyLeaveRequest__c`, Read on `EPA_LeaveCategory__c`, Read on `EPA_PublicHoliday__c` (new). PermSet adds Read on `EPA_PublicHoliday__c` and `EPA_StudyLeaveAllowance__mdt` (new). Correct.
  - **Line Manager** — Profile: Read on `EPA_StudyLeaveRequest__c`, Read on `EPA_LeaveCategory__c`, Read on `EPA_PublicHoliday__c` (new). PermSet adds Read on `EPA_PublicHoliday__c` and `EPA_StudyLeaveAllowance__mdt` (new). Correct.
  - **System Administrator** — Profile: Full CRUD + ViewAll/ModifyAll on all three custom objects. PermSet: Full CRUD + ViewAll/ModifyAll on all four objects including `EPA_StudyLeaveAllowance__mdt`. No changes needed — verified as already complete. Correct.
- **CMDT Handling**: The decision to configure `EPA_StudyLeaveAllowance__mdt` permissions on Permission Sets only (not Profiles) is architecturally sound and well-documented in the solution plan risks section.
- **Naming Conventions**: All components follow the `EPA_CamelCaseName_Suffix` naming standard. Correct.
- **Git Conventions**: Branch `feature/024` targets `Dev1` with correct PR title format `story-024: ...`. Commit messages follow `story-[XXX]: short description`. Correct.
- **Solution Plan Alignment**: Implementation matches the solution plan exactly — four files modified, two verified with no changes needed.
- **Code Quality**: No code analysis required — changes are purely declarative XML metadata (objectPermissions blocks). Confirmed no Apex, LWC, or Flow changes in the PR.
- **Test Results**: All 21 Apex tests pass with 100% pass rate.
- **Blocking Issue**: The PR includes the accidental deletion of `artefacts/stories/sprint004/ready-for-test/story013--manager-approval-process.md`. This file was added to Dev1 in commit `e875b1a` and then deleted in the story-024 commit `f7d99c1`. Merging this PR would remove the story013 file from the repository. This is unrelated to story 024 and must be corrected before the PR can be approved.

### Changes to be made
1. **Restore story013 file** — The file `artefacts/stories/sprint004/ready-for-test/story013--manager-approval-process.md` was accidentally deleted in commit `f7d99c1`. Restore this file to its original state on the `feature/024` branch, commit, and push. The PR must only contain changes related to story 024.

## Fix Record

Agent: Developer Agent
Branch: feature/024
PR: https://github.com/williamhowells238/Study-Leave/pull/13
Summary: Restored the accidentally deleted file `artefacts/stories/sprint004/ready-for-test/story013--manager-approval-process.md` by checking it out from the Dev1 branch. The file was deleted in commit f7d99c1 alongside story-024 changes. No functional changes to the story-024 implementation were needed — the CRUD matrix configuration was confirmed correct by the Architect review.

## PR Re-Review - story-024: configure object-level security on profiles and permission sets

Result: Approved

### Summary
- **Fix Verified**: The previously deleted file `artefacts/stories/sprint004/ready-for-test/story013--manager-approval-process.md` is no longer removed by this PR. The PR diff now contains only 5 files — all scoped to story 024. The blocking issue from the prior review is resolved.
- **Acceptance Criteria (CRUD Matrix)**: Confirmed unchanged from previous review — all four acceptance criteria remain fully satisfied.
  - **Apprentice** — Profile: Create/Read/Edit on `EPA_StudyLeaveRequest__c`, Read on `EPA_LeaveCategory__c`, Read on `EPA_PublicHoliday__c`. PermSet adds Read on `EPA_PublicHoliday__c` and `EPA_StudyLeaveAllowance__mdt`. Correct.
  - **Line Manager** — Profile: Read on `EPA_StudyLeaveRequest__c`, Read on `EPA_LeaveCategory__c`, Read on `EPA_PublicHoliday__c`. PermSet adds Read on `EPA_PublicHoliday__c` and `EPA_StudyLeaveAllowance__mdt`. Correct.
  - **System Administrator** — Profile and PermSet already complete. No changes needed. Correct.
- **Code Quality**: No code analysis required — changes are purely declarative XML metadata.
- **Naming Conventions**: All components follow `EPA_CamelCaseName_Suffix` standard. Correct.
- **Git Conventions**: Branch `feature/024` targets `Dev1`, PR title follows `story-024: ...` format. Correct.
- **Solution Plan Alignment**: Implementation matches the solution plan exactly.

### Changes to be made
- None — PR is approved for merge.

## Test Results

Result: Passed
Tested By: QA Agent

### Acceptance Criteria Results

- AC1: Given the Apprentice role, when object-level permissions are inspected, then apprentices have correct CRUD access — **Pass**
  - Verification method: SOQL query on ObjectPermissions for EPA Apprentice Profile and Study Leave Apprentice Permission Set, plus source XML review for EPA_StudyLeaveAllowance__mdt.
  - Evidence:
    - EPA Apprentice Profile: EPA_StudyLeaveRequest__c — C=true, R=true, E=true, D=false ✓
    - EPA Apprentice Profile: EPA_LeaveCategory__c — C=false, R=true, E=false, D=false ✓
    - EPA Apprentice Profile: EPA_PublicHoliday__c — C=false, R=true, E=false, D=false ✓
    - Study Leave Apprentice PermSet: EPA_StudyLeaveRequest__c — C=true, R=true, E=true, D=false ✓
    - Study Leave Apprentice PermSet: EPA_LeaveCategory__c — C=false, R=true, E=false, D=false ✓
    - Study Leave Apprentice PermSet: EPA_PublicHoliday__c — C=false, R=true, E=false, D=false ✓
    - Study Leave Apprentice PermSet: EPA_StudyLeaveAllowance__mdt — allowRead=true, all others false ✓ (verified from permissionset XML)

- AC2: Given the Line Manager role, when object-level permissions are inspected, then managers have correct CRUD access — **Pass**
  - Verification method: SOQL query on ObjectPermissions for EPA Line Manager Profile and Study Leave Manager Permission Set, plus source XML review for EPA_StudyLeaveAllowance__mdt.
  - Evidence:
    - EPA Line Manager Profile: EPA_StudyLeaveRequest__c — C=false, R=true, E=false, D=false ✓
    - EPA Line Manager Profile: EPA_LeaveCategory__c — C=false, R=true, E=false, D=false ✓
    - EPA Line Manager Profile: EPA_PublicHoliday__c — C=false, R=true, E=false, D=false ✓
    - Study Leave Manager PermSet: EPA_StudyLeaveRequest__c — C=false, R=true, E=false, D=false ✓
    - Study Leave Manager PermSet: EPA_LeaveCategory__c — C=false, R=true, E=false, D=false ✓
    - Study Leave Manager PermSet: EPA_PublicHoliday__c — C=false, R=true, E=false, D=false ✓
    - Study Leave Manager PermSet: EPA_StudyLeaveAllowance__mdt — allowRead=true, all others false ✓ (verified from permissionset XML)

- AC3: Given the System Administrator role, when object-level permissions are inspected, then administrators have full CRUD — **Pass**
  - Verification method: SOQL query on ObjectPermissions for EPA System Administrator Profile and Study Leave Administrator Permission Set, plus source XML review for EPA_StudyLeaveAllowance__mdt.
  - Evidence:
    - EPA System Administrator Profile: EPA_StudyLeaveRequest__c — C=true, R=true, E=true, D=true ✓
    - EPA System Administrator Profile: EPA_LeaveCategory__c — C=true, R=true, E=true, D=true ✓
    - EPA System Administrator Profile: EPA_PublicHoliday__c — C=true, R=true, E=true, D=true ✓
    - Study Leave Administrator PermSet: EPA_StudyLeaveRequest__c — C=true, R=true, E=true, D=true ✓
    - Study Leave Administrator PermSet: EPA_LeaveCategory__c — C=true, R=true, E=true, D=true ✓
    - Study Leave Administrator PermSet: EPA_PublicHoliday__c — C=true, R=true, E=true, D=true ✓
    - Study Leave Administrator PermSet: EPA_StudyLeaveAllowance__mdt — Full CRUD + ViewAll/ModifyAll ✓ (verified from permissionset XML)

- AC4: Given object-level security is configured, when a user without the required permission attempts to access an object, then the system denies access — **Pass**
  - Verification method: SOQL query on ObjectPermissions filtered for any non-standard profiles/permission sets with elevated (Create/Edit/Delete) access to the four custom objects. Verified principle of least privilege.
  - Evidence:
    - No unexpected profiles or permission sets have Create, Edit, or Delete access to any of the four custom objects beyond the defined roles.
    - Apprentice: No Delete on any object ✓
    - Manager: No Create, Edit, or Delete on any object ✓
    - Only System Administrator has Delete access ✓
    - All permissions follow additive model: restrictive Profiles with additive Permission Sets ✓

### Summary
All tests passed. All four acceptance criteria verified through SOQL queries against the scratch org (sprint003) and source XML review. The CRUD matrix is correctly configured across all three roles (Apprentice, Line Manager, System Administrator) for all four custom objects (EPA_StudyLeaveRequest__c, EPA_LeaveCategory__c, EPA_PublicHoliday__c, EPA_StudyLeaveAllowance__mdt). The story is now completed.
