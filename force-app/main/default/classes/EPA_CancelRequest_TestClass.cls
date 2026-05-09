/**
 * @description: Test class for EPA_CancelRequest_Class covering positive,
 *               negative, and bulk scenarios (PNB pattern).
 * @author: Developer Agent
 * @date: 2026-05-08
 */
@isTest(SeeAllData=false)
private class EPA_CancelRequest_TestClass {

    /**
     * @description: Creates test data including apprentice, non-owner, and manager users,
     *               along with study leave requests in various statuses.
     */
    @TestSetup
    static void makeData() {
        Id managerId = UserInfo.getUserId();

        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        // Create apprentice user (direct report of running user)
        User apprentice = new User(
            FirstName = 'Test',
            LastName = 'CancelApprentice',
            Email = 'test.cancel.apprentice@epa.test.invalid',
            Username = 'test.cancel.apprentice.' + DateTime.now().getTime() + '@epa.test.invalid',
            Alias = 'tcapr',
            TimeZoneSidKey = 'Europe/London',
            LocaleSidKey = 'en_GB',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id,
            ManagerId = managerId
        );
        insert apprentice;

        // Create non-owner user (not the apprentice on the request)
        User nonOwner = new User(
            FirstName = 'Non',
            LastName = 'CancelOwner',
            Email = 'non.cancel.owner@epa.test.invalid',
            Username = 'non.cancel.owner.' + DateTime.now().getTime() + '@epa.test.invalid',
            Alias = 'ncown',
            TimeZoneSidKey = 'Europe/London',
            LocaleSidKey = 'en_GB',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );
        insert nonOwner;

        // Assign apprentice permission set to both the apprentice and non-owner so they have object access
        PermissionSet aprPs = [SELECT Id FROM PermissionSet WHERE Name = 'EPA_ApprenticeUser_PermissionSet' LIMIT 1];
        insert new List<PermissionSetAssignment>{
            new PermissionSetAssignment(AssigneeId = apprentice.Id, PermissionSetId = aprPs.Id),
            new PermissionSetAssignment(AssigneeId = nonOwner.Id, PermissionSetId = aprPs.Id)
        };

        // Use System.runAs to avoid Mixed DML error between setup and non-setup objects
        System.runAs(new User(Id = managerId)) {
            // Create leave quota for apprentice
            insert new EPA_LeaveQuota__c(
                EPA_Apprentice__c = apprentice.Id,
                EPA_AnnualEntitlement__c = 20,
                EPA_QuotaYear__c = '2026'
            );

            Datetime now = Datetime.now();

            // Create an Approved request
            EPA_StudyLeaveRequest__c approvedReq = new EPA_StudyLeaveRequest__c(
                EPA_Apprentice__c = apprentice.Id,
                EPA_Manager__c = managerId,
                EPA_LeaveType__c = 'College',
                EPA_StartDate__c = Date.today().addDays(10),
                EPA_EndDate__c = Date.today().addDays(11),
                EPA_NumberOfDays__c = 1,
                EPA_Status__c = 'Approved',
                EPA_Reason__c = 'Approved test',
                EPA_SubmissionTimestamp__c = now,
                EPA_ApprovalTimestamp__c = now
            );

            // Create a Pending request
            EPA_StudyLeaveRequest__c pendingReq = new EPA_StudyLeaveRequest__c(
                EPA_Apprentice__c = apprentice.Id,
                EPA_Manager__c = managerId,
                EPA_LeaveType__c = 'College',
                EPA_StartDate__c = Date.today().addDays(20),
                EPA_EndDate__c = Date.today().addDays(21),
                EPA_NumberOfDays__c = 1,
                EPA_Status__c = 'Pending',
                EPA_Reason__c = 'Pending test',
                EPA_SubmissionTimestamp__c = now
            );

            // Create a Rejected request
            EPA_StudyLeaveRequest__c rejectedReq = new EPA_StudyLeaveRequest__c(
                EPA_Apprentice__c = apprentice.Id,
                EPA_Manager__c = managerId,
                EPA_LeaveType__c = 'College',
                EPA_StartDate__c = Date.today().addDays(30),
                EPA_EndDate__c = Date.today().addDays(31),
                EPA_NumberOfDays__c = 1,
                EPA_Status__c = 'Rejected',
                EPA_Reason__c = 'Rejected test',
                EPA_SubmissionTimestamp__c = now,
                EPA_RejectionTimestamp__c = now,
                EPA_RejectionReason__c = 'Not enough notice'
            );

            // Create a Cancelled request
            EPA_StudyLeaveRequest__c cancelledReq = new EPA_StudyLeaveRequest__c(
                EPA_Apprentice__c = apprentice.Id,
                EPA_Manager__c = managerId,
                EPA_LeaveType__c = 'College',
                EPA_StartDate__c = Date.today().addDays(40),
                EPA_EndDate__c = Date.today().addDays(41),
                EPA_NumberOfDays__c = 1,
                EPA_Status__c = 'Cancelled',
                EPA_Reason__c = 'Cancelled test',
                EPA_SubmissionTimestamp__c = now,
                EPA_CancellationTimestamp__c = now
            );

            List<EPA_StudyLeaveRequest__c> allRequests = new List<EPA_StudyLeaveRequest__c>{
                approvedReq, pendingReq, rejectedReq, cancelledReq
            };
            insert allRequests;

            // Grant apprentice Read access via manual sharing (Private OWD — apprentice is not the record owner)
            List<EPA_StudyLeaveRequest__Share> apprenticeShares = new List<EPA_StudyLeaveRequest__Share>();
            for (EPA_StudyLeaveRequest__c req : allRequests) {
                apprenticeShares.add(new EPA_StudyLeaveRequest__Share(
                    ParentId = req.Id,
                    UserOrGroupId = apprentice.Id,
                    AccessLevel = 'Edit',
                    RowCause = Schema.EPA_StudyLeaveRequest__Share.RowCause.Manual
                ));
            }
            insert apprenticeShares;

            // Grant non-owner Edit access via manual sharing for negative testing
            List<EPA_StudyLeaveRequest__Share> nonOwnerShares = new List<EPA_StudyLeaveRequest__Share>();
            for (EPA_StudyLeaveRequest__c req : allRequests) {
                nonOwnerShares.add(new EPA_StudyLeaveRequest__Share(
                    ParentId = req.Id,
                    UserOrGroupId = nonOwner.Id,
                    AccessLevel = 'Edit',
                    RowCause = Schema.EPA_StudyLeaveRequest__Share.RowCause.Manual
                ));
            }
            insert nonOwnerShares;
        }
    }

