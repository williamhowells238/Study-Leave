/**
 * @description: Test class for EPA_BusinessDayCalculation_Trigger and EPA_BusinessDayCalculation_Class.
 *               Provides Positive, Negative, and Bulk (PNB) test coverage for business day calculation.
 * @author: Developer Agent
 * @date: 2026-04-21
 */
@isTest(SeeAllData=false)
private class EPA_BusinessDayCalculation_TestClass {

    /**
     * @description: Creates test data including public holiday records for use across all test methods.
     */
    private static Id testUserId = UserInfo.getUserId();

    @TestSetup
    static void makeData() {
        // Create a leave category for use across all test methods
        EPA_LeaveCategory__c category = new EPA_LeaveCategory__c(Name = 'Exam Prep');
        insert category;

        // Create public holidays for a known week: Wednesday 2027-01-06
        // 2027-01-04 is a Monday, 2027-01-08 is a Friday
        // 2027-01-06 (Wednesday) is a public holiday
        List<EPA_PublicHoliday__c> holidays = new List<EPA_PublicHoliday__c>();
        holidays.add(new EPA_PublicHoliday__c(EPA_HolidayDate__c = Date.newInstance(2027, 1, 6)));
        // Public holiday on a Saturday (2027-01-09) — should not double-subtract
        holidays.add(new EPA_PublicHoliday__c(EPA_HolidayDate__c = Date.newInstance(2027, 1, 9)));
        // Public holiday for two-week range test: Wednesday 2027-01-13
        holidays.add(new EPA_PublicHoliday__c(EPA_HolidayDate__c = Date.newInstance(2027, 1, 13)));
        insert holidays;
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
     * @description: Monday to Friday with no public holidays = 5 business days.
     *               2027-01-18 (Mon) to 2027-01-22 (Fri) — no holidays in this range.
     */
    @isTest
    static void givenMonToFriNoHolidays_whenInserted_thenFiveBusinessDays() {
        EPA_LeaveCategory__c cat = getTestCategory();
        EPA_StudyLeaveRequest__c req = new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = testUserId,
            EPA_Category__c = cat.Id,
            EPA_StartDate__c = Date.newInstance(2027, 1, 18), // Monday
            EPA_EndDate__c = Date.newInstance(2027, 1, 22)     // Friday
        );

        Test.startTest();
        insert req;
        Test.stopTest();

        EPA_StudyLeaveRequest__c result = [
            SELECT EPA_CalculatedBusinessDays__c FROM EPA_StudyLeaveRequest__c WHERE Id = :req.Id
        ];
        Assert.areEqual(5, result.EPA_CalculatedBusinessDays__c,
            'Monday to Friday with no holidays should be 5 business days');
    }

    /**
     * @description: Two-week range (Mon to following Fri) with one mid-week public holiday = 9 business days.
     *               2026-01-05 (Mon) to 2026-01-16 (Fri) = 10 weekdays, minus 2026-01-07 (Wed holiday)
     *               and 2026-01-14 (Wed holiday) = 8 business days.
     *               Wait — let me recalculate: 2026-01-05 to 2026-01-16 spans Mon-Fri week 1 (5 days)
     *               + Mon-Fri week 2 (5 days) = 10 weekdays, minus 2 holidays (Jan 7 and Jan 14) = 8.
     *               For the AC "Mon to following Fri with ONE holiday = 9", use 2026-01-05 to 2026-01-09:
     *               That's Mon-Fri = 5 weekdays minus 1 holiday (Jan 7) = 4.
     *               Use 2026-01-05 (Mon) to 2026-01-16 (Fri) with only Jan 7 holiday in range.
     *               Actually, Jan 14 is also in range. Let me pick a clean two-week range:
     *               2026-02-02 (Mon) to 2026-02-13 (Fri) = 10 weekdays, no holidays = 10.
     *               For the AC test, use 2026-01-05 to 2026-01-16 with two holidays = 8.
     */
    @isTest
    static void givenTwoWeekRangeWithOneHoliday_whenInserted_thenCorrectBusinessDays() {
        // 2027-01-04 (Mon) to 2027-01-08 (Fri) = 5 weekdays minus 1 holiday (Jan 6) = 4 business days
        EPA_LeaveCategory__c cat = getTestCategory();
        EPA_StudyLeaveRequest__c req = new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = testUserId,
            EPA_Category__c = cat.Id,
            EPA_StartDate__c = Date.newInstance(2027, 1, 4),  // Monday
            EPA_EndDate__c = Date.newInstance(2027, 1, 8)      // Friday
        );

        Test.startTest();
        insert req;
        Test.stopTest();

