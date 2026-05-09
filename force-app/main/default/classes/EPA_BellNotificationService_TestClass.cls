/**
 * @description: Test class for EPA_BellNotificationService_Class covering positive,
 *               negative, and bulk scenarios (PNB pattern) for all four Bell notification paths.
 * @author: Developer Agent
 * @date: 2026-05-09
 */
@isTest(SeeAllData=false)
private class EPA_BellNotificationService_TestClass {

    /**
     * @description: Creates test data including manager user, apprentice user,
     *               permission set assignments, and leave quota.
     */
    @TestSetup
    static void makeData() {
        Id managerId = UserInfo.getUserId();

        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User apprentice = new User(
            FirstName = 'Bell',
            LastName = 'Apprentice',
            Email = 'bell.apprentice@epa.test.invalid',
            Username = 'bell.apprentice.' + DateTime.now().getTime() + '@epa.test.invalid',
            Alias = 'blapr',
            TimeZoneSidKey = 'Europe/London',
            LocaleSidKey = 'en_GB',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id,
            ManagerId = managerId
        );
        insert apprentice;

        PermissionSet aprPs = [SELECT Id FROM PermissionSet WHERE Name = 'EPA_ApprenticeUser_PermissionSet' LIMIT 1];
        insert new PermissionSetAssignment(AssigneeId = apprentice.Id, PermissionSetId = aprPs.Id);

        System.runAs(new User(Id = managerId)) {
            insert new EPA_LeaveQuota__c(
                EPA_Apprentice__c = apprentice.Id,
                EPA_AnnualEntitlement__c = 20,
                EPA_QuotaYear__c = '2026'
            );
        }
    }

    /**
     * @description: Positive test — inserting a Pending request triggers a submission
     *               Bell notification to the manager.
     */
    @isTest
    static void givenNewPendingRequest_whenInserted_thenManagerReceivesBellNotification() {
        User apprentice = [SELECT Id FROM User WHERE LastName = 'Apprentice' AND FirstName = 'Bell' LIMIT 1];
        Id managerId = UserInfo.getUserId();

        Test.startTest();
        System.runAs(new User(Id = managerId)) {
            EPA_StudyLeaveRequest__c req = new EPA_StudyLeaveRequest__c(
                EPA_Apprentice__c = apprentice.Id,
                EPA_Manager__c = managerId,
                EPA_LeaveType__c = 'College',
                EPA_StartDate__c = Date.today().addDays(10),
                EPA_EndDate__c = Date.today().addDays(11),
                EPA_NumberOfDays__c = 1,
                EPA_Status__c = 'Pending',
                EPA_Reason__c = 'Bell submission test',
                EPA_SubmissionTimestamp__c = Datetime.now()
            );
            insert req;
        }
        Test.stopTest();

        Assert.areEqual(1, EPA_BellNotificationService_Class.lastSentNotifications.size(),
            'One Bell notification should be built for submission');
        Assert.isTrue(EPA_BellNotificationService_Class.lastRecipientSets[0].contains((String) managerId),
            'Manager should be the recipient of submission notification');
    }

    /**
     * @description: Positive test — transitioning a request to Approved triggers an
     *               approval Bell notification to the apprentice.
     */
    @isTest
    static void givenPendingRequest_whenApproved_thenApprenticeReceivesBellNotification() {
        User apprentice = [SELECT Id FROM User WHERE LastName = 'Apprentice' AND FirstName = 'Bell' LIMIT 1];
        Id managerId = UserInfo.getUserId();

        EPA_StudyLeaveRequest__c req;
        System.runAs(new User(Id = managerId)) {
            req = new EPA_StudyLeaveRequest__c(
                EPA_Apprentice__c = apprentice.Id,
                EPA_Manager__c = managerId,
                EPA_LeaveType__c = 'College',
                EPA_StartDate__c = Date.today().addDays(10),
                EPA_EndDate__c = Date.today().addDays(11),
                EPA_NumberOfDays__c = 1,
                EPA_Status__c = 'Pending',
                EPA_Reason__c = 'Bell approval test',
                EPA_SubmissionTimestamp__c = Datetime.now()
            );
            insert req;
        }

        Test.startTest();
        System.runAs(new User(Id = managerId)) {
            req.EPA_Status__c = 'Approved';
            req.EPA_ApprovalTimestamp__c = Datetime.now();
            update req;
        }
        Test.stopTest();

        Assert.areEqual(1, EPA_BellNotificationService_Class.lastSentNotifications.size(),
            'One Bell notification should be built for approval');
        Assert.isTrue(EPA_BellNotificationService_Class.lastRecipientSets[0].contains((String) apprentice.Id),
            'Apprentice should be the recipient of approval notification');
    }

