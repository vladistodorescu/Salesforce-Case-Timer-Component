trigger onCase on Case (before update, after update) {
    if (Trigger.isBefore && Trigger.isUpdate){
        List<Case> casesToActivateSLA = new List<Case>();
        List<Case> casesToDeactivateSLA = new List<Case>();

        for (Case currentCase : Trigger.new){
            Case oldCase = Trigger.oldMap.get(currentCase.Id);

            if (oldCase.SLA_Active__c == false && currentCase.SLA_Active__c == true){
                // means we can execute the logic for SLA Activation
                casesToActivateSLA.add(currentCase);
            }

            if (oldCase.SLA_Active__c == true && currentCase.SLA_Active__c == false){
                // means we can execute the logic for SLA Deactivation
                casesToDeactivateSLA.add(currentCase);
            }
        }

        if (!casesToActivateSLA.isEmpty()){
            CaseService.activateCases(casesToActivateSLA);
        }

        if (!casesToDeactivateSLA.isEmpty()){
            CaseService.deactivateCases(casesToDeactivateSLA);
        }
    }
}
