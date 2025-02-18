@isTest
private class EmployeeDocumentFileBatchTest {

    @testSetup
    static void setupTestData() {
        // Create test Employee records
        flair__Employee__c emp1 = new flair__Employee__c(
            Name = 'Test Employee 1',
            BambooHR_Employee_Id__c = '12345'
        );
        insert emp1;

        flair__Employee__c emp2 = new flair__Employee__c(
            Name = 'Test Employee 2',
            BambooHR_Employee_Id__c = '67890'
        );
        insert emp2;
    }

    @isTest
    static void testBatchExecution() {
        // Set up mock HTTP response using BambooHRMockResponse
        String mockResponseBody = '<?xml version="1.0" encoding="UTF-8"?><response><category id="1"><name>CategoryName</name><file id="98765"><name>testFile.pdf</name></file></category></response>';
        Test.setMock(HttpCalloutMock.class, new BambooHRMockResponse(200, mockResponseBody));

        // Create mock custom metadata configuration
        BambooHR_Configuration__mdt configMock = MockBambooHRConfig.getMockConfig();

        // Execute the batch
        Test.startTest();
        EmployeeDocumentFileBatch batch = new EmployeeDocumentFileBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify that the Employee_Document__c records were created
        flair__Employee_Document__c[] insertedDocs = [
            SELECT Id, Name, BambooHR_File_Id__c, flair__Employee1__c 
            FROM flair__Employee_Document__c 
            WHERE BambooHR_Employee_Id__c IN ('12345', '67890')
        ];
        
        System.assertEquals(2, insertedDocs.size(), 'Two Employee_Document__c records should be inserted.');
        System.assertEquals('testFile.pdf', insertedDocs[0].Name, 'File name should be testFile.pdf');
        System.assertEquals('98765', insertedDocs[0].BambooHR_File_Id__c, 'File ID should be 98765');
    }
}