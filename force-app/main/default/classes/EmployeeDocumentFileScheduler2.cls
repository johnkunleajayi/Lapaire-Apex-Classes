public class EmployeeDocumentFileScheduler2 implements Schedulable {
    public void execute(SchedulableContext sc) {
        System.debug('Scheduling the Batch Job for Employee Documents...');
        
        // Execute batch with reduced batch size
        Database.executeBatch(new EmployeeDocumentBatchProcessor(), 5);
    }
}