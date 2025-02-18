public class EmployeeDocumentFileScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        System.debug('Starting the EmployeeDocumentFileScheduler...');

        // Execute the batch job to process employees in batches
        Integer batchSize = 1;
        Database.executeBatch(new EmployeeDocumentFileBatch(), batchSize);

        System.debug('Batch job executed.');
    }
}