// AC1 & AC2: Edit a Pending future-dated request
// Record a029I000009ABv6QAG: Start=2026-06-10, End=2026-06-12, Category=QA Test Category, Status=Pending, BizDays=3
// Change to: Start=2026-06-15, End=2026-06-18, Category=QA Edit Test Category
// Expected: Update succeeds, BizDays recalculated (Jun 15 Mon - Jun 18 Thu = 4 business days)

EPA_StudyLeaveRequest__c req = [SELECT Id, EPA_StartDate__c, EPA_EndDate__c, EPA_Category__c, EPA_Status__c, EPA_CalculatedBusinessDays__c FROM EPA_StudyLeaveRequest__c WHERE Id = 'a029I000009ABv6QAG'];
System.debug('BEFORE: Start=' + req.EPA_StartDate__c + ', End=' + req.EPA_EndDate__c + ', Category=' + req.EPA_Category__c + ', Status=' + req.EPA_Status__c + ', BizDays=' + req.EPA_CalculatedBusinessDays__c);

req.EPA_StartDate__c = Date.newInstance(2026, 6, 15);
req.EPA_EndDate__c = Date.newInstance(2026, 6, 18);
req.EPA_Category__c = 'a009I00000JBxY5QAL'; // QA Edit Test Category
try {
    update req;
    EPA_StudyLeaveRequest__c updated = [SELECT Id, EPA_StartDate__c, EPA_EndDate__c, EPA_Category__c, EPA_Category__r.Name, EPA_Status__c, EPA_CalculatedBusinessDays__c FROM EPA_StudyLeaveRequest__c WHERE Id = 'a029I000009ABv6QAG'];
    System.debug('AFTER: Start=' + updated.EPA_StartDate__c + ', End=' + updated.EPA_EndDate__c + ', Category=' + updated.EPA_Category__r.Name + ', Status=' + updated.EPA_Status__c + ', BizDays=' + updated.EPA_CalculatedBusinessDays__c);
    System.debug('AC1 RESULT: ' + (updated.EPA_StartDate__c == Date.newInstance(2026,6,15) && updated.EPA_EndDate__c == Date.newInstance(2026,6,18) && updated.EPA_Category__c == 'a009I00000JBxY5QAL' ? 'PASS - Fields updated successfully' : 'FAIL - Fields not updated correctly'));
    System.debug('AC2 RESULT: ' + (updated.EPA_CalculatedBusinessDays__c == 4 ? 'PASS - Business days recalculated to 4' : 'FAIL - Expected 4 business days, got ' + updated.EPA_CalculatedBusinessDays__c));
} catch (Exception e) {
    System.debug('AC1 RESULT: FAIL - Update threw exception: ' + e.getMessage());
}
