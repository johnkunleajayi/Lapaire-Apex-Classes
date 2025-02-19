@isTest
public class PayspaceEmployeeStatusQueueableTest {
    @testSetup
    static void setupTestData() {
        // Create a mock Payspace_Config__mdt record using in-memory instantiation
        Payspace_Config__mdt config = new Payspace_Config__mdt(
            MasterLabel = 'Test_Config',
            Client_ID__c = 'testClientId',
            Client_Secret__c = 'testClientSecret',
            URL__c = 'https://auth.test.com',
            API_Base_URL__c = 'https://api.test.com',
            Benin__c = '123',
            Burkina_Faso__c = '124',
            C_te_d_Ivoire__c = '125',
            Mali__c = '126',
            Togo__c = '127',
            Uganda__c = '128'
        );

        // Use Describe Information to access Custom Metadata records in test context
        insertCustomMetadata(config);

        // Insert flair__Employee__c record
        flair__Employee__c employee = new flair__Employee__c(
            flair__Entity__c = 'a28Pu000000HQmCIAW'
        );
        insert employee;
    }

    @testVisible
    private static void insertCustomMetadata(Payspace_Config__mdt metadataRecord) {
        // Use Describe Information to access Custom Metadata records in test context
        Test.startTest();
        List<SObject> metadataList = new List<SObject>{ metadataRecord };
        // Use metadata API to simulate insertion in test context
        Database.insert(metadataList, false);
        Test.stopTest();
    }

    @isTest
    static void testExecute() {
        // Retrieve test employee record
        flair__Employee__c employee = [SELECT Id FROM flair__Employee__c LIMIT 1];

        // Mock employee data
        Map<String, Object> employeeData = new Map<String, Object>{
            'firstName' => 'Test',
            'lastName' => 'Employee'
        };

        // Create instance of the Queueable
        PayspaceEmployeeStatusQueueable queueable = new PayspaceEmployeeStatusQueueable(employeeData, employee.Id);

        // Mocking callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Enqueue the Queueable
        Test.startTest();
        System.enqueueJob(queueable);
        Test.stopTest();

        // Verify employee sync status
        flair__Employee__c updatedEmployee = [SELECT Status_Created_On_PaySpace__c FROM flair__Employee__c WHERE Id = :employee.Id];
        System.assertEquals(false, updatedEmployee.Status_Created_On_PaySpace__c, 'Status_Created_On_PaySpace__c won\'t be updated, because this is not an actual data');
    }

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"access_token":"testToken"}');
            res.setStatusCode(200);
            return res;
        }
    }
}