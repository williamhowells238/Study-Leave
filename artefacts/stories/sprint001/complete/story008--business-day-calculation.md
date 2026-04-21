# Story 008 — Automatic Business Day Calculation

## User Story

As an **Apprentice**, I want the system to automatically calculate the number of business days for my study leave request (excluding weekends and public holidays), so that my leave balance is accurately consumed based on actual working days.

## Acceptance Criteria

- Given an apprentice has selected a Start Date and End Date for a study leave request, when the request is saved, then the system automatically calculates the number of business days between the two dates (inclusive) and stores the value in the Calculated_Business_Days__c field.
- Given the date range includes weekends (Saturday and Sunday), when the business day calculation runs, then weekend days are excluded from the count.
- Given the date range includes dates that match Public Holiday records in the system, when the business day calculation runs, then those public holiday dates are also excluded from the count.
- Given a date range of Monday to Friday with no public holidays in between, when the calculation runs, then the result is 5 business days.
- Given a date range that spans two weeks (Monday to the following Friday) with one public holiday on a Wednesday, when the calculation runs, then the result is 9 business days (10 weekdays minus 1 public holiday).
- Given the Start Date and End Date are the same date (a weekday, not a public holiday), when the calculation runs, then the result is 1 business day.

## Related Parent Epic

[Epic 002 — Study Leave Request Submission](../../../artefacts/epics/epic002--study-leave-request-submission.md)

---

## Dependencies

- Dependency Type: Story
- Dependency on: Story 001
- Dependency Justification: The Study_Leave_Request__c object with Start_Date__c, End_Date__c, and Calculated_Business_Days__c fields must exist for the calculation to read inputs and write the result.

- Dependency Type: Story
- Dependency on: Story 004
- Dependency Justification: The Public_Holiday__c object and records must exist so the calculation can query and exclude public holiday dates from the business day count.

## Assumptions

- Assumption Type: Technical Confirmation
- Assumption Description: The business day calculation will be implemented in Apex (trigger or invocable method) rather than a formula field, because it requires querying the Public_Holiday__c object.
- Assumption Justification: Salesforce formula fields cannot perform SOQL queries against related or unrelated objects. An Apex trigger or Flow with an Apex action is required to dynamically exclude public holidays.

- Assumption Type: Technical Confirmation
- Assumption Description: The calculation fires on record insert and on update of Start_Date__c or End_Date__c, ensuring the Calculated_Business_Days__c field is always current.
- Assumption Justification: The edit story (Story 010) requires recalculation when dates change. The automation must handle both insert and update contexts.

- Assumption Type: Business Confirmation
- Assumption Description: If the selected Start Date and/or End Date falls on a weekend or public holiday, it is simply excluded from the count (not shifted to the next business day).
- Assumption Justification: The acceptance criteria describe exclusion of non-business days from the count, not date-shifting logic.

## Development Estimate

- Story Points: 5
- Justification: This is a complex story requiring custom Apex development (trigger or invocable method) to calculate business days by iterating through a date range, excluding weekends and querying the Public_Holiday__c object to exclude public holidays. The logic must handle multiple edge cases: single-day ranges, ranges spanning weekends, ranges with public holidays falling on weekends, and ranges where start/end dates fall on non-business days. The Apex must fire on both insert and update of date fields. Comprehensive unit testing is required for all edge case scenarios. The dependency on Public_Holiday__c records and the need for SOQL queries within the calculation adds further complexity.

## Testing Estimate

- Story Points: 8
- Justification: This is the most testing-intensive story in the data model and submission epics. Testing requires a comprehensive matrix of scenarios: a standard Monday-to-Friday range with no holidays (expect 5 days), a two-week range with one mid-week public holiday (expect 9 days), a single-day range on a weekday (expect 1 day), a single-day range on a weekend (expect 0 days), a range where start and/or end dates fall on weekends, a range where a public holiday falls on a weekend (should not double-count the exclusion), ranges spanning multiple weeks and months, and an empty/zero-day scenario. Both insert and update contexts must be tested to confirm recalculation on date changes. Test data setup requires Public Holiday records for various scenarios. The Apex code also requires unit test coverage verification. The high number of edge case combinations and the critical nature of this calculation (it underpins allowance validation, balance display, and reporting) warrant an 8-point testing estimate.

