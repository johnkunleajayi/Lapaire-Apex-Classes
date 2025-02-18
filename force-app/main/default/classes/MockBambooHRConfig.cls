public class MockBambooHRConfig {
    public static BambooHR_Configuration__mdt getMockConfig() {
        BambooHR_Configuration__mdt config = new BambooHR_Configuration__mdt();
        config.API_Endpoint__c = 'https://api.bamboohr.com/';
        config.API_Key__c = 'fake-api-key';
        config.Organization__c = 'testOrg';
        return config;
    }
}