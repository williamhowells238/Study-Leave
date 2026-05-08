/**
 * @description: Test class for EPA_LeaveBalanceCalculation_Class covering positive,
 *               negative, and bulk scenarios (PNB pattern). Verifies balance increments
 *               on approval, decrements on cancellation, no change on rejection, floor
 *               at zero, missing quota handling, and bulk multi-apprentice transactions.
 * @author: Developer Agent
 * @date: 2026-05-08
 */
@isTest(SeeAllData=false)
private class EPA_LeaveBalanceCalculation_TestClass {

    /**
     * @description: Creates test data including apprentice and manager users, quota records,
     *               and pending study leave requests with appropriate sharing.
     */
    @TestSetup
    static void makeData() {
        Id managerId = UserInfo.getUserId();

        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        // Create apprentice user
        User apprentice = new User(
            FirstName = 'Balance',
            LastName = 'Apprentice',
            Email = 'balance.apprentice@epa.test.invalid',
            Username = 'balance.apprentice.' + DateTime.now().getTime() + '@epa.test.invalid',
            Alias = 'balapr',
            TimeZoneSidKey = 'Europe/London',
            LocaleSidKey = 'en_GB',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id,
            ManagerId = managerId
        );
        insert apprentice;

        // Assign apprentice permission set
        PermissionSet aprPs = [SELECT Id FROM PermissionSet WHERE Name = 'EPA_ApprenticeUser_PermissionSet' LIMIT 1];
        insert new PermissionSetAssignment(AssigneeId = apprentice.Id, PermissionSetId = aprPs.Id);

        System.runAs(new User(Id = managerId)) {
            // Create leave quota for the current year
            insert new EPA_LeaveQuota__c(
                EPA_Apprentice__c = apprentice.Id,
                EPA_AnnualEntitlement__c = 24,
                EPA_DaysUsed__c = 0,
                EPA_QuotaYear__c = String.valueOf(Date.today().year())
            );

            Datetime now = Datetime.now();

            // Create multiple Pending requests for testing
            List<EPA_StudyLeaveRequest__c> requests = new List<EPA_StudyLeaveRequest__c>();
            for (Integer i = 0; i < 6; i++) {
                requests.add(new EPA_StudyLeaveRequest__c(
                    EPA_Apprentice__c = apprentice.Id,
                    EPA_Manager__c = managerId,
                    EPA_LeaveType__c = 'College',
                    EPA_StartDate__c = Date.today().addDays(10 + (i * 5)),
                    EPA_EndDate__c = Date.today().addDays(12 + (i * 5)),
                    EPA_NumberOfDays__c = 2,
                    EPA_Status__c = 'Pending',
                    EPA_Reason__c = 'Balance test ' + i,
                    EPA_SubmissionTimestamp__c = now
                ));
            }
            insert requests;

            // Grant apprentice Edit access via manual sharing (Private OWD)
            List<EPA_StudyLeaveRequest__Share> apprenticeShares = new List<EPA_StudyLeaveRequest__Share>();
            for (EPA_StudyLeaveRequest__c req : requests) {
                apprenticeShares.add(new EPA_StudyLeaveRequest__Share(
                    ParentId = req.Id,
                    UserOrGroupId = apprentice.Id,
                    AccessLevel = 'Edit',
                    RowCause = Schema.EPA_StudyLeaveRequest__Share.RowCause.Manual
                ));
            }
            insert apprenticeShares;
        }
    }

    /**
     * @description: Positive test — approving a request increments Days Used by the
     *               request's Number of Days.
     */
    @isTest
    static void givenPendingRequest_whenApproved_thenDaysUsedIncremented() {
        User apprentice = [SELECT Id FROM User WHERE LastName = 'Apprentice' AND FirstName = 'Balance' LIMIT 1];
        EPA_StudyLeaveRequest__c request = [
            SELECT Id, EPA_NumberOfDays__c
            FROM EPA_StudyLeaveRequest__c
            WHERE EPA_Status__c = 'Pending' AND EPA_Apprentice__c = :apprentice.Id
            LIMIT 1
        ];

        Test.startTest();
        request.EPA_Status__c = 'Approved';
        request.EPA_ApprovalTimestamp__c = Datetime.now();
        update request;
        Test.stopTest();

        EPA_LeaveQuota__c quota = [
            SELECT EPA_DaysUsed__c
            FROM EPA_LeaveQuota__c
            WHERE EPA_Apprentice__c = :apprentice.Id
            LIMIT 1
        ];
        Assert.areEqual(request.EPA_NumberOfDays__c, quota.EPA_DaysUsed__c,
            'Days Used should be incremented by the number of days on the approved request');
    }

