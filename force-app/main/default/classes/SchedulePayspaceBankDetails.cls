public class SchedulePayspaceBankDetails implements Schedulable {
    public void execute(SchedulableContext sc) {
        try {
            // Query employees to be synced, filter out those already synced (Sync_With_Payspace = TRUE)
            List<flair__Employee__c> employeesToSync = [SELECT Id, flair__Employee_Number__c, Bank_Payment_Method__c, 
                                                        flair__Bank_Account_Owner__c, Bank_Account_Type__c, Bank_Name__c,
                                                        Bank_Branch__c, Bank_Account_Number_RIB__c, Bank_Details_Created_On_PaySpace__c
                                                        FROM flair__Employee__c 
                                                        WHERE Bank_Details_Created_On_PaySpace__c = FALSE
                                                        AND LastModifiedDate > YESTERDAY
                                                        LIMIT 50
                                                       ];
            
            // Enqueue the Queueable job for each employee
            for (flair__Employee__c employee : employeesToSync) {
                
                Map<String, Object> employeeData = new Map<String, Object> {
                    
                    	'BankDetailId' => 0, //This will be auto generated by PaySpace. No need to create this field is Salesforce
                        'EmployeeNumber' => employee.flair__Employee_Number__c,
                        'PaymentMethod' => employee.Bank_Payment_Method__c,
                        'BankAccountOwnerType' => employee.flair__Bank_Account_Owner__c, 
                        'AccountType' => employee.Bank_Account_Type__c,
                        'BankName' => employee.Bank_Name__c,
                        'BankBranchNo' => employee.Bank_Branch__c,
                        'BankAccountNo' => employee.Bank_Account_Number_RIB__c
                        
                        };
                            
                            // Call Queueable job to send the employee to Payspace
                            System.enqueueJob(new PayspaceBankDetailsQueueable(employeeData, employee.Id));
            }
        } catch (Exception e) {
            System.debug('Error while scheduling Payspace sync: ' + e.getMessage());
        }
    }
}