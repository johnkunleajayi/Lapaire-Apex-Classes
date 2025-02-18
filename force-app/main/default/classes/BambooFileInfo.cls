// Helper class to hold file info (fileId and employeeId)

public class BambooFileInfo {
	
    public String fileId { get; set; }
    public String employeeId { get; set; }
    
    public BambooFileInfo(String fileId, String employeeId) {
        this.fileId = fileId;
        this.employeeId = employeeId;
    }
}