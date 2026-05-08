/**
 * @description: Handler class for Apex Managed Sharing on EPA_StudyLeaveRequest__c.
 *               Creates, updates, and deletes share records to grant the assigned manager
 *               Edit access using the EPA_ManagerAccess__c row cause.
 * @author: Developer Agent
 * @date: 2026-05-08
 */
public with sharing class EPA_StudyLeaveRequestSharing_Class {

    /**
     * @description: Handles after-insert events. Creates share records for each new request
     *               that has a manager assigned.
     * @param newRecords List of newly inserted EPA_StudyLeaveRequest__c records
     * @return void
     */
    public static void handleAfterInsert(List<EPA_StudyLeaveRequest__c> newRecords) {
        List<EPA_StudyLeaveRequest__Share> sharesToInsert = new List<EPA_StudyLeaveRequest__Share>();

        for (EPA_StudyLeaveRequest__c req : newRecords) {
            if (req.EPA_Manager__c != null) {
                sharesToInsert.add(createShareRecord(req.Id, req.EPA_Manager__c));
            }
        }

        if (!sharesToInsert.isEmpty()) {
            Database.insert(sharesToInsert, false);
        }
    }

    /**
     * @description: Handles after-update events. Detects changes to EPA_Manager__c and
     *               recalculates share records accordingly — deletes old shares, inserts new ones.
     * @param newRecords List of updated EPA_StudyLeaveRequest__c records (new values)
     * @param oldMap Map of old record values keyed by Id
     * @return void
     */
    public static void handleAfterUpdate(List<EPA_StudyLeaveRequest__c> newRecords, Map<Id, EPA_StudyLeaveRequest__c> oldMap) {
        List<EPA_StudyLeaveRequest__Share> sharesToInsert = new List<EPA_StudyLeaveRequest__Share>();
        Set<Id> recordIdsWithManagerChange = new Set<Id>();

        for (EPA_StudyLeaveRequest__c req : newRecords) {
            EPA_StudyLeaveRequest__c oldReq = oldMap.get(req.Id);
            if (req.EPA_Manager__c != oldReq.EPA_Manager__c) {
                recordIdsWithManagerChange.add(req.Id);
                if (req.EPA_Manager__c != null) {
                    sharesToInsert.add(createShareRecord(req.Id, req.EPA_Manager__c));
                }
            }
        }

        if (!recordIdsWithManagerChange.isEmpty()) {
            deleteExistingShares(recordIdsWithManagerChange);
        }

        if (!sharesToInsert.isEmpty()) {
            Database.insert(sharesToInsert, false);
        }
    }

    /**
     * @description: Creates a share record granting Edit access to the specified manager user.
     * @param recordId The Id of the EPA_StudyLeaveRequest__c record
     * @param managerId The Id of the manager User to grant access
     * @return EPA_StudyLeaveRequest__Share The share record to insert
     */
    private static EPA_StudyLeaveRequest__Share createShareRecord(Id recordId, Id managerId) {
        EPA_StudyLeaveRequest__Share shareRecord = new EPA_StudyLeaveRequest__Share();
        shareRecord.ParentId = recordId;
        shareRecord.UserOrGroupId = managerId;
        shareRecord.AccessLevel = 'Edit';
        shareRecord.RowCause = Schema.EPA_StudyLeaveRequest__Share.RowCause.EPA_ManagerAccess__c;
        return shareRecord;
    }

    /**
     * @description: Deletes existing Apex-managed share records for the given record IDs
     *               using the EPA_ManagerAccess__c row cause.
     * @param recordIds Set of EPA_StudyLeaveRequest__c record IDs to remove shares for
     * @return void
     */
    private static void deleteExistingShares(Set<Id> recordIds) {
        List<EPA_StudyLeaveRequest__Share> existingShares = [
            SELECT Id
            FROM EPA_StudyLeaveRequest__Share
            WHERE ParentId IN :recordIds
            AND RowCause = :Schema.EPA_StudyLeaveRequest__Share.RowCause.EPA_ManagerAccess__c
        ];
        if (!existingShares.isEmpty()) {
            Database.delete(existingShares, false);
        }
    }
}
