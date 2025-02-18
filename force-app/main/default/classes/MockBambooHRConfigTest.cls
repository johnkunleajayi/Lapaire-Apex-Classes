@isTest
public class MockBambooHRConfigTest {
    @isTest
    static void testGetMockConfig() {
        // Get the mock configuration
        BambooHR_Configuration__mdt mockConfig = MockBambooHRConfig.getMockConfig();
        
        // Assertions to validate the mock data
        System.assertNotEquals(null, mockConfig, 'Mock configuration should not be null');
        System.assertEquals('https://api.bamboohr.com/', mockConfig.API_Endpoint__c, 'API Endpoint should match');
        System.assertEquals('fake-api-key', mockConfig.API_Key__c, 'API Key should match');
        System.assertEquals('testOrg', mockConfig.Organization__c, 'Organization should match');
    }
}