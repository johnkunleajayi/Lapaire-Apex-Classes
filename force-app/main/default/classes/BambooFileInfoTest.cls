@isTest
private class BambooFileInfoTest {
    @isTest
    static void testBambooFileInfo() {
        // Arrange
        String testFileId = '12345';
        String testEmployeeId = 'EMP001';
        
        // Act
        BambooFileInfo fileInfo = new BambooFileInfo(testFileId, testEmployeeId);
        
        // Assert
        System.assertEquals(testFileId, fileInfo.fileId, 'File ID should match the expected value');
        System.assertEquals(testEmployeeId, fileInfo.employeeId, 'Employee ID should match the expected value');
    }
}