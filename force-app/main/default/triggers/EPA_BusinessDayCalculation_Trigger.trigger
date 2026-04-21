/**
 * @description: Before trigger on EPA_StudyLeaveRequest__c to calculate business days
 *               between Start Date and End Date, excluding weekends and public holidays,
 *               and validate against the annual study leave allowance.
 * @author: Developer Agent
 * @date: 2026-04-21
 */
trigger EPA_BusinessDayCalculation_Trigger on EPA_StudyLeaveRequest__c (before insert, before update) {

    List<EPA_StudyLeaveRequest__c> recordsToProcess = new List<EPA_StudyLeaveRequest__c>();

    if (Trigger.isInsert) {
        recordsToProcess = Trigger.new;
    } else if (Trigger.isUpdate) {
        for (EPA_StudyLeaveRequest__c req : Trigger.new) {
            EPA_StudyLeaveRequest__c oldReq = Trigger.oldMap.get(req.Id);
            if (req.EPA_StartDate__c != oldReq.EPA_StartDate__c ||
                req.EPA_EndDate__c != oldReq.EPA_EndDate__c) {
                recordsToProcess.add(req);
            }
        }
    }

    if (!recordsToProcess.isEmpty()) {
        EPA_BusinessDayCalculation_Class.calculateBusinessDays(recordsToProcess);
        EPA_AnnualAllowanceValidation_Class.validateAllowance(recordsToProcess);
    }
}
