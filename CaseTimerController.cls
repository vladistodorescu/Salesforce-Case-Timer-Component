public with sharing class CaseTimerController {
    @AuraEnabled
    public static void updateStatusToOnTrack(String recordId){
        if (recordId == null){
            System.debug('CaseService.updateStatusToWarning: The Record Id cannot be null!');
            return;
        }

        List<Case> caseToUpdate = [SELECT Id, SLA_Status__c
                                   FROM Case
                                   WHERE Id =: recordId
                                   LIMIT 1];
        
        caseToUpdate[0].SLA_Status__c = 'On Track';
        
        update caseToUpdate;
    }

    @AuraEnabled
    public static void updateStatusToWarning(String recordId){
        if (recordId == null){
            System.debug('CaseService.updateStatusToWarning: The Record Id cannot be null!');
            return;
        }

        List<Case> caseToUpdate = [SELECT Id, SLA_Status__c
                                   FROM Case
                                   WHERE Id =: recordId
                                   LIMIT 1];
        
        caseToUpdate[0].SLA_Status__c = 'Warning';
        
        update caseToUpdate;
    }

    @AuraEnabled
    public static void updateStatusToBreached(String recordId){
        if (recordId == null){
            System.debug('CaseService.updateStatusToWarning: The Record Id cannot be null!');
            return;
        }

        List<Case> caseToUpdate = [SELECT Id, SLA_Status__c
                                   FROM Case
                                   WHERE Id =: recordId
                                   LIMIT 1];
        
        caseToUpdate[0].SLA_Status__c = 'Breached';
        
        update caseToUpdate;
    }

    @AuraEnabled(cacheable=true)
    public static SLA_Config__mdt getSettingsSLA(String recordName){
        try {
            return [SELECT Warning_Hours__c, Breach_Hours__c 
                    FROM SLA_Config__mdt 
                    WHERE DeveloperName =: recordName
                    LIMIT 1];
        } catch (Exception e) {
            return null;
        }
    }
}
