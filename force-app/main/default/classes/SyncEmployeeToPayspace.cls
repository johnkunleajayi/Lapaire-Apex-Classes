public class SyncEmployeeToPayspace {
    // Main method to get and send employee updates to Payspace
    public static void syncEmployeesToPayspace() {
        try {
            // Query for updated employee records in Salesforce
            List<flair__Employee__c> employeesToSync = [SELECT Id, flair__First_Name__c, flair__Employee_Number__c, flair__Last_Name__c, Payspace_EmployeeId__c, Payspace_Company_Id__c
                                                        FROM flair__Employee__c 
                                                        WHERE LastModifiedDate > :System.now().addHours(-1)];

            // Loop through employees and send updates to Payspace
            for (flair__Employee__c employee : employeesToSync) {
                // Retrieve Payspace configuration from Custom Metadata
                Payspace_Config__mdt config = [SELECT Client_ID__c, Client_Secret__c, URL__c, API_Base_URL__c 
                                               FROM Payspace_Config__mdt 
                                               WHERE MasterLabel = 'Payspace' 
                                               LIMIT 1];
                System.debug('Payspace Config: ' + config);
                
                if (config == null || config.Client_ID__c == null || config.Client_Secret__c == null || config.URL__c == null) {
                    System.debug('Payspace configuration is missing or incomplete.');
                    continue; // Skip to the next employee
                }

                // Log the configuration data
                System.debug('Client_ID: ' + config.Client_ID__c);
                System.debug('Client_Secret: ' + config.Client_Secret__c);
                System.debug('API Base URL: ' + config.API_Base_URL__c);
                System.debug('Payspace URL: ' + config.URL__c);

                // Prepare the data to be sent to Payspace
                Map<String, String> employeeData = new Map<String, String>{
                    'EmployeeId' => employee.Payspace_EmployeeId__c,
                    'EmployeeNumber' => employee.flair__Employee_Number__c,
                    'FirstName' => employee.flair__First_Name__c,
                    'LastName' => employee.flair__Last_Name__c
                };

                // Enqueue the Queueable class to perform the HTTP callout asynchronously
                System.enqueueJob(new PayspaceSyncQueueable(employeeData, employee.Payspace_Company_Id__c, employee.Payspace_EmployeeId__c));
            }

        } catch (Exception e) {
            System.debug('Error during synchronization: ' + e.getMessage());
        }
    }
}