    /**
     * @description: Positive test - cancel an approved request as the owning apprentice.
     *               Asserts status transitions to Cancelled and cancellation timestamp is populated.
     */
    @isTest
    static void givenApprovedRequest_whenCancelByApprentice_thenStatusCancelledAndTimestampSet() {
        User apprentice = [SELECT Id FROM User WHERE LastName = 'CancelApprentice' LIMIT 1];
        EPA_StudyLeaveRequest__c request = [
            SELECT Id FROM EPA_StudyLeaveRequest__c
            WHERE EPA_Status__c = 'Approved' AND EPA_Apprentice__c = :apprentice.Id
            LIMIT 1
        ];

        Datetime beforeCancel = Datetime.now();

        Test.startTest();
        System.runAs(apprentice) {
            EPA_CancelRequest_Class.cancelRequest(request.Id);
        }
        Test.stopTest();

        EPA_StudyLeaveRequest__c updated = [
            SELECT EPA_Status__c, EPA_CancellationTimestamp__c
            FROM EPA_StudyLeaveRequest__c
            WHERE Id = :request.Id
        ];
        Assert.areEqual('Cancelled', updated.EPA_Status__c, 'Status should be Cancelled');
        Assert.isNotNull(updated.EPA_CancellationTimestamp__c, 'Cancellation timestamp should be set');
        Assert.isTrue(
            updated.EPA_CancellationTimestamp__c >= beforeCancel,
            'Cancellation timestamp should be at or after the cancel action time'
        );
    }

