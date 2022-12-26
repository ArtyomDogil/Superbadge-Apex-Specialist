@isTest
private class WarehouseCalloutServiceTest {
    @isTest
    static void testCallout(){
        Test.startTest();
        Test.setMock(HTTPCalloutMock.class, new WarehouseCalloutServiceMock());
        System.enqueueJob(new WarehouseCalloutService());
        Test.stopTest();
        System.assertEquals(1, [SELECT count() FROM Product2]);
    }
}