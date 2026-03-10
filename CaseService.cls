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

    public static void pauseCases(List<Case> cases){
        if (cases.isEmpty()){
            System.debug('CaseService.deactivateCases: The List cannot be empty!');
            return;
        }

        Datetime now = Datetime.now();

        for (Case currentCase : cases){
            currentCase.Pause_Start__c = now;
        }
    }

    public static void resumeCases(List<Case> cases){
        if (cases.isEmpty()){
            System.debug('CaseService.deactivateCases: The List cannot be empty!');
            return;
        }

        Datetime now = Datetime.now();
        Long nowMs = now.getTime();

        for (Case currentCase : cases){
            if (currentCase.Pause_Start__c != null){
                Long pauseStartMs = currentCase.Pause_Start__c.getTime();
                Integer totalPauseMin = (Integer)((nowMs - pauseStartMs) / 60000);
                Decimal totalExisting = currentCase.SLA_Total_Paused_Minutes__c != null ? currentCase.SLA_Total_Paused_Minutes__c : 0;
                currentCase.SLA_Total_Paused_Minutes__c = totalExisting + totalPauseMin;
                currentCase.Pause_Start__c = null;     
            } 
        }
    }
}
