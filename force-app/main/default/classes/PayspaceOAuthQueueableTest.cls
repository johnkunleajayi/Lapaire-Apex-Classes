@isTest
public class PayspaceOAuthQueueableTest {
    @testSetup
    static void setupTestData() {
        // Insert mock Payspace_Config__mdt record
        Payspace_Config__mdt config = new Payspace_Config__mdt(
            MasterLabel = 'Payspace',
            Client_ID__c = 'testClientId',
            Client_Secret__c = 'testClientSecret',
            URL__c = 'https://auth.test.com'
        );

        insertCustomMetadata(config);
    }

    @testVisible
    private static void insertCustomMetadata(Payspace_Config__mdt metadataRecord) {
        Test.startTest();
        List<SObject> metadataList = new List<SObject>{ metadataRecord };
        Database.insert(metadataList, false);
        Test.stopTest();
    }

    @isTest
    static void testExecute() {
        // Mock the HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Enqueue the Queueable job
        Test.startTest();
        System.enqueueJob(new PayspaceOAuthQueueable());
        Test.stopTest();

        System.assertEquals(null, PayspaceOAuthQueueable.getAccessToken());
    }

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"access_token":"mock-access-token", "expires_in":3600}');
            res.setStatusCode(200);
            return res;
        }
    }
}