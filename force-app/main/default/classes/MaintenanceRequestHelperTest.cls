@isTest
public with sharing class MaintenanceRequestHelperTest {
    private static List<Vehicle__c> createVehicle(Integer count, String nameVehicle){
        List<Vehicle__c> v = new List<Vehicle__c>();
        for (Integer i=0; i<count; i++){
            v.add(new Vehicle__c(Name = nameVehicle + ' ' + i));
        }
        return v;
    }
    private static List<Product2> createEquipment(Integer count, String nameEquip, Integer lifespan, Integer cycle, Boolean replacement){
        List<Product2> e = new List<Product2>();
        for (Integer i=0; i<count; i++){
            e.add(new Product2(Name = nameEquip + ' ' + i,
                               Lifespan_Months__c = lifespan,
                               Maintenance_Cycle__c = cycle,
                               Replacement_Part__c = replacement));
        }
        return e;
    }
    private static List<Case> createRoutineMaintRequest(Integer count, Id vehicleId, Id equipmentId){
        List<Case> c = new List<Case>();
        for (Integer i=0; i<count; i++){
            c.add(new Case(Type = 'Repair',
                           Status = 'Escalated',
                           Origin = 'Phone',
                           Subject = 'Repair',
                           Equipment__c = equipmentId,
                           Vehicle__c = vehicleId));
        }
        return c;
    }
    private static Equipment_Maintenance_Item__c createEMI(Id equipmentId, Id requestId){
        Equipment_Maintenance_Item__c emi = new Equipment_Maintenance_Item__c(Equipment__c = equipmentId,
                                                                              Maintenance_Request__c = requestId);
        return emi;
    }

    @isTest
    private static void testPositive(){
        List<Vehicle__c> vehicle = createVehicle(1, 'Test machine');
        insert vehicle;
        List<Product2> equipment = createEquipment(1, 'Test Equipment', 5, 5, true);
        insert equipment;
        List<Case> updatedMaintRequest = createRoutineMaintRequest(1, vehicle[0].Id, equipment[0].Id);
        insert updatedMaintRequest;
        Equipment_Maintenance_Item__c emi = createEMI(equipment[0].Id, updatedMaintRequest[0].Id);
        insert emi;
        updatedMaintRequest[0].status = 'Closed';
        Test.startTest();
        update updatedMaintRequest;
        Test.stopTest();
        Case newMaintRequest = [SELECT Id, Subject, Type, Equipment__c, Date_Reported__c, Vehicle__c, Date_Due__c
                                FROM Case
                                WHERE Status = 'New' AND Equipment__c = :updatedMaintRequest[0].Equipment__c AND Vehicle__c = :updatedMaintRequest[0].Vehicle__c];
        Equipment_Maintenance_Item__c newEMI = [SELECT Id
                                                FROM Equipment_Maintenance_Item__c
                                                WHERE Maintenance_Request__c = :newMaintRequest.Id];
        System.assert(newEMI != null);
        System.assert(newMaintRequest.Subject != null);
        System.assertEquals(newMaintRequest.Type, 'Routine Maintenance');
        System.assertEquals(newMaintRequest.Date_Reported__c, System.today());
    }

    @isTest
    private static void testNegative(){
        List<Vehicle__c> vehicle = createVehicle(1, 'Test machine');
        insert vehicle;
        List<Product2> equipment = createEquipment(1, 'Test Equipment', 5, 5, true);
        insert equipment;
        List<Case> updatedMaintRequest = createRoutineMaintRequest(1, vehicle[0].Id, equipment[0].Id);
        insert updatedMaintRequest;
        Equipment_Maintenance_Item__c emi = createEMI(equipment[0].Id, updatedMaintRequest[0].Id);
        insert emi;
        updatedMaintRequest[0].Status = 'Working';
        Test.startTest();
        update updatedMaintRequest;
        Test.stopTest();
        List<Case> listMaintRequests = [SELECT Id
                                        FROM Case];
        Equipment_Maintenance_Item__c newEMI = [SELECT Id
                                                FROM Equipment_Maintenance_Item__c
                                                WHERE Maintenance_Request__c = :updatedMaintRequest[0].Id];
        System.assert(newEMI != null);
        System.assert(listMaintRequests.size() == 1);
    }

    @isTest
    private static void testBulk(){
        List<Vehicle__c> listVehicles = createVehicle(300, 'Test machine');
        List<Product2> listEquipments = createEquipment(300, 'Test Equipment', 5, 5, true);
        insert listVehicles;
        insert listEquipments;
        List<Case> listMaintRequests = new List<Case>();
        List<Equipment_Maintenance_Item__c> listEMIs = new List<Equipment_Maintenance_Item__c>();
        List<Id> listOldRequestIds = new List<Id>();
        for (Integer i=0; i<300; i++){
            listMaintRequests.addAll(createRoutineMaintRequest(1, listVehicles.get(i).Id, listEquipments.get(i).Id));
        }
        insert listMaintRequests;
        for (Integer i = 0; i < 300; i++){
            listEMIs.add(createEMI(listEquipments.get(i).Id, listMaintRequests.get(i).Id));
        }
        insert listEMIs;
        Test.startTest();
        for (Case req : listMaintRequests){
            req.Status = 'Closed';
            listOldRequestIds.add(req.Id);
        }
        update listMaintRequests;
        Test.stopTest();
        List<Case> listNewMaintRequests = [SELECT Id
                                        FROM Case
                                        WHERE Status = 'New'];
        List<Equipment_Maintenance_Item__c> listNewEMIs = [SELECT Id
                                                           FROM Equipment_Maintenance_Item__c
                                                           WHERE Maintenance_Request__c IN :listOldRequestIds];
        System.assert(listNewEMIs != null);
        System.assert(listNewMaintRequests.size() == 300);
    }
}