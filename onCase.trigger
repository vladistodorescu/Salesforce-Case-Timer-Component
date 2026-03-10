trigger onCase on Case (before update, after update) {
    if (Trigger.isBefore && Trigger.isUpdate){
        List<Case> casesToActivateSLA = new List<Case>();
        List<Case> casesToDeactivateSLA = new List<Case>();
        List<Case> casesToPauseSLA = new List<Case>();
        List<Case> casesToResumeSLA = new List<Case>();

        for (Case currentCase : Trigger.new){
            Case oldCase = Trigger.oldMap.get(currentCase.Id);

            if (oldCase.SLA_Active__c == false && currentCase.SLA_Active__c == true){
                casesToActivateSLA.add(currentCase);
            }

            if (oldCase.SLA_Active__c == true && currentCase.SLA_Active__c == false){
                casesToDeactivateSLA.add(currentCase);
            }

            if (oldCase.SLA_Paused__c == false && currentCase.SLA_Paused__c == true){
                casesToPauseSLA.add(currentCase);
            }

            if (oldCase.SLA_Paused__c == true && currentCase.SLA_Paused__c == false){
                casesToResumeSLA.add(currentCase);
            }
        }

        if (!casesToActivateSLA.isEmpty()){
            CaseService.activateCases(casesToActivateSLA);
        }

        if (!casesToDeactivateSLA.isEmpty()){
            CaseService.deactivateCases(casesToDeactivateSLA);
        }

        if (!casesToPauseSLA.isEmpty()){
            CaseService.pauseCases(casesToPauseSLA);
        }

        if (!casesToResumeSLA.isEmpty()){
            CaseService.resumeCases(casesToResumeSLA);
        }
    }

    if (Trigger.isAfter && Trigger.isUpdate){
        List<SLA_Audit__c> auditTrailsToInsert = new List<SLA_Audit__c>();

        Set<Id> triggeredCasesIds = new Set<Id>();
        for (Case currentCase: Trigger.new){
            triggeredCasesIds.add(currentCase.Id);
        }

        List<SLA_Audit__c> allAudits = [SELECT Id, Old_Status__c, New_Status__c, Parent_Record__c, Change_TimeStamp__c
                                        FROM SLA_Audit__c
                                        WHERE Parent_Record__c IN :triggeredCasesIds
                                        ORDER BY Change_TimeStamp__c DESC];

        Map<Id, SLA_Audit__c> parentRecordIdToAuditMap = new Map<Id, SLA_Audit__c>();

        for (SLA_Audit__c audit : allAudits){
            parentRecordIdToAuditMap.put(audit.Parent_Record__c, audit);
        }

        DateTime now = Datetime.now();

        for (Case currentCase: Trigger.new){
            Case oldCase = Trigger.oldMap.get(currentCase.Id);

            if (oldCase.SLA_Status__c != currentCase.SLA_Status__c){
                SLA_Audit__c auditTrail = new SLA_Audit__c();
                auditTrail.New_Status__c = currentCase.SLA_Status__c;
                auditTrail.Parent_Record__c = currentCase.Id;
                auditTrail.Change_TimeStamp__c = now;

                // 2 different situations for Elapsed Time:
                // 1. old Status is null --> Elapsed Time = Now - Case Creation Date
                // 2. old Status is not null --> Elapsed Time = Now - Last Change Timestamp (most recent Audit record related to this Case)
                if (oldCase.SLA_Status__c == null){
                    auditTrail.Old_Status__c = 'NULL';

                    Datetime createdDt = currentCase.CreatedDate;
                    Long elapsedMs = now.getTime() - createdDt.getTime();
                    Decimal elapsedMin = Decimal.valueOf(elapsedMs) / (1000 * 60);
                    auditTrail.Elapsed_Time__c = elapsedMin;

                    auditTrailsToInsert.add(auditTrail);
                } 
                else {
                    auditTrail.Old_Status__c = oldCase.SLA_Status__c;

                    SLA_Audit__c lastStatusChangeAudit = parentRecordIdToAuditMap.get(currentCase.Id);
                    Datetime lastChangedDt = lastStatusChangeAudit.Change_TimeStamp__c;
                    Long elapsedMs = now.getTime() - lastChangedDt.getTime();
                    Decimal elapsedMin = Decimal.valueOf(elapsedMs)/ (1000 * 60);
                    auditTrail.Elapsed_Time__c = elapsedMin;

                    auditTrailsToInsert.add(auditTrail);
                }
            }
        }

        if (!auditTrailsToInsert.isEmpty()){
            insert auditTrailsToInsert;
        }
    }