    /**
     * @description: Negative test - attempt to cancel a Pending request.
     *               Asserts AuraHandledException is thrown with appropriate message.
     */
    @isTest
    static void givenPendingRequest_whenCancelByApprentice_thenExceptionThrown() {
        User apprentice = [SELECT Id FROM User WHERE LastName = 'CancelApprentice' LIMIT 1];
        EPA_StudyLeaveRequest__c request = [
            SELECT Id FROM EPA_StudyLeaveRequest__c
            WHERE EPA_Status__c = 'Pending' AND EPA_Apprentice__c = :apprentice.Id
            LIMIT 1
        ];

        String exceptionMessage;
        Test.startTest();
        System.runAs(apprentice) {
            try {
                EPA_CancelRequest_Class.cancelRequest(request.Id);
                Assert.fail('Expected AuraHandledException was not thrown');
            } catch (AuraHandledException e) {
                exceptionMessage = e.getMessage();
            }
        }
        Test.stopTest();

        Assert.isTrue(
            exceptionMessage != null && exceptionMessage.contains('Approved'),
            'Exception message should indicate only Approved requests can be cancelled'
        );

        // Verify record was not mutated
        EPA_StudyLeaveRequest__c unchanged = [
            SELECT EPA_Status__c FROM EPA_StudyLeaveRequest__c WHERE Id = :request.Id
        ];
        Assert.areEqual('Pending', unchanged.EPA_Status__c, 'Status should remain Pending after failed attempt');
    }

    /**
     * @description: Negative test - attempt to cancel a Rejected request.
     *               Asserts AuraHandledException is thrown.
     */
    @isTest
    static void givenRejectedRequest_whenCancelByApprentice_thenExceptionThrown() {
        User apprentice = [SELECT Id FROM User WHERE LastName = 'CancelApprentice' LIMIT 1];
        EPA_StudyLeaveRequest__c request = [
            SELECT Id FROM EPA_StudyLeaveRequest__c
            WHERE EPA_Status__c = 'Rejected' AND EPA_Apprentice__c = :apprentice.Id
            LIMIT 1
        ];

        String exceptionMessage;
        Test.startTest();
        System.runAs(apprentice) {
            try {
                EPA_CancelRequest_Class.cancelRequest(request.Id);
                Assert.fail('Expected AuraHandledException was not thrown');
            } catch (AuraHandledException e) {
                exceptionMessage = e.getMessage();
            }
        }
        Test.stopTest();

        Assert.isTrue(
            exceptionMessage != null && exceptionMessage.contains('Approved'),
            'Exception message should indicate only Approved requests can be cancelled'
        );
    }

    /**
     * @description: Negative test - attempt to cancel an already Cancelled request.
     *               Asserts AuraHandledException is thrown.
     */
    @isTest
    static void givenCancelledRequest_whenCancelAgain_thenExceptionThrown() {
        User apprentice = [SELECT Id FROM User WHERE LastName = 'CancelApprentice' LIMIT 1];
        EPA_StudyLeaveRequest__c request = [
            SELECT Id FROM EPA_StudyLeaveRequest__c
            WHERE EPA_Status__c = 'Cancelled' AND EPA_Apprentice__c = :apprentice.Id
            LIMIT 1
        ];

        String exceptionMessage;
        Test.startTest();
        System.runAs(apprentice) {
            try {
                EPA_CancelRequest_Class.cancelRequest(request.Id);
                Assert.fail('Expected AuraHandledException was not thrown');
            } catch (AuraHandledException e) {
                exceptionMessage = e.getMessage();
            }
        }
        Test.stopTest();

        Assert.isTrue(
            exceptionMessage != null && exceptionMessage.contains('Approved'),
            'Exception message should indicate only Approved requests can be cancelled'
        );
    }

