@isTest
private class EmployeeDocumentFileScheduler2Test {
    
    @testSetup
    static void setupTestData() {
        // Insert test data if EmployeeDocumentBatchProcessor processes specific records
    }
    
    @isTest
    static void testScheduledExecution() {
        Test.startTest();
        
        // Create an instance of the scheduler and execute it
        EmployeeDocumentFileScheduler2 scheduler = new EmployeeDocumentFileScheduler2();
        scheduler.execute(null);
        
        Test.stopTest();

        // Verify that a batch job was queued
        List<AsyncApexJob> jobs = [SELECT Id, Status, JobType FROM AsyncApexJob WHERE JobType = 'BatchApex' ORDER BY CreatedDate DESC];
        System.assert(!jobs.isEmpty(), 'Batch job should be enqueued.');
        System.assertEquals('Completed', jobs[0].Status, 'Batch job should have completed successfully.');
    }
}