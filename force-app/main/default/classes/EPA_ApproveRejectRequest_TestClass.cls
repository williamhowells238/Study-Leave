/**
 * @description: Test class for EPA_ApproveRejectRequest_Class covering positive,
 *               negative, and bulk scenarios (PNB pattern).
 * @author: Developer Agent
 * @date: 2026-05-08
 */
@isTest(SeeAllData=false)
private class EPA_ApproveRejectRequest_TestClass {

    /**
     * @description: Creates test data including manager, apprentice, and non-manager users,
     *               along with pending study leave requests assigned to the manager.
     */
    @TestSetup
    static void makeData() {
        Id managerId = UserInfo.getUserId();

        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        // Create apprentice user (direct report of running user)
        User apprentice = new User(
            FirstName = 'Test',
            LastName = 'Apprentice',
            Email = 'test.apprentice@epa.test.invalid',
            Username = 'test.apprentice.' + DateTime.now().getTime() + '@epa.test.invalid',
            Alias = 'tstapr',
            TimeZoneSidKey = 'Europe/London',
            LocaleSidKey = 'en_GB',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id,
            ManagerId = managerId
        );
        insert apprentice;

        // Create non-manager user (not linked as manager to any request)
        User nonManager = new User(
            FirstName = 'Non',
            LastName = 'Manager',
            Email = 'non.manager@epa.test.invalid',
            Username = 'non.manager.' + DateTime.now().getTime() + '@epa.test.invalid',
            Alias = 'nonmgr',
            TimeZoneSidKey = 'Europe/London',
            LocaleSidKey = 'en_GB',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );
        insert nonManager;

        // Assign manager permission set to non-manager so they have object access
        PermissionSet mgrPs = [SELECT Id FROM PermissionSet WHERE Name = 'EPA_ManagerUser_PermissionSet' LIMIT 1];
        insert new PermissionSetAssignment(AssigneeId = nonManager.Id, PermissionSetId = mgrPs.Id);

        // Use System.runAs to avoid Mixed DML error between setup and non-setup objects
        System.runAs(new User(Id = managerId)) {
            // Create leave quota for apprentice
            insert new EPA_LeaveQuota__c(
                EPA_Apprentice__c = apprentice.Id,
                EPA_AnnualEntitlement__c = 20,
                EPA_QuotaYear__c = '2026'
            );

            // Create Pending study leave requests (manager is the running user)
            List<EPA_StudyLeaveRequest__c> requests = new List<EPA_StudyLeaveRequest__c>();
            Datetime now = Datetime.now();
            for (Integer i = 0; i < 5; i++) {
                requests.add(new EPA_StudyLeaveRequest__c(
                    EPA_Apprentice__c = apprentice.Id,
                    EPA_Manager__c = managerId,
                    EPA_LeaveType__c = 'College',
                    EPA_StartDate__c = Date.today().addDays(10 + i),
                    EPA_EndDate__c = Date.today().addDays(11 + i),
                    EPA_NumberOfDays__c = 1,
                    EPA_Status__c = 'Pending',
                    EPA_Reason__c = 'Test reason ' + i,
                    EPA_SubmissionTimestamp__c = now
                ));
            }
            insert requests;

            // Grant non-manager Read access via manual sharing so the manager identity check is tested
            List<EPA_StudyLeaveRequest__Share> nonManagerShares = new List<EPA_StudyLeaveRequest__Share>();
            for (EPA_StudyLeaveRequest__c req : requests) {
                nonManagerShares.add(new EPA_StudyLeaveRequest__Share(
                    ParentId = req.Id,
                    UserOrGroupId = nonManager.Id,
                    AccessLevel = 'Edit',
                    RowCause = Schema.EPA_StudyLeaveRequest__Share.RowCause.Manual
                ));
            }
            insert nonManagerShares;
        }
    }

    /**
     * @description: Positive test - approve a pending request as the correct manager.
     *               Asserts status transitions to Approved and timestamp is populated.
     */
    @isTest
    static void givenPendingRequest_whenApproveByManager_thenStatusApprovedAndTimestampSet() {
        EPA_StudyLeaveRequest__c request = [
            SELECT Id FROM EPA_StudyLeaveRequest__c WHERE EPA_Status__c = 'Pending' LIMIT 1
        ];

        Test.startTest();
        EPA_ApproveRejectRequest_Class.approveRequest(request.Id);
        Test.stopTest();

        EPA_StudyLeaveRequest__c updated = [
            SELECT EPA_Status__c, EPA_ApprovalTimestamp__c
            FROM EPA_StudyLeaveRequest__c
            WHERE Id = :request.Id
        ];
        Assert.areEqual('Approved', updated.EPA_Status__c, 'Status should be Approved');
        Assert.isNotNull(updated.EPA_ApprovalTimestamp__c, 'Approval timestamp should be set');
    }

    /**
     * @description: Positive test - reject a pending request with a reason.
     *               Asserts status transitions to Rejected, timestamp and reason are populated.
     */
    @isTest
    static void givenPendingRequest_whenRejectWithReason_thenStatusRejectedAndReasonStored() {
        EPA_StudyLeaveRequest__c request = [
            SELECT Id FROM EPA_StudyLeaveRequest__c WHERE EPA_Status__c = 'Pending' LIMIT 1
        ];

        Test.startTest();
        EPA_ApproveRejectRequest_Class.rejectRequest(request.Id, 'Insufficient notice period');
        Test.stopTest();

        EPA_StudyLeaveRequest__c updated = [
            SELECT EPA_Status__c, EPA_RejectionTimestamp__c, EPA_RejectionReason__c
            FROM EPA_StudyLeaveRequest__c
            WHERE Id = :request.Id
        ];
        Assert.areEqual('Rejected', updated.EPA_Status__c, 'Status should be Rejected');
        Assert.isNotNull(updated.EPA_RejectionTimestamp__c, 'Rejection timestamp should be set');
        Assert.areEqual('Insufficient notice period', updated.EPA_RejectionReason__c, 'Rejection reason should be stored');
    }