    /**
     * @description: Negative test - attempt to cancel a request as a non-owner user.
     *               Asserts AuraHandledException is thrown about authorisation.
     */
    @isTest
    static void givenApprovedRequest_whenCancelByNonOwner_thenExceptionThrown() {
        User apprentice = [SELECT Id FROM User WHERE LastName = 'CancelApprentice' LIMIT 1];
        EPA_StudyLeaveRequest__c request = [
            SELECT Id FROM EPA_StudyLeaveRequest__c
            WHERE EPA_Status__c = 'Approved' AND EPA_Apprentice__c = :apprentice.Id
            LIMIT 1
        ];

        User nonOwner = [SELECT Id FROM User WHERE LastName = 'CancelOwner' AND FirstName = 'Non' LIMIT 1];

        String exceptionMessage;
        Test.startTest();
        System.runAs(nonOwner) {
            try {
                EPA_CancelRequest_Class.cancelRequest(request.Id);
                Assert.fail('Expected AuraHandledException was not thrown');
            } catch (AuraHandledException e) {
                exceptionMessage = e.getMessage();
            }
        }
        Test.stopTest();

        Assert.isTrue(
            exceptionMessage != null && exceptionMessage.contains('not authorised'),
            'Exception message should indicate unauthorised access'
        );

        // Verify record was not mutated
        EPA_StudyLeaveRequest__c unchanged = [
            SELECT EPA_Status__c FROM EPA_StudyLeaveRequest__c WHERE Id = :request.Id
        ];
        Assert.areEqual('Approved', unchanged.EPA_Status__c, 'Status should remain Approved after failed attempt');
    }

    /**
     * @description: Bulk test - cancel 33 approved requests to verify governor limit safety.
     *               Each call performs 1 SOQL + 1 DML with trigger handlers consuming
     *               additional SOQL (balance + notification).
     */
    @isTest
    static void givenBulkApprovedRequests_whenCancelAll_thenAllTransitionCorrectly() {
        Id managerId = UserInfo.getUserId();
        User apprentice = [SELECT Id FROM User WHERE LastName = 'CancelApprentice' LIMIT 1];

        // Create 33 Approved requests for bulk test
        List<EPA_StudyLeaveRequest__c> bulkRequests = new List<EPA_StudyLeaveRequest__c>();
        Datetime now = Datetime.now();
        System.runAs(new User(Id = managerId)) {
            for (Integer i = 0; i < 33; i++) {
                bulkRequests.add(new EPA_StudyLeaveRequest__c(
                    EPA_Apprentice__c = apprentice.Id,
                    EPA_Manager__c = managerId,
                    EPA_LeaveType__c = 'College',
                    EPA_StartDate__c = Date.today().addDays(100 + i),
                    EPA_EndDate__c = Date.today().addDays(101 + i),
                    EPA_NumberOfDays__c = 1,
                    EPA_Status__c = 'Approved',
                    EPA_Reason__c = 'Bulk cancel test ' + i,
                    EPA_SubmissionTimestamp__c = now,
                    EPA_ApprovalTimestamp__c = now
                ));
            }
            insert bulkRequests;

            // Grant apprentice access via manual sharing (Private OWD)
            List<EPA_StudyLeaveRequest__Share> bulkShares = new List<EPA_StudyLeaveRequest__Share>();
            for (EPA_StudyLeaveRequest__c req : bulkRequests) {
                bulkShares.add(new EPA_StudyLeaveRequest__Share(
                    ParentId = req.Id,
                    UserOrGroupId = apprentice.Id,
                    AccessLevel = 'Edit',
                    RowCause = Schema.EPA_StudyLeaveRequest__Share.RowCause.Manual
                ));
            }
            insert bulkShares;
        }

        Set<Id> bulkIds = new Map<Id, EPA_StudyLeaveRequest__c>(bulkRequests).keySet();

        Test.startTest();
        System.runAs(apprentice) {
            for (EPA_StudyLeaveRequest__c req : bulkRequests) {
                EPA_CancelRequest_Class.cancelRequest(req.Id);
            }
        }
        Test.stopTest();

        List<EPA_StudyLeaveRequest__c> updated = [
            SELECT EPA_Status__c, EPA_CancellationTimestamp__c
            FROM EPA_StudyLeaveRequest__c
            WHERE Id IN :bulkIds
        ];
        Assert.areEqual(33, updated.size(), 'All 33 records should be returned');
        for (EPA_StudyLeaveRequest__c rec : updated) {
            Assert.areEqual('Cancelled', rec.EPA_Status__c, 'All records should be Cancelled');
            Assert.isNotNull(rec.EPA_CancellationTimestamp__c, 'All records should have cancellation timestamp');
        }
    }
}
