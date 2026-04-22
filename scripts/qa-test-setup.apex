EPA_StudyLeaveRequest__c req = new EPA_StudyLeaveRequest__c(
    EPA_StartDate__c = Date.newInstance(2026, 4, 20),
    EPA_EndDate__c = Date.newInstance(2026, 4, 21),
    EPA_Category__c = 'a009I00000JBlljQAD',
    EPA_Apprentice__c = '0059I000009VMgbQAG',
    EPA_Status__c = 'Pending',
    EPA_CalculatedBusinessDays__c = 2
);
Database.DMLOptions dmo = new Database.DMLOptions();
dmo.allowFieldTruncation = true;
Database.insert(req, dmo);
System.debug('Created past-dated record: ' + req.Id);