    /**
     * @description: Positive test - reject a pending request without a reason.
     *               Asserts status transitions to Rejected, timestamp set, reason is null.
     */
    @isTest
    static void givenPendingRequest_whenRejectWithoutReason_thenStatusRejectedAndReasonNull() {
        EPA_StudyLeaveRequest__c request = [
            SELECT Id FROM EPA_StudyLeaveRequest__c WHERE EPA_Status__c = 'Pending' LIMIT 1
        ];

        Test.startTest();
        EPA_ApproveRejectRequest_Class.rejectRequest(request.Id, null);
        Test.stopTest();

        EPA_StudyLeaveRequest__c updated = [
            SELECT EPA_Status__c, EPA_RejectionTimestamp__c, EPA_RejectionReason__c
            FROM EPA_StudyLeaveRequest__c
            WHERE Id = :request.Id
        ];
        Assert.areEqual('Rejected', updated.EPA_Status__c, 'Status should be Rejected');
        Assert.isNotNull(updated.EPA_RejectionTimestamp__c, 'Rejection timestamp should be set');
        Assert.isNull(updated.EPA_RejectionReason__c, 'Rejection reason should be null when not provided');
    }

    /**
     * @description: Negative test - attempt to approve a request as a non-manager user.
     *               Asserts AuraHandledException is thrown.
     */
    @isTest
    static void givenPendingRequest_whenApproveByNonManager_thenExceptionThrown() {
        EPA_StudyLeaveRequest__c request = [
            SELECT Id FROM EPA_StudyLeaveRequest__c WHERE EPA_Status__c = 'Pending' LIMIT 1
        ];

        User nonManager = [SELECT Id FROM User WHERE LastName = 'Manager' AND FirstName = 'Non' LIMIT 1];

        String exceptionMessage;
        Test.startTest();
        System.runAs(nonManager) {
            try {
                EPA_ApproveRejectRequest_Class.approveRequest(request.Id);
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
        Assert.areEqual('Pending', unchanged.EPA_Status__c, 'Status should remain Pending after failed attempt');
    }

    /**
     * @description: Negative test - attempt to approve an already Approved request.
     *               Asserts AuraHandledException is thrown.
     */
    @isTest
    static void givenApprovedRequest_whenApproveAgain_thenExceptionThrown() {
        EPA_StudyLeaveRequest__c request = [
            SELECT Id FROM EPA_StudyLeaveRequest__c WHERE EPA_Status__c = 'Pending' LIMIT 1
        ];

        // First approve it
        EPA_ApproveRejectRequest_Class.approveRequest(request.Id);

        String exceptionMessage;
        Test.startTest();
        try {
            EPA_ApproveRejectRequest_Class.approveRequest(request.Id);
            Assert.fail('Expected AuraHandledException was not thrown');
        } catch (AuraHandledException e) {
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();

        Assert.isTrue(
            exceptionMessage != null && exceptionMessage.contains('Pending'),
            'Exception message should indicate only Pending records can be approved'
        );
    }

    /**
     * @description: Bulk test - approve 33 pending requests in a single transaction.
     *               Asserts all records transition correctly without governor limit issues.
     *               Uses 33 records as each call performs 1 SOQL + 1 DML with trigger
     *               handlers consuming additional SOQL (balance + notification).
     */
    @isTest
    static void givenBulkPendingRequests_whenApproveAll_thenAllTransitionCorrectly() {
        Id managerId = UserInfo.getUserId();
        User apprentice = [SELECT Id FROM User WHERE LastName = 'Apprentice' AND FirstName = 'Test' LIMIT 1];

        // Create 33 Pending requests for bulk test
        List<EPA_StudyLeaveRequest__c> bulkRequests = new List<EPA_StudyLeaveRequest__c>();
        Datetime now = Datetime.now();
        for (Integer i = 0; i < 33; i++) {
            bulkRequests.add(new EPA_StudyLeaveRequest__c(
                EPA_Apprentice__c = apprentice.Id,
                EPA_Manager__c = managerId,
                EPA_LeaveType__c = 'College',
                EPA_StartDate__c = Date.today().addDays(50 + i),
                EPA_EndDate__c = Date.today().addDays(51 + i),
                EPA_NumberOfDays__c = 1,
                EPA_Status__c = 'Pending',
                EPA_Reason__c = 'Bulk test ' + i,
                EPA_SubmissionTimestamp__c = now
            ));
        }
        insert bulkRequests;

        Set<Id> bulkIds = new Map<Id, EPA_StudyLeaveRequest__c>(bulkRequests).keySet();

        Test.startTest();
        for (EPA_StudyLeaveRequest__c req : bulkRequests) {
            EPA_ApproveRejectRequest_Class.approveRequest(req.Id);
        }
        Test.stopTest();

        List<EPA_StudyLeaveRequest__c> updated = [
            SELECT EPA_Status__c, EPA_ApprovalTimestamp__c
            FROM EPA_StudyLeaveRequest__c
            WHERE Id IN :bulkIds
        ];
        Assert.areEqual(33, updated.size(), 'All 33 records should be returned');
        for (EPA_StudyLeaveRequest__c rec : updated) {
            Assert.areEqual('Approved', rec.EPA_Status__c, 'All records should be Approved');
            Assert.isNotNull(rec.EPA_ApprovalTimestamp__c, 'All records should have approval timestamp');
        }
    }
}
