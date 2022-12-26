public with sharing class WarehouseCalloutService implements Queueable, Database.AllowsCallouts{
    private static final String WAREHOUSE_URL = 'https://th-superbadge-apex.herokuapp.com/equipment';
    public static void execute(QueueableContext context){
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(WAREHOUSE_URL);
        req.setMethod('GET');
        HttpResponse res = http.send(req);
        List<Product2> listEquipmentFromWarehouse = new List<Product2>();
        if (res.getStatusCode() == 200){
            List<Object> jsonResponse = (List<Object>)JSON.deserializeUntyped(res.getBody());
            for (Object item : jsonResponse){
                Map<String,Object> mapJsonItem = (Map<String,Object>)item;
                Product2 equipment = new Product2();
                equipment.Replacement_Part__c = (Boolean) mapJsonItem.get('replacement');
                equipment.Name = (String) mapJsonItem.get('name');
                equipment.Maintenance_Cycle__c = (Integer) mapJsonItem.get('maintenanceperiod');
                equipment.Lifespan_Months__c = (Integer) mapJsonItem.get('lifespan');
                equipment.Cost__c = (Integer) mapJsonItem.get('cost');
                equipment.Warehouse_SKU__c = (String) mapJsonItem.get('sku');
                equipment.Current_Inventory__c = (Double) mapJsonItem.get('quantity');
                equipment.ProductCode = (String) mapJsonItem.get('_id');
                listEquipmentFromWarehouse.add(equipment);
            }
            if (listEquipmentFromWarehouse.size() > 0){
                upsert listEquipmentFromWarehouse;
            }
        }
    }
}