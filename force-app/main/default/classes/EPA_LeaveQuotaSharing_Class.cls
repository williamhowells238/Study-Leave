/**
 * @description: Handler class for Apex Managed Sharing on EPA_LeaveQuota__c.
 *               Creates, updates, and deletes share records to grant the apprentice's manager
 *               Read access using the EPA_ManagerAccess__c row cause.
 * @author: Developer Agent
 * @date: 2026-05-08
 */
public with sharing class EPA_LeaveQuotaSharing_Class {

    /**
     * @description: Handles after-insert events. Queries the ManagerId for each apprentice
     *               and creates share records granting Read access to their manager.
     * @param newRecords List of newly inserted EPA_LeaveQuota__c records
     * @return void
     */
    public static void handleAfterInsert(List<EPA_LeaveQuota__c> newRecords) {
        Set<Id> apprenticeIds = new Set<Id>();
        for (EPA_LeaveQuota__c quota : newRecords) {
            if (quota.EPA_Apprentice__c != null) {
                apprenticeIds.add(quota.EPA_Apprentice__c);
            }
        }

        if (apprenticeIds.isEmpty()) {
            return;
        }

        Map<Id, Id> apprenticeToManagerMap = getApprenticeManagerMap(apprenticeIds);
        List<EPA_LeaveQuota__Share> sharesToInsert = new List<EPA_LeaveQuota__Share>();

        for (EPA_LeaveQuota__c quota : newRecords) {
            if (quota.EPA_Apprentice__c != null && apprenticeToManagerMap.containsKey(quota.EPA_Apprentice__c)) {
                Id managerId = apprenticeToManagerMap.get(quota.EPA_Apprentice__c);
                if (managerId != null) {
                    sharesToInsert.add(createShareRecord(quota.Id, managerId));
                }
            }
        }

        if (!sharesToInsert.isEmpty()) {
            Database.insert(sharesToInsert, false);
        }
    }

    /**
     * @description: Handles after-update events. Detects changes to EPA_Apprentice__c and
     *               recalculates share records accordingly.
     * @param newRecords List of updated EPA_LeaveQuota__c records (new values)
     * @param oldMap Map of old record values keyed by Id
     * @return void
     */
    public static void handleAfterUpdate(List<EPA_LeaveQuota__c> newRecords, Map<Id, EPA_LeaveQuota__c> oldMap) {
        Set<Id> apprenticeIds = new Set<Id>();
        Set<Id> recordIdsWithApprenticeChange = new Set<Id>();

        for (EPA_LeaveQuota__c quota : newRecords) {
            EPA_LeaveQuota__c oldQuota = oldMap.get(quota.Id);
            if (quota.EPA_Apprentice__c != oldQuota.EPA_Apprentice__c) {
                recordIdsWithApprenticeChange.add(quota.Id);
                if (quota.EPA_Apprentice__c != null) {
                    apprenticeIds.add(quota.EPA_Apprentice__c);
                }
            }
        }

        if (recordIdsWithApprenticeChange.isEmpty()) {
            return;
        }

        deleteExistingShares(recordIdsWithApprenticeChange);

        if (apprenticeIds.isEmpty()) {
            return;
        }

        Map<Id, Id> apprenticeToManagerMap = getApprenticeManagerMap(apprenticeIds);
        List<EPA_LeaveQuota__Share> sharesToInsert = new List<EPA_LeaveQuota__Share>();

        for (EPA_LeaveQuota__c quota : newRecords) {
            if (recordIdsWithApprenticeChange.contains(quota.Id)
                && quota.EPA_Apprentice__c != null
                && apprenticeToManagerMap.containsKey(quota.EPA_Apprentice__c)) {
                Id managerId = apprenticeToManagerMap.get(quota.EPA_Apprentice__c);
                if (managerId != null) {
                    sharesToInsert.add(createShareRecord(quota.Id, managerId));
                }
            }
        }

        if (!sharesToInsert.isEmpty()) {
            Database.insert(sharesToInsert, false);
        }
    }

    /**
     * @description: Queries User records to build a map of apprentice ID to their manager ID.
     * @param apprenticeIds Set of User IDs for the apprentices
     * @return Map<Id, Id> Map of apprentice User ID to Manager User ID
     */
    private static Map<Id, Id> getApprenticeManagerMap(Set<Id> apprenticeIds) {
        Map<Id, Id> apprenticeToManagerMap = new Map<Id, Id>();
        for (User u : [SELECT Id, ManagerId FROM User WHERE Id IN :apprenticeIds]) {
            apprenticeToManagerMap.put(u.Id, u.ManagerId);
        }
        return apprenticeToManagerMap;
    }

    /**
     * @description: Creates a share record granting Read access to the specified manager user.
     * @param recordId The Id of the EPA_LeaveQuota__c record
     * @param managerId The Id of the manager User to grant access
     * @return EPA_LeaveQuota__Share The share record to insert
     */
    private static EPA_LeaveQuota__Share createShareRecord(Id recordId, Id managerId) {
        EPA_LeaveQuota__Share shareRecord = new EPA_LeaveQuota__Share();
        shareRecord.ParentId = recordId;
        shareRecord.UserOrGroupId = managerId;
        shareRecord.AccessLevel = 'Read';
        shareRecord.RowCause = Schema.EPA_LeaveQuota__Share.RowCause.EPA_ManagerAccess__c;
        return shareRecord;
    }

    /**
     * @description: Deletes existing Apex-managed share records for the given record IDs
     *               using the EPA_ManagerAccess__c row cause.
     * @param recordIds Set of EPA_LeaveQuota__c record IDs to remove shares for
     * @return void
     */
    private static void deleteExistingShares(Set<Id> recordIds) {
        List<EPA_LeaveQuota__Share> existingShares = [
            SELECT Id
            FROM EPA_LeaveQuota__Share
            WHERE ParentId IN :recordIds
            AND RowCause = :Schema.EPA_LeaveQuota__Share.RowCause.EPA_ManagerAccess__c
        ];
        if (!existingShares.isEmpty()) {
            Database.delete(existingShares, false);
        }
    }
}
