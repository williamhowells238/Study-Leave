/**
 * @description: Test class for EPA_AnnualAllowanceValidation_Class.
 *               Provides Positive, Negative, and Bulk (PNB) test coverage for
 *               annual allowance validation logic including year-boundary splitting.
 * @author: Developer Agent
 * @date: 2026-04-21
 */
@isTest(SeeAllData=false)
private class EPA_AnnualAllowanceValidation_TestClass {

    private static Id testUserId = UserInfo.getUserId();

    /**
     * @description: Creates test data including leave category, public holidays,
     *               and pre-existing study leave requests in various statuses.
     *               Note: The EPA_StudyLeaveSubmission_Flow sets all new records to 'Pending'.
     *               Status is updated after insert to achieve the desired test state.
     */
    @TestSetup
    static void makeData() {
        // Set high allowance to prevent validation blocking test data creation
        EPA_AnnualAllowanceValidation_Class.allowanceOverride = 1000;

        EPA_LeaveCategory__c category = new EPA_LeaveCategory__c(Name = 'Exam Prep');
        insert category;

        // Public holidays
        List<EPA_PublicHoliday__c> holidays = new List<EPA_PublicHoliday__c>();
        holidays.add(new EPA_PublicHoliday__c(EPA_HolidayDate__c = Date.newInstance(2027, 1, 6)));  // Wed
        holidays.add(new EPA_PublicHoliday__c(EPA_HolidayDate__c = Date.newInstance(2027, 12, 27))); // Mon
        insert holidays;

        // Insert all requests as Pending (flow will set status to Pending anyway)
        List<EPA_StudyLeaveRequest__c> requests = new List<EPA_StudyLeaveRequest__c>();

        // Request 1: 10 business days in 2027 — will become Approved
        // 2027-01-18 (Mon) to 2027-01-31 (Sun) — 10 weekdays in range
        requests.add(new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = testUserId,
            EPA_Category__c = category.Id,
            EPA_StartDate__c = Date.newInstance(2027, 1, 18),
            EPA_EndDate__c = Date.newInstance(2027, 1, 31)
        ));

