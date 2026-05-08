/**
 * @description: Controller class for the Apprentice Request List LWC.
 *               Returns the current user's study leave requests for display.
 * @author: Developer Agent
 * @date: 2026-05-08
 */
public with sharing class EPA_ApprenticeRequestList_Class {

    /**
     * @description: Retrieves all study leave requests belonging to the current user,
     *               ordered by start date descending.
     * @return List of EPA_StudyLeaveRequest__c records for the running user.
     */
    @AuraEnabled(cacheable=true)
    public static List<EPA_StudyLeaveRequest__c> getMyRequests() {
        return [
            SELECT Id,
                   Name,
                   EPA_LeaveType__c,
                   EPA_StartDate__c,
                   EPA_EndDate__c,
                   EPA_NumberOfDays__c,
                   EPA_Status__c,
                   EPA_Reason__c,
                   EPA_RejectionReason__c
            FROM EPA_StudyLeaveRequest__c
            WHERE EPA_Apprentice__c = :UserInfo.getUserId()
            WITH USER_MODE
            ORDER BY EPA_StartDate__c DESC
        ];
    }
}
