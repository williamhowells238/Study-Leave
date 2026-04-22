// AC4 Test: Create a study leave request for a user with NO manager
// Expect: Flow triggers but exits gracefully at Decision element, no error

// First, temporarily remove manager from User User
User apprentice = [SELECT Id, Name, ManagerId FROM User WHERE Name = 'User User' LIMIT 1];
System.debug('RESULT: Before - ' + apprentice.Name + ' ManagerId: ' + apprentice.ManagerId);
apprentice.ManagerId = null;
update apprentice;
System.debug('RESULT: Manager removed from User User');

// Get leave category
EPA_LeaveCategory__c cat = [SELECT Id FROM EPA_LeaveCategory__c WHERE Name = 'QA Test Category 015' LIMIT 1];

// Create a study leave request - should NOT cause an error even with no manager
EPA_StudyLeaveRequest__c req = new EPA_StudyLeaveRequest__c(
    EPA_StartDate__c = Date.newInstance(2026, 7, 1),
    EPA_EndDate__c = Date.newInstance(2026, 7, 2),
    EPA_Category__c = cat.Id,
    EPA_Apprentice__c = apprentice.Id,
    EPA_Status__c = 'Pending',
    EPA_CalculatedBusinessDays__c = 1
);

try {
    insert req;
    System.debug('RESULT: AC4 PASS - Request created successfully with no manager, no error. Record Id: ' + req.Id);
} catch (Exception e) {
    System.debug('RESULT: AC4 FAIL - Error occurred: ' + e.getMessage());
}

// Restore manager
apprentice.ManagerId = '0057200000C8wo6AAB';
update apprentice;
System.debug('RESULT: Manager restored for User User');
