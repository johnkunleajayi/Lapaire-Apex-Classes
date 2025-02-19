@isTest
public class SchedulePayspaceEmployeeCreationTest {
    
    @testSetup
    static void setupTestData() {
        // Create test Employee records that need syncing
        List<flair__Employee__c> employees = new List<flair__Employee__c>();
        for (Integer i = 0; i < 5; i++) {
            flair__Employee__c emp = new flair__Employee__c(
                flair__Employee_Number__c = 'EMP00' + i,
                flair__First_Name__c = 'Test' + i,
                flair__Last_Name__c = 'User' + i,
                flair__Company_Email__c = 'test' + i + '@example.com',
                flair__Date_Of_Birth__c = Date.newInstance(1990, 1, i + 1),
                flair__Gender__c = 'Male',
                flair__Nationality__c = 'Togo',
                flair__Country__c = 'Togo',
                Address_Line1__c = '123 Street ' + i,
                Address_Code__c = '10000',
                Province__c = 'Kara',
                Created_on_Payspace__c = false // Needs syncing
            );
            employees.add(emp);
        }
        insert employees;
    }

    @isTest
    static void testExecuteWithEmployees() {
        // Mocking the HTTP Callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Count jobs before execution
        Integer jobsBefore = [SELECT COUNT() FROM AsyncApexJob];

        // Execute the scheduled job
        Test.startTest();
        new SchedulePayspaceEmployeeCreation().execute(null);
        Test.stopTest();

        // Count jobs after execution
        Integer jobsAfter = [SELECT COUNT() FROM AsyncApexJob];

        // Assert that new queueable jobs were added
        System.assert(jobsAfter > jobsBefore, 'Queueable jobs should be enqueued.');
    }

    // Mock HTTP response generator
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            res.setStatusCode(200);
            return res;
        }
    }
}