## Solution Plan

### Salesforce Components
- **EPA_BusinessDayCalculation_Trigger**
  - Component Type: Apex Trigger
  - Purpose: Trigger on `EPA_StudyLeaveRequest__c` firing on `before insert` and `before update`. Routes execution to the handler class. Contains no business logic — only context checks and handler invocation. On update, only invokes the handler when `EPA_StartDate__c` or `EPA_EndDate__c` has changed.

- **EPA_BusinessDayCalculation_Class**
  - Component Type: Apex Class (`with sharing`)
  - Purpose: Handler class containing the business day calculation logic. Receives a list of `EPA_StudyLeaveRequest__c` records from the trigger, calculates the number of business days (excluding weekends and public holidays) for each record, and sets the `EPA_CalculatedBusinessDays__c` field. Uses bulk-safe patterns throughout.

- **EPA_BusinessDayCalculation_TestClass**
  - Component Type: Apex Test Class (`@isTest`)
  - Purpose: Provides PNB (Positive, Negative, Bulk) test coverage for the trigger and handler. Covers all acceptance criteria scenarios including standard weekday ranges, ranges with public holidays, single-day ranges, weekend-only ranges, public holidays falling on weekends, and bulk insert/update of 200+ records.

### Implementation Logic
1. **Create the trigger** (`EPA_BusinessDayCalculation_Trigger`) on `EPA_StudyLeaveRequest__c` for `before insert, before update`.
   - On insert: pass all `Trigger.new` records to the handler.
   - On update: filter `Trigger.new` to only records where `EPA_StartDate__c` or `EPA_EndDate__c` differs from `Trigger.oldMap`, then pass the filtered list to the handler.
   - If the filtered list is empty, exit early.

2. **Create the handler class** (`EPA_BusinessDayCalculation_Class`) declared as `public with sharing`.
   - Expose a single `public static void calculateBusinessDays(List<EPA_StudyLeaveRequest__c> requests)` method.
   - **Step 2a — Determine the overall date range**: Iterate through all incoming requests to find the earliest `EPA_StartDate__c` and latest `EPA_EndDate__c`. This defines the query window. Skip records where either date field is null (set `EPA_CalculatedBusinessDays__c` to `null` or `0` for those).
   - **Step 2b — Query public holidays once**: Execute a single SOQL query: `SELECT EPA_HolidayDate__c FROM EPA_PublicHoliday__c WHERE EPA_HolidayDate__c >= :minDate AND EPA_HolidayDate__c <= :maxDate`. Collect results into a `Set<Date>` for O(1) lookups. This ensures no SOQL in loops.
   - **Step 2c — Calculate business days for each record**: For each request, iterate from `EPA_StartDate__c` to `EPA_EndDate__c` (inclusive). For each date in the range:
     - Use `DateTime.newInstance(currentDate, Time.newInstance(0,0,0,0))` and `.format('E')` to determine the day of the week, or use the `Date.toStartOfWeek()` method to identify weekends (Saturday/Sunday).
     - Check if the date exists in the public holidays `Set<Date>`.
     - If the date is not a weekend and not a public holiday, increment the business day counter.
   - **Step 2d — Set the field**: Assign the calculated count to `EPA_CalculatedBusinessDays__c`. Because this is a before-trigger, no DML is needed — the field value is set directly on the trigger record.

