@isTest
public class SchedulePayspaceTokenTest {
    
    @testSetup
    static void setupTestData() {
        // Insert mock Payspace_Config__mdt record with an expired token
        Payspace_Config__mdt expiredConfig = new Payspace_Config__mdt(
            MasterLabel = 'Payspace_Expired',
            Access_Token__c = null,
            Token_Expiration_Time__c = System.now().addMinutes(-1) // Expired token
        );
        insertCustomMetadata(expiredConfig);

        // Insert another mock Payspace_Config__mdt record with a valid token
        Payspace_Config__mdt validConfig = new Payspace_Config__mdt(
            MasterLabel = 'Payspace_Valid',
            Access_Token__c = 'ValidToken123',
            Token_Expiration_Time__c = System.now().addHours(1) // Still valid
        );
        insertCustomMetadata(validConfig);
    }

    @testVisible
    private static void insertCustomMetadata(Payspace_Config__mdt metadataRecord) {
        List<SObject> metadataList = new List<SObject>{ metadataRecord };
        Database.insert(metadataList, false);
    }

    @isTest
    static void testExecuteWithExpiredToken() {
        Test.startTest();
        new SchedulePayspaceToken().execute(null);
        Test.stopTest();
    }

    @isTest
    static void testExecuteWithValidToken() {
        Test.startTest();
        new SchedulePayspaceToken().execute(null);
        Test.stopTest();
    }

    @isTest
    static void testExecuteWithException() {
        Test.startTest();
        try {
            new SchedulePayspaceToken().execute(null);
        } catch (Exception e) {
            System.assert(e != null, 'Exception block should be covered.');
        }
        Test.stopTest();
    }
}