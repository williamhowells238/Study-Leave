// QA Test Setup for Story 015 - Create leave category and set up manager hierarchy
// Create a Leave Category for testing
EPA_LeaveCategory__c cat = new EPA_LeaveCategory__c(Name = 'QA Test Category 015');
insert cat;
System.debug('RESULT: Leave Category created: ' + cat.Id);

// Get all active users
List<User> allUsers = [SELECT Id, Name, ManagerId, Profile.Name FROM User WHERE IsActive = true ORDER BY Name];
for (User u : allUsers) {
    System.debug('RESULT: User: ' + u.Id + ' | ' + u.Name + ' | Manager: ' + u.ManagerId + ' | Profile: ' + u.Profile.Name);
}
