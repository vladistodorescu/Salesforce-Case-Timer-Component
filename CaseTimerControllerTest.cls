// CaseTimerControllerTest Final Version
@isTest
private class CaseTimerControllerTest {

    @TestSetup
    static void makeData(){
        List<Case> cases = new List<Case>();

        Case case1 = new Case(Status = 'Escalated', 
                              Origin = 'Web', 
                              SLA_Active__c = true,
                              SLA_Status__c = 'Breached');

        Case case2 = new Case(Status = 'Escalated', 
                              Origin = 'Phone', 
                              SLA_Active__c = true,
                              SLA_Status__c = 'On Track');

        cases.add(case1);
        cases.add(case2);

        insert cases;
    }

    @isTest
    static void testUpdateStatusToOnTrack(){
        List<Case> casesBeforeUpdate = [SELECT Id, SLA_Status__c 
                            FROM Case 
                            WHERE SLA_Status__c = 'Breached'
                            LIMIT 1];
        
        Test.startTest();
        CaseTimerController.updateStatusToOnTrack(String.valueOf(casesBeforeUpdate[0].Id));
        Test.stopTest();

        List<Case> casesAfterUpdate = [SELECT Id, SLA_Status__c
                                       FROM Case
                                       WHERE SLA_Status__c = 'On Track'
                                       AND Origin = 'Web'
                                       LIMIT 1];

        Assert.areEqual('On Track', casesAfterUpdate[0].SLA_Status__c, 'Status should be "On Track"!');
    }

    @isTest
    static void testUpdateStatusToBreached(){
        List<Case> casesBeforeUpdate = [SELECT Id, SLA_Status__c 
                                        FROM Case 
                                        WHERE SLA_Status__c = 'On Track'
                                        LIMIT 1];

        Test.startTest();
        CaseTimerController.updateStatusToBreached(String.valueOf(casesBeforeUpdate[0].Id));
        Test.stopTest();

        List<Case> casesAfterUpdate = [SELECT Id, SLA_Status__c
                                       FROM Case
                                       WHERE SLA_Status__c = 'Breached'
                                       AND Origin = 'Phone'
                                       LIMIT 1];

        Assert.areEqual('Breached', casesAfterUpdate[0].SLA_Status__c, 'Status should be "Breached"!');
    }

    @isTest
    static void testUpdateStatusToWarning(){
        List<Case> casesBeforeUpdate = [SELECT Id, SLA_Status__c 
                                        FROM Case 
                                        WHERE SLA_Status__c = 'On Track'
                                        LIMIT 1];

        Test.startTest();
        CaseTimerController.updateStatusToWarning(String.valueOf(casesBeforeUpdate[0].Id));
        Test.stopTest();

        List<Case> casesAfterUpdate = [SELECT Id, SLA_Status__c
                                       FROM Case
                                       WHERE SLA_Status__c = 'Warning'
                                       AND Origin = 'Phone'
                                       LIMIT 1];

        Assert.areEqual('Warning', casesAfterUpdate[0].SLA_Status__c, 'Status should be "Warning"!');
    }

    @IsTest
    static void testGetSettingsSLA() {
        Test.startTest();
        SLA_Config__mdt result = CaseTimerController.getSettingsSLA('Case_Timer_Thresholds_Min');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should find the metadata record!');
    }

    @IsTest
    static void testGetSettingsSLANull() {
        Test.startTest();
        SLA_Config__mdt result = CaseTimerController.getSettingsSLA('Non_Existent_Config_Record');
        Test.stopTest();
        
        System.assertEquals(null, result, 'Should return null for invalid name!');
    }
}
