public with sharing class MaintenanceRequestHelper {
    public static void updateWorkOrders(List<Case> listNewCases, Map<Id,Case> mapOldCases) {
        Set<Id> setIdOfClosedMaintReq = new Set<Id>();
        for (Case mr : listNewCases){
            if(mr.Status == 'Closed' && mapOldCases.get(mr.Id).Status != 'Closed'){
                if(mr.Type == 'Repair' || mr.Type == 'Routine Maintenance'){
                    setIdOfClosedMaintReq.add(mr.Id);
                }
            }
        }
        if (!setIdOfClosedMaintReq.isEmpty()){
            List<Case> listNewMaintRequests = new List<Case>();
            Map<Id,Decimal> mapMaintCycles = new Map<Id,Decimal>();
            Map<Id,Case> mapClosedMaintRequests = new Map<Id,Case>([
                SELECT Id,
                       Vehicle__c,
                       Equipment__c,
                       Equipment__r.Maintenance_Cycle__c,
                       (SELECT Id, Quantity__c, Equipment__c
                        FROM Equipment_Maintenance_Items__r)
                FROM Case
                WHERE Id IN :setIdOfClosedMaintReq
            ]);
            AggregateResult[] results = [SELECT Maintenance_Request__c,
                                                MIN(Equipment__r.Maintenance_Cycle__c)cycle
                                         FROM Equipment_Maintenance_Item__c
                                         WHERE Maintenance_Request__c IN :setIdOfClosedMaintReq
                                         GROUP BY Maintenance_Request__c];
            for (AggregateResult ar : results){
                mapMaintCycles.put((Id) ar.get('Maintenance_Request__c'), (Decimal) ar.get('cycle'));
            }
            for (Case cmr : mapClosedMaintRequests.values()){
                Case nmr = new Case (
                    ParentId = cmr.Id,
                    Status = 'New',
                    Subject = 'Routine Maintenance',
                    Type = 'Routine Maintenance',
                    Vehicle__c = cmr.Vehicle__c,
                    Equipment__c = cmr.Equipment__c,
                    Origin = 'Web',
                    Date_Reported__c = Date.Today()
                );
                if (mapMaintCycles.containskey(cmr.Id)){
                    nmr.Date_Due__c = Date.today().addDays((Integer) mapMaintCycles.get(cmr.Id));
                } /*else {
                    nmr.Date_Due__c = Date.today().addDays((Integer) cmr.Equipment__r.Maintenance_Cycle__c);
                }*/
                listNewMaintRequests.add(nmr);
            }
            insert listNewMaintRequests;
            List<Equipment_Maintenance_Item__c> listClonedEMI = new List<Equipment_Maintenance_Item__c>();
            for (Case nmr : listNewMaintRequests){
                for (Equipment_Maintenance_Item__c emi : mapClosedMaintRequests.get(nmr.ParentId).Equipment_Maintenance_Items__r){
                    Equipment_Maintenance_Item__c emiClone = emi.clone();
                    emiClone.Maintenance_Request__c = nmr.Id;
                    listClonedEMI.add(emiClone);
                }
            }
            insert listClonedEMI;
        }
    }
}