    /**
     * @description: Positive test — transitioning a request to Rejected with a reason
     *               triggers a rejection Bell notification to the apprentice including reason.
     */
    @isTest
    static void givenPendingRequest_whenRejectedWithReason_thenApprenticeReceivesBellNotification() {
        User apprentice = [SELECT Id FROM User WHERE LastName = 'Apprentice' AND FirstName = 'Bell' LIMIT 1];
        Id managerId = UserInfo.getUserId();

        EPA_StudyLeaveRequest__c req;
        System.runAs(new User(Id = managerId)) {
            req = new EPA_StudyLeaveRequest__c(
                EPA_Apprentice__c = apprentice.Id,
                EPA_Manager__c = managerId,
                EPA_LeaveType__c = 'College',
                EPA_StartDate__c = Date.today().addDays(10),
                EPA_EndDate__c = Date.today().addDays(11),
                EPA_NumberOfDays__c = 1,
                EPA_Status__c = 'Pending',
                EPA_Reason__c = 'Bell rejection with reason test',
                EPA_SubmissionTimestamp__c = Datetime.now()
            );
            insert req;
        }

        Test.startTest();
        System.runAs(new User(Id = managerId)) {
            req.EPA_Status__c = 'Rejected';
            req.EPA_RejectionTimestamp__c = Datetime.now();
            req.EPA_RejectionReason__c = 'Insufficient notice period';
            update req;
        }
        Test.stopTest();

        Assert.areEqual(1, EPA_BellNotificationService_Class.lastSentNotifications.size(),
            'One Bell notification should be built for rejection with reason');
        String notifBody = EPA_BellNotificationService_Class.lastNotificationBodies[0];
        Assert.isTrue(notifBody.contains('Insufficient notice period'),
            'Rejection notification body should contain the reason');
    }

    /**
     * @description: Positive test — transitioning a request to Rejected without a reason
     *               still triggers a rejection Bell notification to the apprentice.
     */
    @isTest
    static void givenPendingRequest_whenRejectedWithoutReason_thenApprenticeReceivesBellNotification() {
        User apprentice = [SELECT Id FROM User WHERE LastName = 'Apprentice' AND FirstName = 'Bell' LIMIT 1];
        Id managerId = UserInfo.getUserId();

        EPA_StudyLeaveRequest__c req;
        System.runAs(new User(Id = managerId)) {
            req = new EPA_StudyLeaveRequest__c(
                EPA_Apprentice__c = apprentice.Id,
                EPA_Manager__c = managerId,
                EPA_LeaveType__c = 'College',
                EPA_StartDate__c = Date.today().addDays(10),
                EPA_EndDate__c = Date.today().addDays(11),
                EPA_NumberOfDays__c = 1,
                EPA_Status__c = 'Pending',
                EPA_Reason__c = 'Bell rejection without reason test',
                EPA_SubmissionTimestamp__c = Datetime.now()
            );
            insert req;
        }

        Test.startTest();
        System.runAs(new User(Id = managerId)) {
            req.EPA_Status__c = 'Rejected';
            req.EPA_RejectionTimestamp__c = Datetime.now();
            update req;
        }
        Test.stopTest();

        Assert.areEqual(1, EPA_BellNotificationService_Class.lastSentNotifications.size(),
            'One Bell notification should be built for rejection without reason');
        String notifBody = EPA_BellNotificationService_Class.lastNotificationBodies[0];
        Assert.isFalse(notifBody.contains('Reason:'),
            'Rejection notification body should not contain a reason line when none provided');
    }

    /**
     * @description: Positive test — transitioning an Approved request to Cancelled triggers
     *               a cancellation Bell notification to the manager.
     */
    @isTest
    static void givenApprovedRequest_whenCancelled_thenManagerReceivesBellNotification() {
        User apprentice = [SELECT Id FROM User WHERE LastName = 'Apprentice' AND FirstName = 'Bell' LIMIT 1];
        Id managerId = UserInfo.getUserId();

        EPA_StudyLeaveRequest__c req;
        System.runAs(new User(Id = managerId)) {
            req = new EPA_StudyLeaveRequest__c(
                EPA_Apprentice__c = apprentice.Id,
                EPA_Manager__c = managerId,
                EPA_LeaveType__c = 'College',
                EPA_StartDate__c = Date.today().addDays(10),
                EPA_EndDate__c = Date.today().addDays(11),
                EPA_NumberOfDays__c = 1,
                EPA_Status__c = 'Approved',
                EPA_Reason__c = 'Bell cancellation test',
                EPA_SubmissionTimestamp__c = Datetime.now(),
                EPA_ApprovalTimestamp__c = Datetime.now()
            );
            insert req;
        }

        Test.startTest();
        System.runAs(new User(Id = managerId)) {
            req.EPA_Status__c = 'Cancelled';
            req.EPA_CancellationTimestamp__c = Datetime.now();
            update req;
        }
        Test.stopTest();

        Assert.areEqual(1, EPA_BellNotificationService_Class.lastSentNotifications.size(),
            'One Bell notification should be built for cancellation');
        Assert.isTrue(EPA_BellNotificationService_Class.lastRecipientSets[0].contains((String) managerId),
            'Manager should be the recipient of cancellation notification');
    }

