public class EmployeeDocumentBatchProcessor implements Database.Batchable<SObject>, Database.AllowsCallouts {

    // Query Locator for the batch
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, BambooHR_Employee_Id__c, BambooHR_File_Id__c 
            FROM flair__Employee_Document__c 
            WHERE BambooHR_Employee_Id__c != NULL 
            AND BambooHR_File_Id__c != NULL
            AND File_Created__c = FALSE
            LIMIT 200
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<flair__Employee_Document__c> scope) {
        // Define a batch size for enqueuing Queueable jobs
        Integer maxBatchSize = 50;
        
        // Split the scope into smaller chunks
        List<List<flair__Employee_Document__c>> recordBatches = splitIntoBatches(scope, maxBatchSize);
        
        for (List<flair__Employee_Document__c> batch : recordBatches) {
            System.enqueueJob(new BambooFileProcessorQueueableBatch(batch));
        }
    }
    
    // Helper method to split records into smaller batches
    private List<List<flair__Employee_Document__c>> splitIntoBatches(List<flair__Employee_Document__c> records, Integer batchSize) {
        List<List<flair__Employee_Document__c>> batches = new List<List<flair__Employee_Document__c>>();
        Integer totalRecords = records.size();
        
        for (Integer i = 0; i < totalRecords; i += batchSize) {
            List<flair__Employee_Document__c> batch = new List<flair__Employee_Document__c>();
            for (Integer j = i; j < Math.min(i + batchSize, totalRecords); j++) {
                batch.add(records[j]);
            }
            batches.add(batch);
        }
        
        return batches;
    }
    
    // Finish method
    public void finish(Database.BatchableContext bc) {
        System.debug('Batch processing completed.');
    }
}