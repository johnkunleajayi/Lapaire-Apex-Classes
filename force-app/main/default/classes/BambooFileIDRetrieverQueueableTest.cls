@isTest
private class BambooFileIDRetrieverQueueableTest {
    
    @testSetup
    static void setupTestData() {
        // Create test Employee record
        flair__Employee__c emp = new flair__Employee__c(
            Name = 'Test Employee',
            BambooHR_Employee_Id__c = '12345'
        );
        insert emp;
    }
    
    @isTest
    static void testQueueableExecution() {
        // Set up mock HTTP response using BambooHRMockResponse
        String mockResponseBody = '<?xml version="1.0" encoding="UTF-8"?><response><category id="1"><name>CategoryName</name><file id="98765"><name>testFile.pdf</name></file></category></response>';
        Test.setMock(HttpCalloutMock.class, new BambooHRMockResponse(200, mockResponseBody));

        // Create mock custom metadata configuration
        BambooHR_Configuration__mdt configMock = MockBambooHRConfig.getMockConfig();
        
        Test.startTest();
        System.enqueueJob(new BambooFileIDRetrieverQueueable('12345', configMock));
        Test.stopTest();
        
        // Verify that the Employee_Document__c record was created
        flair__Employee_Document__c[] insertedDocs = [SELECT Id, Name, BambooHR_File_Id__c, flair__Employee1__c FROM flair__Employee_Document__c WHERE BambooHR_Employee_Id__c = '12345'];
        System.assertEquals(1, insertedDocs.size(), 'One Employee_Document__c record should be inserted.');
        System.assertEquals('testFile.pdf', insertedDocs[0].Name, 'File name should be testFile.pdf');
        System.assertEquals('98765', insertedDocs[0].BambooHR_File_Id__c, 'File ID should be 98765');
    }
}