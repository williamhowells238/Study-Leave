/**
 * @description: Service class providing approve and reject actions for study leave requests.
 *               Enforces security checks (manager identity, pending status) and records audit timestamps.
 * @author: Developer Agent
 * @date: 2026-05-08
 */
public with sharing class EPA_ApproveRejectRequest_Class {

    /**
     * @description: Approves a pending study leave request. Validates the logged-in user is
     *               the assigned manager and the request is in Pending status.
     * @param requestId The Id of the EPA_StudyLeaveRequest__c record to approve.
     * @return void
     */
    @AuraEnabled
    public static void approveRequest(Id requestId) {
        List<EPA_StudyLeaveRequest__c> requests = [
            SELECT Id, EPA_Status__c, EPA_Manager__c, EPA_ApprovalTimestamp__c
            FROM EPA_StudyLeaveRequest__c
            WHERE Id = :requestId
            WITH USER_MODE
            LIMIT 1
        ];

        if (requests.isEmpty()) {
            throw buildException('Study leave request not found.');
        }

        EPA_StudyLeaveRequest__c request = requests[0];

        if (request.EPA_Manager__c != UserInfo.getUserId()) {
            throw buildException('You are not authorised to approve this request. Only the assigned manager can approve.');
        }

        if (request.EPA_Status__c != 'Pending') {
            throw buildException('Only requests with Pending status can be approved. Current status: ' + request.EPA_Status__c);
        }

        request.EPA_Status__c = 'Approved';
        request.EPA_ApprovalTimestamp__c = Datetime.now();
        update request;
    }

    /**
     * @description: Rejects a pending study leave request with an optional rejection reason.
     *               Validates the logged-in user is the assigned manager and the request is in Pending status.
     * @param requestId The Id of the EPA_StudyLeaveRequest__c record to reject.
     * @param rejectionReason Optional reason for the rejection.
     * @return void
     */
    @AuraEnabled
    public static void rejectRequest(Id requestId, String rejectionReason) {
        List<EPA_StudyLeaveRequest__c> requests = [
            SELECT Id, EPA_Status__c, EPA_Manager__c, EPA_RejectionTimestamp__c, EPA_RejectionReason__c
            FROM EPA_StudyLeaveRequest__c
            WHERE Id = :requestId
            WITH USER_MODE
            LIMIT 1
        ];

        if (requests.isEmpty()) {
            throw buildException('Study leave request not found.');
        }

        EPA_StudyLeaveRequest__c request = requests[0];

        if (request.EPA_Manager__c != UserInfo.getUserId()) {
            throw buildException('You are not authorised to reject this request. Only the assigned manager can reject.');
        }

        if (request.EPA_Status__c != 'Pending') {
            throw buildException('Only requests with Pending status can be rejected. Current status: ' + request.EPA_Status__c);
        }

        request.EPA_Status__c = 'Rejected';
        request.EPA_RejectionTimestamp__c = Datetime.now();
        request.EPA_RejectionReason__c = rejectionReason;
        update request;
    }

    /**
     * @description: Builds an AuraHandledException with the message accessible in test context.
     * @param message The error message.
     * @return AuraHandledException with message set.
     */
    private static AuraHandledException buildException(String message) {
        AuraHandledException ex = new AuraHandledException(message);
        ex.setMessage(message);
        return ex;
    }
}