    /**
     * @description: Positive test — cancelling an approved request decrements Days Used
     *               back to the original value.
     */
    @isTest
    static void givenApprovedRequest_whenCancelled_thenDaysUsedDecremented() {
        User apprentice = [SELECT Id FROM User WHERE LastName = 'Apprentice' AND FirstName = 'Balance' LIMIT 1];
        EPA_StudyLeaveRequest__c request = [
            SELECT Id, EPA_NumberOfDays__c
            FROM EPA_StudyLeaveRequest__c
            WHERE EPA_Status__c = 'Pending' AND EPA_Apprentice__c = :apprentice.Id
            LIMIT 1
        ];

        // First approve the request
        request.EPA_Status__c = 'Approved';
        request.EPA_ApprovalTimestamp__c = Datetime.now();
        update request;

        // Verify increment happened
        EPA_LeaveQuota__c quotaAfterApproval = [
            SELECT EPA_DaysUsed__c FROM EPA_LeaveQuota__c
            WHERE EPA_Apprentice__c = :apprentice.Id LIMIT 1
        ];
        Assert.areEqual(request.EPA_NumberOfDays__c, quotaAfterApproval.EPA_DaysUsed__c,
            'Days Used should be incremented after approval');

        Test.startTest();
        request.EPA_Status__c = 'Cancelled';
        request.EPA_CancellationTimestamp__c = Datetime.now();
        update request;
        Test.stopTest();

        EPA_LeaveQuota__c quotaAfterCancel = [
            SELECT EPA_DaysUsed__c FROM EPA_LeaveQuota__c
            WHERE EPA_Apprentice__c = :apprentice.Id LIMIT 1
        ];
        Assert.areEqual(0, quotaAfterCancel.EPA_DaysUsed__c,
            'Days Used should be decremented back to 0 after cancellation');
    }

    /**
     * @description: Positive test — rejecting a request leaves Days Used unchanged.
     */
    @isTest
    static void givenPendingRequest_whenRejected_thenDaysUsedUnchanged() {
        User apprentice = [SELECT Id FROM User WHERE LastName = 'Apprentice' AND FirstName = 'Balance' LIMIT 1];
        EPA_StudyLeaveRequest__c request = [
            SELECT Id
            FROM EPA_StudyLeaveRequest__c
            WHERE EPA_Status__c = 'Pending' AND EPA_Apprentice__c = :apprentice.Id
            LIMIT 1
        ];

        EPA_LeaveQuota__c quotaBefore = [
            SELECT EPA_DaysUsed__c FROM EPA_LeaveQuota__c
            WHERE EPA_Apprentice__c = :apprentice.Id LIMIT 1
        ];

        Test.startTest();
        request.EPA_Status__c = 'Rejected';
        request.EPA_RejectionTimestamp__c = Datetime.now();
        request.EPA_RejectionReason__c = 'Not enough notice';
        update request;
        Test.stopTest();

        EPA_LeaveQuota__c quotaAfter = [
            SELECT EPA_DaysUsed__c FROM EPA_LeaveQuota__c
            WHERE EPA_Apprentice__c = :apprentice.Id LIMIT 1
        ];
        Assert.areEqual(quotaBefore.EPA_DaysUsed__c, quotaAfter.EPA_DaysUsed__c,
            'Days Used should remain unchanged when a request is rejected');
    }

    /**
     * @description: Negative test — Days Used floors at zero when a cancellation would
     *               push it below zero.
     */
    @isTest
    static void givenZeroDaysUsed_whenApprovedRequestCancelled_thenDaysUsedFloorsAtZero() {
        User apprentice = [SELECT Id FROM User WHERE LastName = 'Apprentice' AND FirstName = 'Balance' LIMIT 1];
        EPA_StudyLeaveRequest__c request = [
            SELECT Id, EPA_NumberOfDays__c
            FROM EPA_StudyLeaveRequest__c
            WHERE EPA_Status__c = 'Pending' AND EPA_Apprentice__c = :apprentice.Id
            LIMIT 1
        ];

        // Approve, then manually set Days Used to 0 to simulate a data anomaly
        request.EPA_Status__c = 'Approved';
        request.EPA_ApprovalTimestamp__c = Datetime.now();
        update request;

        EPA_LeaveQuota__c quota = [
            SELECT Id, EPA_DaysUsed__c FROM EPA_LeaveQuota__c
            WHERE EPA_Apprentice__c = :apprentice.Id LIMIT 1
        ];
        quota.EPA_DaysUsed__c = 0;
        update quota;

        Test.startTest();
        request.EPA_Status__c = 'Cancelled';
        request.EPA_CancellationTimestamp__c = Datetime.now();
        update request;
        Test.stopTest();

        EPA_LeaveQuota__c quotaAfter = [
            SELECT EPA_DaysUsed__c FROM EPA_LeaveQuota__c
            WHERE EPA_Apprentice__c = :apprentice.Id LIMIT 1
        ];
        Assert.areEqual(0, quotaAfter.EPA_DaysUsed__c,
            'Days Used should floor at zero and never go negative');
    }

