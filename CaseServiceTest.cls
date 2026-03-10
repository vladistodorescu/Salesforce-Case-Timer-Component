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

        Case caseToPause = new Case(Status = 'Escalated', 
                                    Origin = 'Web', 
                                    SLA_Active__c = true,
                                    SLA_Paused__c = false,
                                    SuppliedEmail = 'caseToPause@gmail.com');

        Case caseToResume = new Case(Status = 'Escalated', 
                                    Origin = 'Web', 
                                    SLA_Active__c = true,
                                    SLA_Paused__c = true,
                                    Pause_Start__c = Datetime.now().addMinutes(-15), 
                                    SLA_Total_Paused_Minutes__c = 10,
                                    SuppliedEmail = 'caseToResume@gmail.com');

        cases.add(caseToActivate);
        cases.add(caseToDeactivate);
        cases.add(caseToPause);
        cases.add(caseToResume);

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
        
        Assert.areEqual('On Track', casesToActivate[0].SLA_Status__c, 'CaseServiceTest.testActivateCases(): SLA Status is not "On Track"!');
        Assert.areEqual(0, casesToActivate[0].SLA_Total_Paused_Minutes__c, 'CaseServiceTest.testActivateCases(): SLA Total Paused Minutes is not 0!'); 
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

        Assert.areEqual(null, casestoDeactivate[0].SLA_Start__c, 'CaseServiceTest.testDeactivateCases(): SLA Start is not null!');
        Assert.areEqual(null, casestoDeactivate[0].SLA_Total_Paused_Minutes__c, 'CaseServiceTest.testDeactivateCases(): SLA Total Paused Minutes is not 0!'); 
        Assert.areEqual(null, casestoDeactivate[0].Pause_Start__c, 'CaseServiceTest.testDeactivateCases(): SLA Pause Start is not null!'); 
        Assert.areEqual(false, casestoDeactivate[0].SLA_Paused__c, 'CaseServiceTest.testDeactivateCases(): SLA Paused Boolean is not false!');
        Assert.areEqual('Inactive', casestoDeactivate[0].SLA_Status__c, 'CaseServiceTest.testDeactivateCases(): SLA Status is not "Inactive"'); 
    }

    @isTest
    static void testPauseCases(){
        List<Case> casesToPause = [SELECT Id, Pause_Start__c, SuppliedEmail 
                                   FROM Case
                                   WHERE SuppliedEmail = 'caseToPause@gmail.com'
                                   LIMIT 1];

        Test.startTest();
        CaseService.pauseCases(casesToPause);
        Test.stopTest();

        Assert.areNotEqual(null, casesToPause[0].Pause_Start__c, 'CaseServiceTest.testPauseCases(): Pause_Start__c should be different form null after pausing Cases!');
    }

    @isTest
    static void testResumeCases(){
        List<Case> casesToResume = [SELECT Id, Pause_Start__c, SLA_Total_Paused_Minutes__c
                                    FROM Case
                                    WHERE SuppliedEmail = 'caseToResume@gmail.com'
                                    LIMIT 1];

        Test.startTest();
        CaseService.resumeCases(casesToResume);
        Test.stopTest();

        Assert.areEqual(null, casesToResume[0].Pause_Start__c, 'CaseServiceTest.testResumeCases(): Pause_Start__c should be null!');
        Assert.areEqual(25, casesToResume[0].SLA_Total_Paused_Minutes__c, 'CaseServiceTest.testResumeCases(): SLA_Total_Paused_minutes__c should be 25!');
    }

}