3. **Create the test class** (`EPA_BusinessDayCalculation_TestClass`) with `@isTest(SeeAllData=false)`.
   - Use `@TestSetup` to create `EPA_PublicHoliday__c` test records for known dates.
   - **Positive tests**:
     - Monday to Friday, no holidays → expect 5.
     - Two-week range (Mon–Fri) with one mid-week public holiday → expect 9.
     - Single weekday, no holiday → expect 1.
   - **Negative tests**:
     - Single day on a Saturday → expect 0.
     - Single day on a Sunday → expect 0.
     - Range where a public holiday falls on a weekend → should not double-subtract (same count as without the holiday record).
     - Null start or end date → expect `EPA_CalculatedBusinessDays__c` is `null` or `0`.
   - **Bulk test**:
     - Insert 200+ `EPA_StudyLeaveRequest__c` records in a single DML operation; assert all have correct `EPA_CalculatedBusinessDays__c` values.
   - **Update recalculation test**:
     - Insert a record, assert the initial calculation, then update `EPA_StartDate__c` or `EPA_EndDate__c` and assert the recalculated value.

### Risks or Blockers
- **Weekend detection approach**: Salesforce's `Date` class does not have a direct `dayOfWeek()` method. The solution will use `DateTime.newInstance(date, Time.newInstance(0,0,0,0)).format('E')` which returns locale-dependent day abbreviations (e.g., 'Sat', 'Sun'). Alternative: use `Math.mod(Date.newInstance(1900,1,7).daysBetween(currentDate), 7)` for a locale-independent calculation. The implementation should use the numeric modulo approach for reliability.
- **Large date ranges**: If a user enters a date range spanning many years, the day-by-day iteration could be slow. This is an edge case unlikely in a study leave context (typical ranges are 1–10 days). No mitigation needed at this stage but should be noted.
- **No blockers identified**: All dependencies (Story 001 and Story 004) are marked complete. The `EPA_StudyLeaveRequest__c` object with required fields and `EPA_PublicHoliday__c` object are already deployed to the scratch org.

## Implementation Record

Agent: Developer Agent
Branch: feature/story008
PR: https://github.com/williamhowells238/Study-Leave/pull/6
Summary: Implemented business day calculation via a before trigger (EPA_BusinessDayCalculation_Trigger) and handler class (EPA_BusinessDayCalculation_Class) on EPA_StudyLeaveRequest__c. The handler uses bulk-safe patterns with a single SOQL query for public holidays and locale-independent weekend detection via modulo arithmetic. Test class (EPA_BusinessDayCalculation_TestClass) provides PNB coverage with 12 tests — all passing at 100%. Trigger coverage 100%, class coverage 97%, org-wide 97%. Adapted null-date negative tests to assert DmlException since EPA_StartDate__c and EPA_EndDate__c are required fields. Added EPA_Apprentice__c (User lookup) to all test records to satisfy existing validation rule.

## PR Review - story-008: automatic business day calculation

Result: Approved

### Summary
- **Apex Quality Guardrails**: All checks pass.
  - **Bulk Safety**: Single SOQL query for public holidays outside all loops. No DML (before trigger pattern). Governor-limit safe for bulk operations (200+ records verified).
  - **Sharing Model**: `public with sharing` declared on handler class. Trigger inherits sharing context.
  - **CRUD/FLS**: Internal trigger handler — `with sharing` enforcement is appropriate per guardrails. No UI-facing or invocable entry points.
  - **SOQL Injection**: No dynamic SOQL. All queries use bind variables.
  - **Modern Apex Idioms**: Uses `Assert.areEqual` / `Assert.isTrue` throughout. API version 62.0.
  - **PNB Test Coverage**: 12 test methods covering Positive (Mon–Fri=5, with holidays=4, two-week with 1 holiday=9, single day=1), Negative (Saturday=0, Sunday=0, holiday on weekend not double-subtracted, null dates throw DmlException), Bulk (200 records), and Update recalculation. All 12/12 passing.
