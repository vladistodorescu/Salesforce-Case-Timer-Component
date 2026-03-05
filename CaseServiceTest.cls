@isTest
private class CaseServiceTest {

    @TestSetup
    static void makeData(){
        List<Case> cases = new List<Case>();

        Case caseToActivate = new Case(Status = 'Escalated', 
                                       Origin = 'Web', 
                                       SLA_Active__c = false, 
                                       SuppliedEmail = 'caseToActivate@gmail.com');

        Case caseToDeactivate = new Case(Status = 'Escalated', 
                                         Origin = 'Phone', 
                                         SLA_Active__c = true,
                                         SLA_Paused__c = true,
                                         SLA_Start__c = Datetime.now().addHours(-2),
                                         Pause_Start__c = Datetime.now().addHours(-1), 
                                         SLA_Total_Paused_Minutes__c = 60,
                                         SuppliedEmail = 'caseToDeactivate@gmail.com');

        cases.add(caseToActivate);
        cases.add(caseToDeactivate);

        insert cases;
    }

    @isTest
    static void testActivateCases() {
        List<Case> casestoActivate = [SELECT SLA_Active__c, 
                                            SLA_Paused__c, 
                                            SLA_Start__c, 
                                            SLA_Total_Paused_Minutes__c, 
                                            SLA_Status__c, 
                                            Pause_Start__c, 
                                            SuppliedEmail 
                                            FROM Case 
                                            WHERE SuppliedEmail = 'caseToActivate@gmail.com'
                                            LIMIT 1];
        
        Test.startTest();
        CaseService.activateCases(casesToActivate);
        Test.stopTest();
        
        Assert.areEqual('On Track', casesToActivate[0].SLA_Status__c, 'SLA Status is not "On Track"!');
        Assert.areEqual(0, casesToActivate[0].SLA_Total_Paused_Minutes__c, 'SLA Total Paused Minutes is not 0!'); 
    }

    @isTest
    static void testDeactivateCases(){
        List<Case> casestoDeactivate = [SELECT SLA_Active__c, 
                                               SLA_Paused__c, 
                                               SLA_Start__c, 
                                               SLA_Total_Paused_Minutes__c, 
                                               SLA_Status__c, 
                                               Pause_Start__c, 
                                               SuppliedEmail 
                                               FROM Case 
                                               WHERE SuppliedEmail = 'caseToDeactivate@gmail.com'
                                               LIMIT 1];

        Test.startTest();
        CaseService.deactivateCases(casestoDeactivate);
        Test.stopTest();

        Assert.areEqual(null, casestoDeactivate[0].SLA_Start__c, 'SLA Start is not null!');
        Assert.areEqual(null, casestoDeactivate[0].SLA_Total_Paused_Minutes__c, 'SLA Total Paused Minutes is not 0!'); 
        Assert.areEqual(null, casestoDeactivate[0].Pause_Start__c, 'SLA Pause Start is not null!'); 
        Assert.areEqual(false, casestoDeactivate[0].SLA_Paused__c, 'SLA Paused Boolean is not false!');
        Assert.areEqual('Inactive', casestoDeactivate[0].SLA_Status__c, 'SLA Status is not "Inactive"'); 
    }
}