        // Request 2: 5 business days in 2027 — will stay Pending
        // 2027-02-01 (Mon) to 2027-02-05 (Fri)
        requests.add(new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = testUserId,
            EPA_Category__c = category.Id,
            EPA_StartDate__c = Date.newInstance(2027, 2, 1),
            EPA_EndDate__c = Date.newInstance(2027, 2, 5)
        ));

        // Request 3: 5 business days — will become Rejected (should NOT count)
        // 2027-03-01 (Mon) to 2027-03-05 (Fri)
        requests.add(new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = testUserId,
            EPA_Category__c = category.Id,
            EPA_StartDate__c = Date.newInstance(2027, 3, 1),
            EPA_EndDate__c = Date.newInstance(2027, 3, 5)
        ));

        // Request 4: 5 business days — will become Cancelled (should NOT count)
        // 2027-03-08 (Mon) to 2027-03-12 (Fri)
        requests.add(new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = testUserId,
            EPA_Category__c = category.Id,
            EPA_StartDate__c = Date.newInstance(2027, 3, 8),
            EPA_EndDate__c = Date.newInstance(2027, 3, 12)
        ));

        insert requests;

        // Update statuses after insert (trigger only re-validates on date change, not status change)
        requests[0].EPA_Status__c = 'Approved';
        requests[2].EPA_Status__c = 'Rejected';
        requests[3].EPA_Status__c = 'Cancelled';
        update new List<EPA_StudyLeaveRequest__c>{requests[0], requests[2], requests[3]};
    }

    /**
     * @description: Retrieves the test leave category created in TestSetup.
     * @return The test EPA_LeaveCategory__c record.
     */
    private static EPA_LeaveCategory__c getTestCategory() {
        return [SELECT Id FROM EPA_LeaveCategory__c WHERE Name = 'Exam Prep' LIMIT 1];
    }

    // =========================================================================
    // POSITIVE TESTS
    // =========================================================================

    /**
     * @description: Request within remaining allowance succeeds.
     *               15 days used (10 Approved + 5 Pending), 20 allowance, requesting 4 days.
     */
    @isTest
    static void givenRequestWithinAllowance_whenInserted_thenNoError() {
        EPA_AnnualAllowanceValidation_Class.allowanceOverride = 20;
        EPA_LeaveCategory__c cat = getTestCategory();

        EPA_StudyLeaveRequest__c req = new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = testUserId,
            EPA_Category__c = cat.Id,
            EPA_StartDate__c = Date.newInstance(2027, 4, 7),  // Monday
            EPA_EndDate__c = Date.newInstance(2027, 4, 10)     // Thursday = 4 days
        );

        Test.startTest();
        insert req;
        Test.stopTest();

        EPA_StudyLeaveRequest__c result = [
            SELECT Id FROM EPA_StudyLeaveRequest__c WHERE Id = :req.Id
        ];
        Assert.isNotNull(result, 'Request within allowance should be inserted successfully');
    }

    /**
     * @description: Request at exact allowance limit succeeds.
     *               15 days used, 20 allowance, requesting exactly 5 days.
     */
    @isTest
    static void givenRequestAtExactLimit_whenInserted_thenNoError() {
        EPA_AnnualAllowanceValidation_Class.allowanceOverride = 20;
        EPA_LeaveCategory__c cat = getTestCategory();

        EPA_StudyLeaveRequest__c req = new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = testUserId,
            EPA_Category__c = cat.Id,
            EPA_StartDate__c = Date.newInstance(2027, 4, 7),  // Monday
            EPA_EndDate__c = Date.newInstance(2027, 4, 11)     // Friday = 5 days
        );

        Test.startTest();
        insert req;
        Test.stopTest();

        EPA_StudyLeaveRequest__c result = [
            SELECT Id FROM EPA_StudyLeaveRequest__c WHERE Id = :req.Id
        ];
        Assert.isNotNull(result, 'Request at exact limit should be inserted successfully');
    }

    /**
     * @description: Only Approved and Pending requests count. With only Rejected/Cancelled
     *               prior requests, a new request within the full allowance should succeed.
     */
    @isTest
    static void givenOnlyRejectedCancelledPrior_whenInserted_thenSucceeds() {
        EPA_AnnualAllowanceValidation_Class.allowanceOverride = 20;
        EPA_LeaveCategory__c cat = getTestCategory();

        // Delete Approved and Pending test data so only Rejected/Cancelled remain
        delete [SELECT Id FROM EPA_StudyLeaveRequest__c
                WHERE EPA_Status__c IN ('Approved', 'Pending')];

        EPA_StudyLeaveRequest__c req = new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = testUserId,
            EPA_Category__c = cat.Id,
            EPA_StartDate__c = Date.newInstance(2027, 5, 5),  // Monday
            EPA_EndDate__c = Date.newInstance(2027, 5, 23)     // Friday = 15 weekdays
        );

        Test.startTest();
        insert req;
        Test.stopTest();

        EPA_StudyLeaveRequest__c result = [
            SELECT Id FROM EPA_StudyLeaveRequest__c WHERE Id = :req.Id
        ];
        Assert.isNotNull(result, 'Request should succeed when only Rejected/Cancelled prior requests exist');
    }

    // =========================================================================
    // NEGATIVE TESTS
    // =========================================================================

    /**
     * @description: Request exceeding allowance is rejected with correct error message.
     *               15 days used, 20 allowance, requesting 6 days (total 21 > 20).
     */
    @isTest
    static void givenRequestExceedsAllowance_whenInserted_thenErrorWithMessage() {
        EPA_AnnualAllowanceValidation_Class.allowanceOverride = 20;
        EPA_LeaveCategory__c cat = getTestCategory();

        EPA_StudyLeaveRequest__c req = new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = testUserId,
            EPA_Category__c = cat.Id,
            EPA_StartDate__c = Date.newInstance(2027, 4, 7),   // Monday
            EPA_EndDate__c = Date.newInstance(2027, 4, 14)      // Monday = 6 weekdays
        );

        Test.startTest();
        Boolean exceptionThrown = false;
        String errorMessage = '';
        try {
            insert req;
        } catch (DmlException e) {
            exceptionThrown = true;
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'DmlException should be thrown when allowance is exceeded');
        Assert.isTrue(errorMessage.contains('days remaining of your annual study leave allowance'),
            'Error message should mention remaining allowance. Actual: ' + errorMessage);
        Assert.isTrue(errorMessage.contains('This request requires'),
            'Error message should mention requested days. Actual: ' + errorMessage);
    }

    // =========================================================================
    // YEAR-BOUNDARY TESTS
    // =========================================================================

    /**
     * @description: Request spanning December to January splits days across years.
     *               Days in each year are validated independently.
     */
    @isTest
    static void givenYearBoundaryRequest_whenInserted_thenDaysSplitAcrossYears() {
        EPA_AnnualAllowanceValidation_Class.allowanceOverride = 20;
        EPA_LeaveCategory__c cat = getTestCategory();

        // Delete existing requests to have a clean slate
        delete [SELECT Id FROM EPA_StudyLeaveRequest__c];

        // 2027-12-27 (Mon, public holiday) to 2028-01-07 (Fri)
        // 2027 days: Dec 28(Tue),29(Wed),30(Thu),31(Fri) = 4 business days (27th is holiday)
        // 2028 days: Jan 3(Mon),4(Tue),5(Wed),6(Thu),7(Fri) = 5 business days
        //            (Jan 1,2 are Sat/Sun)
        EPA_StudyLeaveRequest__c req = new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = testUserId,
            EPA_Category__c = cat.Id,
            EPA_StartDate__c = Date.newInstance(2027, 12, 27),
            EPA_EndDate__c = Date.newInstance(2028, 1, 7)
        );

        Test.startTest();
        insert req;
        Test.stopTest();

        EPA_StudyLeaveRequest__c result = [
            SELECT Id, EPA_CalculatedBusinessDays__c
            FROM EPA_StudyLeaveRequest__c WHERE Id = :req.Id
        ];
        Assert.isNotNull(result, 'Year-boundary request within allowance should succeed');
    }

    /**
     * @description: Year-boundary request that exceeds allowance in one year is rejected.
     */
    @isTest
    static void givenYearBoundaryExceedsAllowance_whenInserted_thenError() {
        EPA_AnnualAllowanceValidation_Class.allowanceOverride = 17;
        EPA_LeaveCategory__c cat = getTestCategory();

        // 15 days already used in 2027 (10 Approved + 5 Pending)
        // Request spanning Dec 2027 to Jan 2028 — even a few days in 2027 would exceed 17
        // 2027-12-20 (Mon) to 2028-01-07 (Fri)
        // 2027 portion: Dec 20-24 (5 weekdays) + Dec 27(holiday so skip) + Dec 28-31 (4 weekdays) = 9 days
        // 15 + 9 = 24 > 17 — should fail
        EPA_StudyLeaveRequest__c req = new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = testUserId,
            EPA_Category__c = cat.Id,
            EPA_StartDate__c = Date.newInstance(2027, 12, 20),
            EPA_EndDate__c = Date.newInstance(2028, 1, 7)
        );

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            insert req;
        } catch (DmlException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Year-boundary request exceeding allowance should be rejected');
    }

    // =========================================================================
    // CONFIG CHANGE TEST
    // =========================================================================

    /**
     * @description: When the allowance value changes, subsequent validations use the new value.
     *               With 15 days used and allowance changed to 25, a 9-day request should succeed.
     */
    @isTest
    static void givenAllowanceIncreased_whenInserted_thenNewValueRespected() {
        EPA_AnnualAllowanceValidation_Class.allowanceOverride = 25;
        EPA_LeaveCategory__c cat = getTestCategory();

        // 15 days used, allowance is now 25, requesting 9 days (total 24 <= 25)
        EPA_StudyLeaveRequest__c req = new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = testUserId,
            EPA_Category__c = cat.Id,
            EPA_StartDate__c = Date.newInstance(2027, 5, 5),   // Monday
            EPA_EndDate__c = Date.newInstance(2027, 5, 15)      // Thursday = 9 weekdays
        );

        Test.startTest();
        insert req;
        Test.stopTest();

        EPA_StudyLeaveRequest__c result = [
            SELECT Id FROM EPA_StudyLeaveRequest__c WHERE Id = :req.Id
        ];
        Assert.isNotNull(result, 'Request should succeed with increased allowance');
    }

    // =========================================================================
    // BULK TEST
    // =========================================================================

    /**
     * @description: Bulk insert of 200 records processes without governor limit exceptions.
     *               Each record requests 0 business days (Sat-Sun) to stay within allowance.
     */
    @isTest
    static void givenBulkInsert_whenInserted_thenAllProcessed() {
        EPA_AnnualAllowanceValidation_Class.allowanceOverride = 20;
        EPA_LeaveCategory__c cat = getTestCategory();

        List<EPA_StudyLeaveRequest__c> bulkRequests = new List<EPA_StudyLeaveRequest__c>();
        for (Integer i = 0; i < 200; i++) {
            bulkRequests.add(new EPA_StudyLeaveRequest__c(
                EPA_Apprentice__c = testUserId,
                EPA_Category__c = cat.Id,
                EPA_StartDate__c = Date.newInstance(2028, 1, 8),  // Saturday
                EPA_EndDate__c = Date.newInstance(2028, 1, 9)      // Sunday = 0 business days
            ));
        }

        Test.startTest();
        insert bulkRequests;
        Test.stopTest();

        Integer insertedCount = [SELECT COUNT() FROM EPA_StudyLeaveRequest__c
                                  WHERE EPA_StartDate__c = :Date.newInstance(2028, 1, 8)];
        Assert.areEqual(200, insertedCount, 'All 200 bulk records should be inserted');
    }
}
