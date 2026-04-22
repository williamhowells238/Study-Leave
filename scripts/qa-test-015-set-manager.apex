// Set User User's manager to Integration User (or create hierarchy)
// We'll use the Tooling API approach - update ManagerId on User User
User apprentice = [SELECT Id, Name, ManagerId FROM User WHERE Name = 'User User' LIMIT 1];
User manager = [SELECT Id, Name FROM User WHERE Name = 'Integration User' LIMIT 1];

// Set manager
apprentice.ManagerId = manager.Id;
update apprentice;
System.debug('RESULT: Set manager of ' + apprentice.Name + ' (' + apprentice.Id + ') to ' + manager.Name + ' (' + manager.Id + ')');

// Verify
User verify = [SELECT Id, Name, ManagerId, Manager.Name FROM User WHERE Id = :apprentice.Id];
System.debug('RESULT: Verified - ' + verify.Name + ' manager is now: ' + verify.Manager.Name + ' (' + verify.ManagerId + ')');