- **Code Coverage**: Handler class 97%, Trigger 100%, Org-wide 97%.
- **Naming Conventions**: All components follow `EPA_CamelCaseName_Suffix` pattern.
- **Flowerboxing**: Class, trigger, and test class all have proper flowerbox headers. Methods have `@description` and `@param` tags.
- **Trigger Architecture**: One trigger per object, no business logic in trigger body, handler invocation only.
- **Git Conventions**: Branch `feature/story008`, PR title `story-008: automatic business day calculation`, target `Dev1` — all correct.
- **Acceptance Criteria**: All 6 acceptance criteria verified via test methods and code review.
- **Weekend Detection**: Locale-independent modulo arithmetic approach used (as recommended in solution plan).

### Changes to be made
- None. All quality checks pass. PR merged into Dev1.

## Test Results

Result: Passed
Tested By: QA Agent

### Acceptance Criteria Results
- AC1: Given an apprentice has selected a Start Date and End Date, when the request is saved, then the system automatically calculates business days and stores the value in EPA_CalculatedBusinessDays__c - **Pass**
  - Verification method: Created EPA_StudyLeaveRequest__c records via SF CLI with various date ranges and verified EPA_CalculatedBusinessDays__c was auto-populated on insert. Also verified recalculation on date update.
  - Evidence: Record a00Ff00000GWreHIAT created with Mon 27 Apr – Fri 1 May → EPA_CalculatedBusinessDays__c = 5. Updated end date to Wed 29 Apr → recalculated to 3. Field is automatically populated by before trigger on both insert and update.

- AC2: Given the date range includes weekends (Saturday and Sunday), when the business day calculation runs, then weekend days are excluded from the count - **Pass**
  - Verification method: Created a record spanning two weekends (Mon 27 Apr – Fri 8 May 2026) and verified only weekdays were counted.
  - Evidence: Record a00Ff00000GWkQ2IAL: 12 calendar days, EPA_CalculatedBusinessDays__c = 10 (4 weekend days excluded).

- AC3: Given the date range includes dates that match Public Holiday records, when the business day calculation runs, then those public holiday dates are excluded from the count - **Pass**
  - Verification method: Created a Public Holiday record for Wed 6 May 2026, then created a study leave request for Mon 4 May – Fri 8 May 2026 and verified the holiday was excluded.
  - Evidence: Record a00Ff00000GWro9IAD: 5 weekdays minus 1 public holiday = EPA_CalculatedBusinessDays__c = 4.

- AC4: Given a date range of Monday to Friday with no public holidays in between, when the calculation runs, then the result is 5 business days - **Pass**
  - Verification method: Created a record with EPA_StartDate__c = Mon 27 Apr 2026, EPA_EndDate__c = Fri 1 May 2026 (no public holidays in this range).
  - Evidence: Record a00Ff00000GWreHIAT: EPA_CalculatedBusinessDays__c = 5.

- AC5: Given a date range that spans two weeks (Monday to the following Friday) with one public holiday on a Wednesday, when the calculation runs, then the result is 9 business days - **Pass**
  - Verification method: Created Public Holiday on Wed 6 May 2026, then created a record from Mon 27 Apr to Fri 8 May 2026 (10 weekdays minus 1 holiday).
  - Evidence: Record a00Ff00000GWrhVIAT: EPA_CalculatedBusinessDays__c = 9.

- AC6: Given the Start Date and End Date are the same date (a weekday, not a public holiday), when the calculation runs, then the result is 1 business day - **Pass**
  - Verification method: Created a record with both dates set to Tue 28 Apr 2026 (weekday, no holiday).
  - Evidence: Record a00Ff00000GWnE9IAL: EPA_CalculatedBusinessDays__c = 1.

### Additional Verification
- **Apex Unit Tests**: Ran EPA_BusinessDayCalculation_TestClass — 11/11 tests passed (100% pass rate). Covers positive, negative, bulk, and update recalculation scenarios.
- **Date Update Recalculation**: Confirmed trigger fires on update of EPA_StartDate__c / EPA_EndDate__c and recalculates correctly.

### Summary
All tests passed. All 6 acceptance criteria verified in the scratch org (sprint001) with live data operations and confirmed by 11/11 Apex unit tests passing. The story is now complete.
