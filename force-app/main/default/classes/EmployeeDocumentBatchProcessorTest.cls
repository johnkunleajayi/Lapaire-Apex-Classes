@isTest 
public class EmployeeDocumentBatchProcessorTest {
    
    @testSetup 
    static void setupTestData() {
        
        List<flair__Employee_Document__c> testDocuments = new List<flair__Employee_Document__c>();
        for (Integer i = 0; i < 10; i++) {
            flair__Employee_Document__c doc = new flair__Employee_Document__c(
                Name = 'Test Document ' + i, 
                flair__Document_Category__c = 'a14QH000003SY5FYAW', 
                flair__Employee1__c = 'a1zPu000001IlSvIAK', 
                BambooHR_Employee_Id__c = 'EMP' + i, 
                BambooHR_File_Id__c = 'FILE' + i, 
                File_Created__c = false 
            );
            testDocuments.add(doc);
        }
        insert testDocuments;
    }
    
    @isTest 
    static void testEmployeeDocumentBatchProcessor() {
        // Set up the callout mock
        Test.setMock(HttpCalloutMock.class, new MockBambooHRCallout());

        // Start test execution
        Test.startTest();
        EmployeeDocumentBatchProcessor batch = new EmployeeDocumentBatchProcessor();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Verify if File_Created__c was updated
        List<flair__Employee_Document__c> processedDocuments = [
            SELECT Id, File_Created__c FROM flair__Employee_Document__c WHERE File_Created__c = TRUE
        ];
        System.assertEquals(10, processedDocuments.size(), 'All documents should have been processed.');
    }
}