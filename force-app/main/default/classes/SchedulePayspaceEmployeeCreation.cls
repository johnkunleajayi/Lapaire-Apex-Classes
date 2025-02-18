public class SchedulePayspaceEmployeeCreation implements Schedulable {
    public void execute(SchedulableContext sc) {
        try {
            // Query employees to be synced, filter out those already synced (Sync_With_Payspace = TRUE)
            List<flair__Employee__c> employeesToSync = [SELECT Id, flair__Employee_Number__c, flair__First_Name__c, flair__Last_Name__c,
                                                        flair__Company_Email__c, flair__Date_Of_Birth__c, flair__Gender__c, flair__Nationality__c,
                                                        flair__Entity__r.Name, Address_Line1__c, Address_Line2__c,
                                                        Address_Line3__c, Address_Code__c, flair__Country__c, 
                                                        Province__c, Created_on_Payspace__c 
                                                        FROM flair__Employee__c 
                                                        WHERE Created_on_Payspace__c = FALSE AND LastModifiedDate > YESTERDAY
                                                        LIMIT 50
                                                       ];
            
            // Enqueue the Queueable job for each employee
            for (flair__Employee__c employee : employeesToSync) {
                
                // Dynamically create initials
                String firstNameInitial = employee.flair__First_Name__c != null ? employee.flair__First_Name__c.substring(0, 1) : '';
                String lastNameInitial = employee.flair__Last_Name__c != null ? employee.flair__Last_Name__c.substring(0, 1) : '';
                String initials = firstNameInitial + lastNameInitial;
                
                Map<String, Object> employeeData = new Map<String, Object> {
                    'EmployeeNumber' => employee.flair__Employee_Number__c,
                        'Title' => 'Mr',
                        'CompanyFrequency'=> 'Monthly',
                        'FirstName' => employee.flair__First_Name__c,
                        'LastName' => employee.flair__Last_Name__c,
                        'Initials' => initials,
                        'Email' => employee.flair__Company_Email__c,
                        'Birthday' => String.valueOf(employee.flair__Date_Of_Birth__c),
                        'Gender' => employee.flair__Gender__c,
                        'Nationality' => employee.flair__Nationality__c,
                        'Citizenship' => employee.flair__Nationality__c,
                        
                        // Address Mapping
                        'Address' => new List<Map<String, String>>{
                            new Map<String, String> {
                                'AddressType' => 'Physical',
                                'AddressLine1' => employee.Address_Line1__c,
                                'AddressLine2' => employee.Address_Line2__c,
                                'AddressLine3' => employee.Address_Line3__c,
                                'AddressCode' => employee.Address_Code__c,
                                'AddressCountry' => employee.flair__Country__c,
                                'Province' => employee.Province__c,
                                'SameAsPhysical' => 'false',
                                'IsCareofAddress' => 'false'
                            },
                            new Map<String, String> {
                                'AddressType' => 'Postal',
                                'AddressLine1' => 'P.O. Box ' + employee.Address_Code__c,
                                'AddressLine2' => 'Central Post Office',
                                'AddressLine3' => employee.Address_Line3__c,
                                'AddressCode' => employee.Address_Code__c,
                                'AddressCountry' => employee.flair__Country__c,
                                'Province' => employee.Province__c,
                                'SameAsPhysical' => 'false',
                                'IsCareofAddress' => 'false'
                            }
                        }
                };
                
                // Check if the Entity Name is 'Benin' and include the custom field 'EEPOB'
                if (employee.flair__Entity__r.Name == 'Bénin') {
                    List<Map<String, Object>> customFields = new List<Map<String, Object>>{
                        new Map<String, Object>{
                            'Code' => 'EEPOB',
                            'Label' => 'place of birth',
                            'Value' => 'Benin',
                            'OptionCode' => null
                        }
                    };
                    
                    employeeData.put('CustomFields', customFields);
                }

                // Call Queueable job to send the employee to Payspace
                System.enqueueJob(new PayspaceEmployeeCreationQueueable(employeeData, employee.Id));
            }
        } catch (Exception e) {
            System.debug('Error while scheduling Payspace sync: ' + e.getMessage());
        }
    }
}