public class SchedulePayspaceSync implements Schedulable {
    public void execute(SchedulableContext sc) {
        try {
            // Query the employees updated in the last hour
            List<flair__Employee__c> employeesToSync = [SELECT Id, flair__First_Name__c, flair__Employee_Number__c, 
                                                        Sync_With_Payspace__c, flair__Last_Name__c, Payspace_EmployeeId__c, 
                                                        Payspace_Company_Id__c
                                                        FROM flair__Employee__c 
                                                        WHERE Sync_With_Payspace__c = FALSE AND LastModifiedDate > YESTERDAY
                                                        LIMIT 50
                                                       ];

            // Loop through employees and enqueue the queueable job for each
            for (flair__Employee__c employee : employeesToSync) {
                Map<String, String> employeeData = new Map<String, String>{
                    'EmployeeId' => employee.Payspace_EmployeeId__c,
                    'EmployeeNumber' => employee.flair__Employee_Number__c,
                    'FirstName' => employee.flair__First_Name__c,
                    'LastName' => employee.flair__Last_Name__c
                };
                System.enqueueJob(new PayspaceSyncQueueable(employeeData, employee.Payspace_Company_Id__c, employee.Payspace_EmployeeId__c));
            }

        } catch (Exception e) {
            System.debug('Error while scheduling PayspaceSyncQueueable: ' + e.getMessage());
        }
    }
}