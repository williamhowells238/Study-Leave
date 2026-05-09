/**
 * @description: Service class providing the cancel action for approved study leave requests.
 *               Enforces security checks (apprentice identity, approved status) and records cancellation timestamp.
 * @author: Developer Agent
 * @date: 2026-05-08
 */
public with sharing class EPA_CancelRequest_Class {

    /**
     * @description: Cancels an approved study leave request. Validates the logged-in user is
     *               the owning apprentice and the request is in Approved status. Sets status to
     *               Cancelled and populates the cancellation timestamp.
     * @param requestId The Id of the EPA_StudyLeaveRequest__c record to cancel.
     * @return void
     */
    @AuraEnabled
    public static void cancelRequest(Id requestId) {
        List<EPA_StudyLeaveRequest__c> requests = [
            SELECT Id, EPA_Status__c, EPA_Apprentice__c, EPA_CancellationTimestamp__c
            FROM EPA_StudyLeaveRequest__c
            WHERE Id = :requestId
            WITH USER_MODE
            LIMIT 1
        ];

        if (requests.isEmpty()) {
            throw buildException('Study leave request not found.');
        }

        EPA_StudyLeaveRequest__c request = requests[0];

        if (request.EPA_Apprentice__c != UserInfo.getUserId()) {
            throw buildException('You are not authorised to cancel this request. Only the requesting apprentice can cancel.');
        }

        if (request.EPA_Status__c != 'Approved') {
            throw buildException('Only requests with Approved status can be cancelled. Current status: ' + request.EPA_Status__c);
        }

        request.EPA_Status__c = 'Cancelled';
        request.EPA_CancellationTimestamp__c = Datetime.now();
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
