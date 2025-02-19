public class PayspaceEmployeeCreationQueueable implements Queueable, Database.AllowsCallouts {
    
    private Map<String, Object> employeeData;  
    private Id employeeId;  
    
    // Constructor to accept Map<String, Object> and Id
    public PayspaceEmployeeCreationQueueable(Map<String, Object> employeeData, Id employeeId) {
        this.employeeData = employeeData;
        this.employeeId = employeeId;
    }
    
    public void execute(QueueableContext context) {
        try {
            // Retrieve Payspace configuration from Custom Metadata
            Payspace_Config__mdt config = [SELECT Client_ID__c, Client_Secret__c, URL__c, API_Base_URL__c, 
                                           Benin__c, Burkina_Faso__c, C_te_d_Ivoire__c, Mali__c, 
                                           Togo__c, Uganda__c 
                                           FROM Payspace_Config__mdt 
                                           LIMIT 1];
            if (config == null) {
                throw new CustomException('Payspace configuration is missing in Payspace_Config__mdt.');
            }
            
            // Get API base URL and Authentication details
            String apiBaseUrl = config.API_Base_URL__c;
            String authBaseUrl = config.URL__c;
            String clientId = config.Client_ID__c;
            String clientSecret = config.Client_Secret__c;
            
            // Fetch employee details (assuming Country__c stores the country name)
            flair__Employee__c employee = [SELECT Id, flair__Entity__r.Name FROM flair__Employee__c WHERE Id = :employeeId LIMIT 1];
            
            // Map country names to their respective numbers from metadata
            Map<String, String> countryCodeMap = new Map<String, String>{
                'Bénin' => config.Benin__c,
                    'Burkina Faso' => config.Burkina_Faso__c,
                    'Côte d\'Ivoire' => config.C_te_d_Ivoire__c,
                    'Mali' => config.Mali__c,
                    'Togo' => config.Togo__c,
                    'Uganda' => config.Uganda__c
                    };
                        
                        // Determine the correct country number based on the employee's country
                        String countryNumber = countryCodeMap.containsKey(employee.flair__Entity__r.Name) ? countryCodeMap.get(employee.flair__Entity__r.Name) : 'defaultNumber';
            
            // Prepare the API URL for the employee creation request
            String employeeUrl = apiBaseUrl + '/' + countryNumber + '/Employee';
            
            // Get Access Token
            String accessToken = getAccessToken(authBaseUrl, clientId, clientSecret);       
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(employeeUrl);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(employeeData));  // Serialize the employee data
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            
            // Log the response status and body
            System.debug('Response Status: ' + res.getStatusCode());
            System.debug('Response Body: ' + res.getBody());
            
            
            // Handle the response
            if (res.getStatusCode() == 201) {
                // Success: Mark employee as synced
                updateEmployeeSyncStatus(employeeId);
                System.debug('Employee created successfully in Payspace.');
            } else {
                System.debug('Failed to create employee in Payspace. Status: ' + res.getStatusCode() + ', Response: ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Error while syncing employee to Payspace: ' + e.getMessage());
        }
    }
    
    private String getAccessToken(String authBaseUrl, String clientId, String clientSecret) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(authBaseUrl);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setBody('grant_type=client_credentials&client_id=' + EncodingUtil.urlEncode(clientId, 'UTF-8') +
                        '&client_secret=' + EncodingUtil.urlEncode(clientSecret, 'UTF-8'));
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                return (String) result.get('access_token');
            } else {
                throw new CustomException('Failed to retrieve access token: ' + res.getBody());
            }
        } catch (Exception e) {
            throw new CustomException('Error while retrieving access token: ' + e.getMessage());
        }
    }
    
    
    private void updateEmployeeSyncStatus(Id employeeId) {
        try {
            flair__Employee__c employee = [SELECT Id, Created_on_Payspace__c FROM flair__Employee__c WHERE Id = :employeeId LIMIT 1];
            employee.Created_on_Payspace__c = TRUE;
            update employee;
        } catch (Exception e) {
            System.debug('Error updating employee Created_on_Payspace__c: ' + e.getMessage());
        }
    }
    
    public class CustomException extends Exception {}
}