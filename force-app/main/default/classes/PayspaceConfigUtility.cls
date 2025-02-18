public class PayspaceConfigUtility {
    
    // Method to get Payspace configuration
    public static Payspace_Config__mdt getPayspaceConfig() {
        // Query Custom Metadata for the Payspace configuration
        List<Payspace_Config__mdt> configs = [SELECT URL__c, API_Base_URL__c 
                                              FROM Payspace_Config__mdt 
                                              WHERE MasterLabel = 'Payspace' LIMIT 1];
        
        if (!configs.isEmpty()) {
            return configs[0];
        } else {
            throw new CustomException('Payspace configuration not found.');
        }
    }
    
    // Custom exception class to handle missing config scenario
    public class CustomException extends Exception {}
}