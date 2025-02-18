public class SchedulePayspaceToken implements Schedulable {
    public void execute(SchedulableContext SC) {
        try {
            // Retrieve the stored token and its expiration date from Custom Metadata
            Payspace_Config__mdt config = [SELECT Access_Token__c, Token_Expiration_Time__c 
                                            FROM Payspace_Config__mdt 
                                            WHERE MasterLabel = 'Payspace' 
                                            LIMIT 1];
            
            // Check if the token has expired or is missing
            if (config == null || config.Access_Token__c == null || config.Token_Expiration_Time__c == null 
                || config.Token_Expiration_Time__c < System.now()) {
                // If expired or missing, enqueue the job to get a new token
                System.enqueueJob(new PayspaceOAuthQueueable());
                System.debug('Enqueued job to refresh token.');
            } else {
                System.debug('Token is valid and still active.');
            }
        } catch (Exception e) {
            System.debug('Error occurred while checking token: ' + e.getMessage());
        }
    }
}