// AC4: Editing an Approved request resets status to Pending
// Use record a029I000009AGMTQA4 (Start=2026-06-01, End=2026-06-03, Status=Pending)
// Step 1: Set it to Approved
// Step 2: Edit the dates
// Step 3: Verify status reset to Pending

// Step 1: Set to Approved
EPA_StudyLeaveRequest__c req = [SELECT Id, EPA_Status__c FROM EPA_StudyLeaveRequest__c WHERE Id = 'a029I000009AGMTQA4'];
System.debug('BEFORE APPROVE: Status=' + req.EPA_Status__c);
req.EPA_Status__c = 'Approved';
update req;
System.debug('SET TO APPROVED');

// Step 2: Edit dates on the Approved record
EPA_StudyLeaveRequest__c approvedReq = [SELECT Id, EPA_StartDate__c, EPA_EndDate__c, EPA_Status__c, EPA_CalculatedBusinessDays__c FROM EPA_StudyLeaveRequest__c WHERE Id = 'a029I000009AGMTQA4'];
System.debug('BEFORE EDIT: Start=' + approvedReq.EPA_StartDate__c + ', End=' + approvedReq.EPA_EndDate__c + ', Status=' + approvedReq.EPA_Status__c + ', BizDays=' + approvedReq.EPA_CalculatedBusinessDays__c);

approvedReq.EPA_StartDate__c = Date.newInstance(2026, 6, 8);
approvedReq.EPA_EndDate__c = Date.newInstance(2026, 6, 10);
try {
    update approvedReq;
    EPA_StudyLeaveRequest__c updated = [SELECT Id, EPA_StartDate__c, EPA_EndDate__c, EPA_Status__c, EPA_CalculatedBusinessDays__c FROM EPA_StudyLeaveRequest__c WHERE Id = 'a029I000009AGMTQA4'];
    System.debug('AFTER EDIT: Start=' + updated.EPA_StartDate__c + ', End=' + updated.EPA_EndDate__c + ', Status=' + updated.EPA_Status__c + ', BizDays=' + updated.EPA_CalculatedBusinessDays__c);
    System.debug('AC4 RESULT: ' + (updated.EPA_Status__c == 'Pending' ? 'PASS - Status reset from Approved to Pending' : 'FAIL - Expected Pending, got ' + updated.EPA_Status__c));
} catch (Exception e) {
    System.debug('AC4 RESULT: FAIL - Update threw exception: ' + e.getMessage());
}

// Step 3: Also test category-only change on an Approved record resets status
// Reset to Approved first
EPA_StudyLeaveRequest__c resetReq = [SELECT Id FROM EPA_StudyLeaveRequest__c WHERE Id = 'a029I000009AGMTQA4'];
resetReq.EPA_Status__c = 'Approved';
update resetReq;
System.debug('RESET TO APPROVED AGAIN');

EPA_StudyLeaveRequest__c catReq = [SELECT Id, EPA_Category__c, EPA_Status__c FROM EPA_StudyLeaveRequest__c WHERE Id = 'a029I000009AGMTQA4'];
catReq.EPA_Category__c = 'a009I00000JBlljQAD'; // Change back to QA Test Category
try {
    update catReq;
    EPA_StudyLeaveRequest__c catUpdated = [SELECT Id, EPA_Category__c, EPA_Category__r.Name, EPA_Status__c FROM EPA_StudyLeaveRequest__c WHERE Id = 'a029I000009AGMTQA4'];
    System.debug('AFTER CATEGORY EDIT: Category=' + catUpdated.EPA_Category__r.Name + ', Status=' + catUpdated.EPA_Status__c);
    System.debug('AC4b RESULT: ' + (catUpdated.EPA_Status__c == 'Pending' ? 'PASS - Category change also resets Approved to Pending' : 'FAIL - Expected Pending, got ' + catUpdated.EPA_Status__c));
} catch (Exception e) {
    System.debug('AC4b RESULT: FAIL - Category update threw exception: ' + e.getMessage());
}