    /**
     * @description: Negative test — missing quota record does not throw an exception.
     *               The transaction completes cleanly and no balance is updated.
     */
    @isTest
    static void givenMissingQuotaRecord_whenRequestApproved_thenNoExceptionThrown() {
        User apprentice = [SELECT Id FROM User WHERE LastName = 'Apprentice' AND FirstName = 'Balance' LIMIT 1];
        EPA_StudyLeaveRequest__c request = [
            SELECT Id
            FROM EPA_StudyLeaveRequest__c
            WHERE EPA_Status__c = 'Pending' AND EPA_Apprentice__c = :apprentice.Id
            LIMIT 1
        ];

        // Delete all quota records for the apprentice
        List<EPA_LeaveQuota__c> quotas = [
            SELECT Id FROM EPA_LeaveQuota__c WHERE EPA_Apprentice__c = :apprentice.Id
        ];
        delete quotas;

        Test.startTest();
        request.EPA_Status__c = 'Approved';
        request.EPA_ApprovalTimestamp__c = Datetime.now();
        update request;
        Test.stopTest();

        // Verify no exception was thrown — the test reaching this point is the assertion
        List<EPA_LeaveQuota__c> remaining = [
            SELECT Id FROM EPA_LeaveQuota__c WHERE EPA_Apprentice__c = :apprentice.Id
        ];
        Assert.areEqual(0, remaining.size(),
            'No quota records should exist after deletion');
    }

    /**
     * @description: Bulk test — approving 200+ requests across multiple apprentices in a
     *               single transaction updates all quota records correctly without governor
     *               limit exceptions.
     */
    @isTest
    static void givenBulkRequests_whenApprovedInSingleTransaction_thenAllQuotasUpdated() {
        Id managerId = UserInfo.getUserId();
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        PermissionSet aprPs = [SELECT Id FROM PermissionSet WHERE Name = 'EPA_ApprenticeUser_PermissionSet' LIMIT 1];

        // Create 4 bulk apprentice users
        List<User> bulkApprentices = new List<User>();
        for (Integer i = 0; i < 4; i++) {
            bulkApprentices.add(new User(
                FirstName = 'BulkBal',
                LastName = 'Apprentice' + i,
                Email = 'bulkbal.apprentice' + i + '@epa.test.invalid',
                Username = 'bulkbal.apprentice' + i + '.' + DateTime.now().getTime() + '@epa.test.invalid',
                Alias = 'bba' + i,
                TimeZoneSidKey = 'Europe/London',
                LocaleSidKey = 'en_GB',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = standardProfile.Id,
                ManagerId = managerId
            ));
        }
        insert bulkApprentices;

        // Assign permission sets
        List<PermissionSetAssignment> psAssignments = new List<PermissionSetAssignment>();
        for (User u : bulkApprentices) {
            psAssignments.add(new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = aprPs.Id));
        }
        insert psAssignments;

        System.runAs(new User(Id = managerId)) {
            // Create quota records for each apprentice
            List<EPA_LeaveQuota__c> bulkQuotas = new List<EPA_LeaveQuota__c>();
            for (User u : bulkApprentices) {
                bulkQuotas.add(new EPA_LeaveQuota__c(
                    EPA_Apprentice__c = u.Id,
                    EPA_AnnualEntitlement__c = 24,
                    EPA_DaysUsed__c = 0,
                    EPA_QuotaYear__c = String.valueOf(Date.today().year())
                ));
            }
            insert bulkQuotas;

            // Create 200+ requests spread across the 4 apprentices (50 each)
            List<EPA_StudyLeaveRequest__c> bulkRequests = new List<EPA_StudyLeaveRequest__c>();
            Datetime now = Datetime.now();
            for (Integer a = 0; a < 4; a++) {
                for (Integer i = 0; i < 50; i++) {
                    bulkRequests.add(new EPA_StudyLeaveRequest__c(
                        EPA_Apprentice__c = bulkApprentices[a].Id,
                        EPA_Manager__c = managerId,
                        EPA_LeaveType__c = 'College',
                        EPA_StartDate__c = Date.today().addDays(100 + (a * 100) + i),
                        EPA_EndDate__c = Date.today().addDays(100 + (a * 100) + i),
                        EPA_NumberOfDays__c = 1,
                        EPA_Status__c = 'Pending',
                        EPA_Reason__c = 'Bulk balance test ' + a + '-' + i,
                        EPA_SubmissionTimestamp__c = now
                    ));
                }
            }
            insert bulkRequests;

            // Approve all 200 in a single DML
            Test.startTest();
            for (EPA_StudyLeaveRequest__c req : bulkRequests) {
                req.EPA_Status__c = 'Approved';
                req.EPA_ApprovalTimestamp__c = now;
            }
            update bulkRequests;
            Test.stopTest();

            // Assert each apprentice's quota reflects 50 days used
            for (User u : bulkApprentices) {
                EPA_LeaveQuota__c quota = [
                    SELECT EPA_DaysUsed__c FROM EPA_LeaveQuota__c
                    WHERE EPA_Apprentice__c = :u.Id LIMIT 1
                ];
                // Capped at Annual Entitlement (24) since 50 > 24
                Assert.areEqual(24, quota.EPA_DaysUsed__c,
                    'Days Used should be capped at Annual Entitlement (24) for apprentice ' + u.LastName);
            }
        }
    }
}
