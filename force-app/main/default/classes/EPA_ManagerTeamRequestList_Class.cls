/**
 * @description: Controller class for the Manager Team Request List LWC.
 *               Returns study leave requests for the current manager's direct reports.
 * @author: Developer Agent
 * @date: 2026-05-08
 */
public with sharing class EPA_ManagerTeamRequestList_Class {

    /**
     * @description: Retrieves study leave requests belonging to the current manager's
     *               direct reports, optionally filtered by status.
     * @param statusFilter Optional status value to filter requests (e.g. 'Pending', 'Approved').
     *                     Pass null or empty string to return all statuses.
     * @return List of EPA_StudyLeaveRequest__c records for the manager's direct reports.
     */
    @AuraEnabled(cacheable=true)
    public static List<EPA_StudyLeaveRequest__c> getTeamRequests(String statusFilter) {
        List<Id> directReportIds = new List<Id>();
        for (User u : [SELECT Id FROM User WHERE ManagerId = :UserInfo.getUserId() WITH USER_MODE]) {
            directReportIds.add(u.Id);
        }

        if (directReportIds.isEmpty()) {
            return new List<EPA_StudyLeaveRequest__c>();
        }

        if (String.isNotBlank(statusFilter)) {
            return [
                SELECT Id,
                       Name,
                       EPA_Apprentice__r.Name,
                       EPA_LeaveType__c,
                       EPA_StartDate__c,
                       EPA_EndDate__c,
                       EPA_NumberOfDays__c,
                       EPA_Status__c
                FROM EPA_StudyLeaveRequest__c
                WHERE EPA_Apprentice__c IN :directReportIds
                  AND EPA_Status__c = :statusFilter
                WITH USER_MODE
                ORDER BY EPA_StartDate__c DESC
            ];
        }

        return [
            SELECT Id,
                   Name,
                   EPA_Apprentice__r.Name,
                   EPA_LeaveType__c,
                   EPA_StartDate__c,
                   EPA_EndDate__c,
                   EPA_NumberOfDays__c,
                   EPA_Status__c
            FROM EPA_StudyLeaveRequest__c
            WHERE EPA_Apprentice__c IN :directReportIds
            WITH USER_MODE
            ORDER BY EPA_StartDate__c DESC
        ];
    }
}