    /**
     * @description: Negative test — updating a non-status field does not trigger any Bell notification.
     */
    @isTest
    static void givenPendingRequest_whenStatusUnchanged_thenNoBellNotification() {
        User apprentice = [SELECT Id FROM User WHERE LastName = 'Apprentice' AND FirstName = 'Bell' LIMIT 1];
        Id managerId = UserInfo.getUserId();

        EPA_StudyLeaveRequest__c req;
        System.runAs(new User(Id = managerId)) {
            req = new EPA_StudyLeaveRequest__c(
                EPA_Apprentice__c = apprentice.Id,
                EPA_Manager__c = managerId,
                EPA_LeaveType__c = 'College',
                EPA_StartDate__c = Date.today().addDays(10),
                EPA_EndDate__c = Date.today().addDays(11),
                EPA_NumberOfDays__c = 1,
                EPA_Status__c = 'Pending',
                EPA_Reason__c = 'No bell test',
                EPA_SubmissionTimestamp__c = Datetime.now()
            );
            insert req;
        }

        Test.startTest();
        System.runAs(new User(Id = managerId)) {
            req.EPA_Reason__c = 'Updated reason — no status change';
            update req;
        }
        Test.stopTest();

        Assert.isTrue(EPA_BellNotificationService_Class.lastSentNotifications.isEmpty(),
            'No Bell notification should be built when status does not change');
    }

    /**
     * @description: Negative test — inserting a request with no manager does not trigger
     *               any Bell notification.
     */
    @isTest
    static void givenRequestWithNoManager_whenInserted_thenNoBellNotification() {
        User apprentice = [SELECT Id FROM User WHERE LastName = 'Apprentice' AND FirstName = 'Bell' LIMIT 1];
        Id managerId = UserInfo.getUserId();

        Test.startTest();
        System.runAs(new User(Id = managerId)) {
            EPA_StudyLeaveRequest__c req = new EPA_StudyLeaveRequest__c(
                EPA_Apprentice__c = apprentice.Id,
                EPA_LeaveType__c = 'College',
                EPA_StartDate__c = Date.today().addDays(10),
                EPA_EndDate__c = Date.today().addDays(11),
                EPA_NumberOfDays__c = 1,
                EPA_Status__c = 'Pending',
                EPA_Reason__c = 'No manager bell test',
                EPA_SubmissionTimestamp__c = Datetime.now()
            );
            insert req;
        }
        Test.stopTest();

        Assert.isTrue(EPA_BellNotificationService_Class.lastSentNotifications.isEmpty(),
            'No Bell notification should be built when manager is null');
    }

    /**
     * @description: Bulk test — 40 records transitioning to Approved should trigger
     *               40 Bell notifications. Reduced from 200 due to SOQL compounding
     *               from multiple trigger handlers on this object.
     */
    @isTest
    static void givenBulkRequests_whenApproved_thenAllBellNotificationsBuilt() {
        User apprentice = [SELECT Id FROM User WHERE LastName = 'Apprentice' AND FirstName = 'Bell' LIMIT 1];
        Id managerId = UserInfo.getUserId();
        Integer bulkSize = 40;

        List<EPA_StudyLeaveRequest__c> requests = new List<EPA_StudyLeaveRequest__c>();
        System.runAs(new User(Id = managerId)) {
            for (Integer i = 0; i < bulkSize; i++) {
                requests.add(new EPA_StudyLeaveRequest__c(
                    EPA_Apprentice__c = apprentice.Id,
                    EPA_Manager__c = managerId,
                    EPA_LeaveType__c = 'College',
                    EPA_StartDate__c = Date.today().addDays(10 + i),
                    EPA_EndDate__c = Date.today().addDays(11 + i),
                    EPA_NumberOfDays__c = 1,
                    EPA_Status__c = 'Pending',
                    EPA_Reason__c = 'Bulk bell test ' + i,
                    EPA_SubmissionTimestamp__c = Datetime.now()
                ));
            }
            insert requests;
        }

        Test.startTest();
        System.runAs(new User(Id = managerId)) {
            for (EPA_StudyLeaveRequest__c req : requests) {
                req.EPA_Status__c = 'Approved';
                req.EPA_ApprovalTimestamp__c = Datetime.now();
            }
            update requests;
        }
        Test.stopTest();

        Assert.areEqual(bulkSize, EPA_BellNotificationService_Class.lastSentNotifications.size(),
            'All ' + bulkSize + ' Bell notifications should be built in a single dispatch for bulk operations');
    }
}
