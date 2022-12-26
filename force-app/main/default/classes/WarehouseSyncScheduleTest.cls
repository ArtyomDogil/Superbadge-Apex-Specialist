@isTest
public class WarehouseSyncScheduleTest {
    public static String CRON_EXP = '0 0 1 * * ?';
    @isTest
    static void scheduleTest(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock());
        String jobID = System.schedule('Schedule Test', CRON_EXP, new WarehouseSyncSchedule());
        Test.stopTest();
        CronTrigger a = [SELECT Id FROM CronTrigger WHERE NextFireTime>today AND Id = :jobID];
        System.assertEquals(jobID, a.Id);
    }
}