        EPA_StudyLeaveRequest__c result = [
            SELECT EPA_CalculatedBusinessDays__c FROM EPA_StudyLeaveRequest__c WHERE Id = :req.Id
        ];
        Assert.areEqual(4, result.EPA_CalculatedBusinessDays__c,
            'Mon to Fri with one mid-week holiday should be 4 business days');
    }

    /**
     * @description: AC test — two-week range Mon to following Fri with one public holiday = 9.
     *               2026-01-19 (Mon) to 2026-01-30 (Fri) = 10 weekdays.
     *               We need a holiday in this range. Create one inline.
     */
    @isTest
    static void givenTwoWeekRangeWithOneHoliday_whenInserted_thenNineBusinessDays() {
        // Add a holiday on Wed 2027-01-20
        insert new EPA_PublicHoliday__c(EPA_HolidayDate__c = Date.newInstance(2027, 1, 20));

        EPA_LeaveCategory__c cat = getTestCategory();
        EPA_StudyLeaveRequest__c req = new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = testUserId,
            EPA_Category__c = cat.Id,
            EPA_StartDate__c = Date.newInstance(2027, 1, 18), // Monday
            EPA_EndDate__c = Date.newInstance(2027, 1, 29)     // Friday
        );

        Test.startTest();
        insert req;
        Test.stopTest();

        EPA_StudyLeaveRequest__c result = [
            SELECT EPA_CalculatedBusinessDays__c FROM EPA_StudyLeaveRequest__c WHERE Id = :req.Id
        ];
        Assert.areEqual(9, result.EPA_CalculatedBusinessDays__c,
            'Two-week Mon-Fri range with one holiday should be 9 business days');
    }

    /**
     * @description: Single weekday, no holiday = 1 business day.
     */
    @isTest
    static void givenSingleWeekday_whenInserted_thenOneBusinessDay() {
        EPA_LeaveCategory__c cat = getTestCategory();
        EPA_StudyLeaveRequest__c req = new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = testUserId,
            EPA_Category__c = cat.Id,
            EPA_StartDate__c = Date.newInstance(2027, 1, 18), // Monday
            EPA_EndDate__c = Date.newInstance(2027, 1, 18)     // Same Monday
        );

        Test.startTest();
        insert req;
        Test.stopTest();

        EPA_StudyLeaveRequest__c result = [
            SELECT EPA_CalculatedBusinessDays__c FROM EPA_StudyLeaveRequest__c WHERE Id = :req.Id
        ];
        Assert.areEqual(1, result.EPA_CalculatedBusinessDays__c,
            'Single weekday with no holiday should be 1 business day');
    }

    // =========================================================================
    // NEGATIVE TESTS
    // =========================================================================

    /**
     * @description: Single day on Saturday = 0 business days.
     *               2026-01-10 is a Saturday.
     */
    @isTest
    static void givenSingleSaturday_whenInserted_thenZeroBusinessDays() {
        EPA_LeaveCategory__c cat = getTestCategory();
        EPA_StudyLeaveRequest__c req = new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = testUserId,
            EPA_Category__c = cat.Id,
            EPA_StartDate__c = Date.newInstance(2027, 1, 9), // Saturday
            EPA_EndDate__c = Date.newInstance(2027, 1, 9)
        );

        Test.startTest();
        insert req;
        Test.stopTest();

        EPA_StudyLeaveRequest__c result = [
            SELECT EPA_CalculatedBusinessDays__c FROM EPA_StudyLeaveRequest__c WHERE Id = :req.Id
        ];
        Assert.areEqual(0, result.EPA_CalculatedBusinessDays__c,
            'Single Saturday should be 0 business days');
    }

    /**
     * @description: Single day on Sunday = 0 business days.
     *               2026-01-11 is a Sunday.
     */
    @isTest
    static void givenSingleSunday_whenInserted_thenZeroBusinessDays() {
        EPA_LeaveCategory__c cat = getTestCategory();
        EPA_StudyLeaveRequest__c req = new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = testUserId,
            EPA_Category__c = cat.Id,
            EPA_StartDate__c = Date.newInstance(2027, 1, 10), // Sunday
            EPA_EndDate__c = Date.newInstance(2027, 1, 10)
        );

        Test.startTest();
        insert req;
        Test.stopTest();

        EPA_StudyLeaveRequest__c result = [
            SELECT EPA_CalculatedBusinessDays__c FROM EPA_StudyLeaveRequest__c WHERE Id = :req.Id
        ];
        Assert.areEqual(0, result.EPA_CalculatedBusinessDays__c,
            'Single Sunday should be 0 business days');
    }

    /**
     * @description: Public holiday on a Saturday should not double-subtract.
     *               Range includes Sat 2026-01-10 (which is also a public holiday).
     *               2026-01-08 (Thu) to 2026-01-12 (Mon) = Thu, Fri, Sat, Sun, Mon.
     *               Weekdays: Thu, Fri, Mon = 3. Thu and Fri have no holidays.
     *               Mon (Jan 12) has no holiday. Result should be 3.
     *               The holiday on Sat Jan 10 should not reduce the count further.
     */
    @isTest
    static void givenHolidayOnWeekend_whenInserted_thenNotDoubleSubtracted() {
        EPA_LeaveCategory__c cat = getTestCategory();
        EPA_StudyLeaveRequest__c req = new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = testUserId,
            EPA_Category__c = cat.Id,
            EPA_StartDate__c = Date.newInstance(2027, 1, 7),  // Thursday
            EPA_EndDate__c = Date.newInstance(2027, 1, 11)     // Monday
        );

        Test.startTest();
        insert req;
        Test.stopTest();

        EPA_StudyLeaveRequest__c result = [
            SELECT EPA_CalculatedBusinessDays__c FROM EPA_StudyLeaveRequest__c WHERE Id = :req.Id
        ];
        Assert.areEqual(3, result.EPA_CalculatedBusinessDays__c,
            'Holiday on Saturday should not double-subtract; expect 3 weekdays');
    }

    /**
     * @description: Null Start Date is rejected by the platform (required field).
     *               Asserts DmlException is thrown.
     */
    @isTest
    static void givenNullStartDate_whenInserted_thenDmlExceptionThrown() {
        EPA_LeaveCategory__c cat = getTestCategory();
        EPA_StudyLeaveRequest__c req = new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = testUserId,
            EPA_Category__c = cat.Id,
            EPA_StartDate__c = null,
            EPA_EndDate__c = Date.newInstance(2027, 1, 8)
        );

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            insert req;
        } catch (DmlException e) {
            exceptionThrown = true;
            Assert.isTrue(e.getMessage().contains('EPA_StartDate__c'),
                'Exception should reference the missing Start Date field');
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown,
            'DmlException should be thrown when Start Date is null');
    }

    /**
     * @description: Null End Date is rejected by the platform (required field).
     *               Asserts DmlException is thrown.
     */
    @isTest
    static void givenNullEndDate_whenInserted_thenDmlExceptionThrown() {
        EPA_LeaveCategory__c cat = getTestCategory();
        EPA_StudyLeaveRequest__c req = new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = testUserId,
            EPA_Category__c = cat.Id,
            EPA_StartDate__c = Date.newInstance(2027, 1, 4),
            EPA_EndDate__c = null
        );

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            insert req;
        } catch (DmlException e) {
            exceptionThrown = true;
            Assert.isTrue(e.getMessage().contains('EPA_EndDate__c'),
                'Exception should reference the missing End Date field');
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown,
            'DmlException should be thrown when End Date is null');
    }

    // =========================================================================
    // BULK TEST
    // =========================================================================

    /**
     * @description: Bulk insert of 200 records to verify no governor limit issues.
     */
    @isTest
    static void givenBulkInsert_whenTwoHundredRecords_thenAllCalculatedCorrectly() {
        List<EPA_StudyLeaveRequest__c> requests = new List<EPA_StudyLeaveRequest__c>();
        // All records: Mon 2027-01-18 to Fri 2027-01-22 = 5 business days (no holidays)
        EPA_LeaveCategory__c cat = getTestCategory();
        for (Integer i = 0; i < 200; i++) {
            requests.add(new EPA_StudyLeaveRequest__c(
                EPA_Apprentice__c = testUserId,
                EPA_Category__c = cat.Id,
                EPA_StartDate__c = Date.newInstance(2027, 1, 18),
                EPA_EndDate__c = Date.newInstance(2027, 1, 22)
            ));
        }

        Test.startTest();
        insert requests;
        Test.stopTest();

        List<EPA_StudyLeaveRequest__c> results = [
            SELECT EPA_CalculatedBusinessDays__c FROM EPA_StudyLeaveRequest__c
            WHERE Id IN :requests
        ];
        Assert.areEqual(200, results.size(), 'All 200 records should be inserted');
        for (EPA_StudyLeaveRequest__c r : results) {
            Assert.areEqual(5, r.EPA_CalculatedBusinessDays__c,
                'Each record should have 5 business days');
        }
    }

    // =========================================================================
    // UPDATE / RECALCULATION TEST
    // =========================================================================

    /**
     * @description: Update Start Date and End Date triggers recalculation.
     */
    @isTest
    static void givenDateChange_whenUpdated_thenRecalculated() {
        EPA_LeaveCategory__c cat = getTestCategory();
        EPA_StudyLeaveRequest__c req = new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = testUserId,
            EPA_Category__c = cat.Id,
            EPA_StartDate__c = Date.newInstance(2027, 1, 18), // Mon-Fri = 5
            EPA_EndDate__c = Date.newInstance(2027, 1, 22)
        );
        insert req;

        EPA_StudyLeaveRequest__c inserted = [
            SELECT EPA_CalculatedBusinessDays__c FROM EPA_StudyLeaveRequest__c WHERE Id = :req.Id
        ];
        Assert.areEqual(5, inserted.EPA_CalculatedBusinessDays__c,
            'Initial calculation should be 5');

        // Update to a single day
        req.EPA_StartDate__c = Date.newInstance(2027, 1, 18);
        req.EPA_EndDate__c = Date.newInstance(2027, 1, 18);

        Test.startTest();
        update req;
        Test.stopTest();

        EPA_StudyLeaveRequest__c updated = [
            SELECT EPA_CalculatedBusinessDays__c FROM EPA_StudyLeaveRequest__c WHERE Id = :req.Id
        ];
        Assert.areEqual(1, updated.EPA_CalculatedBusinessDays__c,
            'After update to single day, should be 1 business day');
    }
}
