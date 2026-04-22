// AC4b retry: Category-only change on Approved request should reset to Pending
// Record a029I000009AGMTQA4 currently has Status=Pending, Category=a009I00000JBlljQAD (QA Test Category)
// Step 1: Reset to Approved
// Step 2: Change category to QA Edit Test Category (a009I00000JBxY5QAL) — a real change
// Step 3: Verify status reset to Pending

// Check current state
EPA_StudyLeaveRequest__c check = [SELECT Id, EPA_Category__c, EPA_Category__r.Name, EPA_Status__c FROM EPA_StudyLeaveRequest__c WHERE Id = 'a029I000009AGMTQA4'];
System.debug('CURRENT STATE: Category=' + check.EPA_Category__r.Name + ' (' + check.EPA_Category__c + '), Status=' + check.EPA_Status__c);

// Set to Approved
check.EPA_Status__c = 'Approved';
update check;

// Now change category to something different
EPA_StudyLeaveRequest__c catReq = [SELECT Id, EPA_Category__c, EPA_Status__c FROM EPA_StudyLeaveRequest__c WHERE Id = 'a029I000009AGMTQA4'];
System.debug('BEFORE CATEGORY EDIT: Category=' + catReq.EPA_Category__c + ', Status=' + catReq.EPA_Status__c);

catReq.EPA_Category__c = 'a009I00000JBxY5QAL'; // QA Edit Test Category — different from current
update catReq;

EPA_StudyLeaveRequest__c result = [SELECT Id, EPA_Category__c, EPA_Category__r.Name, EPA_Status__c FROM EPA_StudyLeaveRequest__c WHERE Id = 'a029I000009AGMTQA4'];
System.debug('AFTER CATEGORY EDIT: Category=' + result.EPA_Category__r.Name + ', Status=' + result.EPA_Status__c);
System.debug('AC4b RESULT: ' + (result.EPA_Status__c == 'Pending' ? 'PASS - Category-only change resets Approved to Pending' : 'FAIL - Expected Pending, got ' + result.EPA_Status__c));
