// AC3: Test that editing a request with a past start date is blocked
// Step 1: Create a past-dated record by inserting as Cancelled (bypasses advance notice VR)
// then updating status to Pending (edit past start date VR only fires on ISCHANGED of date/category fields)

EPA_StudyLeaveRequest__c req = new EPA_StudyLeaveRequest__c(
    EPA_StartDate__c = Date.newInstance(2026, 4, 20),
    EPA_EndDate__c = Date.newInstance(2026, 4, 21),
    EPA_Category__c = 'a009I00000JBlljQAD',
    EPA_Apprentice__c = '0059I000009VMgbQAG',
    EPA_Status__c = 'Cancelled',
    EPA_CalculatedBusinessDays__c = 2
);
insert req;
System.debug('Created past-dated Cancelled record: ' + req.Id);

// Update to Pending (no date/category field changes, so edit VR won't fire)
req.EPA_Status__c = 'Pending';
update req;
System.debug('Updated to Pending: ' + req.Id);

// Step 2: Now try to edit dates on this past-dated record — should be blocked
try {
    req.EPA_StartDate__c = Date.newInstance(2026, 6, 20);
    update req;
    System.debug('AC3 RESULT: FAIL - Edit of past-dated record was NOT blocked');
} catch (DmlException e) {
    String msg = e.getMessage();
    Boolean hasCorrectMessage = msg.contains('This request can no longer be edited as the leave start date has passed');
    System.debug('AC3 Error message: ' + msg);
    System.debug('AC3 RESULT: ' + (hasCorrectMessage ? 'PASS - Edit blocked with correct error message' : 'FAIL - Edit blocked but wrong message: ' + msg));
}

// Step 3: Also test editing category on past-dated record — should also be blocked
EPA_StudyLeaveRequest__c req2 = [SELECT Id, EPA_StartDate__c, EPA_EndDate__c, EPA_Category__c FROM EPA_StudyLeaveRequest__c WHERE Id = :req.Id];
try {
    req2.EPA_Category__c = 'a009I00000JBxY5QAL'; // Change category
    update req2;
    System.debug('AC3b RESULT: FAIL - Category edit of past-dated record was NOT blocked');
} catch (DmlException e) {
    String msg = e.getMessage();
    Boolean hasCorrectMessage = msg.contains('This request can no longer be edited as the leave start date has passed');
    System.debug('AC3b RESULT: ' + (hasCorrectMessage ? 'PASS - Category edit also blocked with correct message' : 'FAIL - Wrong message: ' + msg));
}
