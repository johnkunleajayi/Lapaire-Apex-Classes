public class PayspaceOAuthQueueable implements Queueable, Database.AllowsCallouts {
    public void execute(QueueableContext context) {
        // Perform the HTTP callout to get the access token
        String accessToken = getAccessToken();

        if (accessToken != null) {
            System.debug('Access Token: ' + accessToken);
        } else {
            System.debug('Failed to retrieve Access Token');
        }
    }

    public static String getAccessToken() {
        try {
            System.debug('Client ID: ' + getClientId());
            System.debug('Client Secret: ' + getClientSecret());
            System.debug('Token URL: ' + getTokenUrl());

            // Prepare the body of the POST request
            String body = 'client_id=' + getClientId() + '&' + 
                          'client_secret=' + getClientSecret() + '&' +
                          'grant_type=client_credentials&' +
                          'scope=api.full_access';

            // Prepare the HTTP request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(getTokenUrl());
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setBody(body);

            // Send the HTTP request
            Http http = new Http();
            HttpResponse res = http.send(req);

            // Handle response
            if (res.getStatusCode() == 200) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                String accessToken = (String) result.get('access_token');
                Integer expiresIn = (Integer) result.get('expires_in');

                // Update Access Token and Expiration Date in Custom Metadata
                updateCustomMetadata(accessToken, expiresIn);

                return accessToken;
            } else {
                System.debug('Error: ' + res.getStatus() + ' Response: ' + res.getBody());
                return null;
            }
        } catch (Exception e) {
            System.debug('Error while fetching access token: ' + e.getMessage());
            return null;
        }
    }

    private static String getTokenUrl() {
        Payspace_Config__mdt config = [SELECT URL__c FROM Payspace_Config__mdt WHERE MasterLabel = 'Payspace' LIMIT 1];
        if (config.URL__c == null) {
            throw new CustomException('Token URL is missing in Payspace_Config metadata');
        }
        return config.URL__c;
    }

    private static String getClientId() {
        Payspace_Config__mdt config = [SELECT Client_ID__c FROM Payspace_Config__mdt WHERE MasterLabel = 'Payspace' LIMIT 1];
        if (config.Client_ID__c == null) {
            throw new CustomException('Client ID is missing in Payspace_Config metadata');
        }
        return config.Client_ID__c;
    }

    private static String getClientSecret() {
        Payspace_Config__mdt config = [SELECT Client_Secret__c FROM Payspace_Config__mdt WHERE MasterLabel = 'Payspace' LIMIT 1];
        if (config.Client_Secret__c == null) {
            throw new CustomException('Client Secret is missing in Payspace_Config metadata');
        }
        return config.Client_Secret__c;
    }

    // Method to update the Custom Metadata record
    private static void updateCustomMetadata(String accessToken, Integer expiresIn) {
        try {
            // Prepare Custom Metadata record
            Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
            customMetadata.fullName = 'Payspace_Config.Testing_Token'; // Format: [MetadataType].[RecordName]
            
            // Set the MasterLabel (This is required)
            customMetadata.label = 'Payspace'; // Set the label as well

            // Add fields
            Metadata.CustomMetadataValue tokenField = new Metadata.CustomMetadataValue();
            tokenField.field = 'Access_Token__c'; // API name of the field
            tokenField.value = accessToken;

            Metadata.CustomMetadataValue expirationField = new Metadata.CustomMetadataValue();
            expirationField.field = 'Token_Expiration_Time__c'; // API name of the field
            expirationField.value = System.now().addSeconds(expiresIn);

            customMetadata.values.add(tokenField);
            customMetadata.values.add(expirationField);

            // Perform the metadata operation
            Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
            mdContainer.addMetadata(customMetadata);

            // Asynchronous deployment
            Id asyncRequestId = Metadata.Operations.enqueueDeployment(mdContainer, null);

            System.debug('Custom Metadata update enqueued. Async Request ID: ' + asyncRequestId);
        } catch (Exception e) {
            System.debug('Error updating Custom Metadata: ' + e.getMessage());
            throw new CustomException('Error updating Custom Metadata: ' + e.getMessage());
        }
    }

    public class CustomException extends Exception {}
}