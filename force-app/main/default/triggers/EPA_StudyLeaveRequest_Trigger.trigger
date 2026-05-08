/**
 * @description: Trigger on EPA_StudyLeaveRequest__c that delegates after-insert and after-update
 *               events to the sharing handler class for Apex Managed Sharing.
 * @author: Developer Agent
 * @date: 2026-05-08
 */
trigger EPA_StudyLeaveRequest_Trigger on EPA_StudyLeaveRequest__c (after insert, after update) {

    if (Trigger.isAfter && Trigger.isInsert) {
        EPA_StudyLeaveRequestSharing_Class.handleAfterInsert(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        EPA_StudyLeaveRequestSharing_Class.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}
