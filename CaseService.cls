public with sharing class CaseService {
    public static void activateCases(List<Case> cases){
        if (cases.isEmpty()){
            System.debug('CaseService.activateCases: The List cannot be empty!');
            return;
        }

        Datetime nowDT = Datetime.now();
        
        for (Case currentCase : cases){
            currentCase.SLA_Start__c = nowDT;
            currentCase.SLA_Status__c = 'On Track';
            currentCase.SLA_Total_Paused_Minutes__c = 0;
        }

        // nu trebuie update pentru ca suntem in before
    }

    public static void deactivateCases(List<Case> cases){
        if (cases.isEmpty()){
            System.debug('CaseService.deactivateCases: The List cannot be empty!');
            return;
        }

        for (Case currentCase : cases){
            currentCase.SLA_Start__c = null;
            currentCase.SLA_Paused__c = false;
            currentCase.Pause_Start__c = null;
            currentCase.SLA_Total_Paused_Minutes__c = null;
            currentCase.SLA_Status__c = 'Inactive';
        }

        // nu trebuie update pentru ca suntem in before
    }
}
