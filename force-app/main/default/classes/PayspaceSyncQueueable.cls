public class PayspaceSyncQueueable implements Queueable, Database.AllowsCallouts {
    private Map<String, String> employeeData;
    private String payspaceCompanyId;
    private String payspaceEmployeeId;
    private String apiBaseUrl;
    private String authBaseUrl;
    private String clientId;
    private String clientSecret;

    public PayspaceSyncQueueable(Map<String, String> employeeData, String payspaceCompanyId, String payspaceEmployeeId) {
       
        // Retrieve Payspace configuration from custom metadata
        Payspace_Config__mdt config = [SELECT Client_ID__c, Client_Secret__c, URL__c, API_Base_URL__c 
                                       FROM Payspace_Config__mdt 
                                       LIMIT 1];
        
        if (config == null) {
            throw new CustomException('Payspace configuration is missing in Payspace_Config__mdt.');
        }

        this.employeeData = employeeData;
        this.payspaceCompanyId = payspaceCompanyId;
        this.payspaceEmployeeId = payspaceEmployeeId;
        this.apiBaseUrl = config.API_Base_Url__c;      // API Base URL
        this.authBaseUrl = config.URL__c;    // Authentication Base URL
        this.clientId = config.Client_Id__c;           // Client ID
        this.clientSecret = config.Client_Secret__c;   // Client Secret
    }

    public void execute(QueueableContext context) {
        try {
            // Retrieve access token using the authBaseUrl
            String accessToken = getAccessToken(authBaseUrl);

            // Ensure the Company ID is valid
            if (String.isEmpty(payspaceCompanyId)) {
                System.debug('Company ID is missing. Cannot proceed with the request.');
                return;
            }

            // Formulate the employee API URL using the apiBaseUrl
            String employeeUrl = apiBaseUrl + '/' + payspaceCompanyId + '/Employee(' + payspaceEmployeeId + ')';

            System.debug('Employee API URL: ' + employeeUrl);

            // Send PATCH request to update employee data
            HttpRequest req = new HttpRequest();
            req.setEndpoint(employeeUrl);
            req.setMethod('PATCH');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(employeeData));
            System.debug('Request Body: ' + req.getBody());

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 204) {
                System.debug('Employee data successfully sent to Payspace');
            } else {
                System.debug('Error sending data to Payspace. Status: ' + res.getStatusCode() + ', Response: ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Error while sending data to Payspace: ' + e.getMessage());
        }
    }

    private String getAccessToken(String authBaseUrl) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(authBaseUrl);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setBody('grant_type=client_credentials&client_id=' + EncodingUtil.urlEncode(clientId, 'UTF-8') +
                        '&client_secret=' + EncodingUtil.urlEncode(clientSecret, 'UTF-8'));

            System.debug('Token Request URL: ' + req.getEndpoint());
            System.debug('Request Body: ' + req.getBody());

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                String accessToken = (String) result.get('access_token');
                System.debug('Access Token Retrieved: ' + accessToken);
                return accessToken;
            } else {
                System.debug('Failed to retrieve access token. Status: ' + res.getStatusCode() + ', Response: ' + res.getBody());
                throw new CustomException('Failed to retrieve access token: ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Error while retrieving access token: ' + e.getMessage());
            throw new CustomException('Error while retrieving access token: ' + e.getMessage());
        }
    }
    
    private void updateEmployeeSyncStatus(Id employeeId) {
        try {
            flair__Employee__c employee = [SELECT Id, Sync_With_Payspace__c FROM flair__Employee__c WHERE Id = :employeeId LIMIT 1];
            employee.Sync_With_Payspace__c = TRUE;
            update employee;
        } catch (Exception e) {
            System.debug('Error updating employee Sync_With_Payspace__c: ' + e.getMessage());
        }
    }

    public class CustomException extends Exception {}
}