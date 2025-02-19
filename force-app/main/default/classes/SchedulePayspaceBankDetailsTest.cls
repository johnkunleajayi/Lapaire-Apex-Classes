@isTest
public class SchedulePayspaceBankDetailsTest {
    
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
                Bank_Account_Number_RIB__c = '00978868868',
                Bank_Payment_Method__c = 'Cash',
                Bank_Name__c = 'Access Bank',
                Bank_Account_Type__c = 'Savings',
                Bank_Branch__c = '123 Street',
                flair__Bank_Account_Owner__c = 'Joint',
                flair__Tax_Class__c = 'Diplomatic Missions',
                Bank_Details_Created_On_PaySpace__c = false // Needs syncing
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
        new SchedulePayspaceBankDetails().execute(null);
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