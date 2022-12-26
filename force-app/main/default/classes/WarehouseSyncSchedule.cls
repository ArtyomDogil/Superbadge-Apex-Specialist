global with sharing class WarehouseSyncSchedule implements Schedulable {
    global void execute(System.SchedulableContext context){
        System.enqueueJob(new WarehouseCalloutService());
    }
}