public class BambooFileIDRetrieverQueueable implements Queueable, Database.AllowsCallouts { 
    private String employeeId;
    private BambooHR_Configuration__mdt config;
    
    public BambooFileIDRetrieverQueueable(String employeeId) {
        this(employeeId, BambooHR_Configuration__mdt.getInstance('Default'));
    }
    
    public BambooFileIDRetrieverQueueable(String employeeId, BambooHR_Configuration__mdt config) {
        this.employeeId = employeeId;
        this.config = config;
    }
    
    private Id getEmployeeRecordId(String bambooEmployeeId) {
        flair__Employee__c employeeRecord = [
            SELECT Id 
            FROM flair__Employee__c 
            WHERE Country_Name__c = 'Burkina Faso' AND BambooHR_Employee_Id__c = :bambooEmployeeId
            LIMIT 1
        ];
        return employeeRecord != null ? employeeRecord.Id : null;
    }
    
    public void execute(QueueableContext context) {
        List<BambooFileInfo> fileDataList = new List<BambooFileInfo>();
        List<flair__Employee_Document__c> documentsToInsert = new List<flair__Employee_Document__c>();
        
        try {
            // Fetch configuration from custom metadata
            if (config == null) {
                System.debug('No BambooHR configuration found.');
                return;
            }
            
            String apiEndpoint = config.API_Endpoint__c;
            String apiKey = config.API_Key__c;
            String organization = config.Organization__c;
            
            // Prepare the request URL
            String endpoint = apiEndpoint + organization + '/v1/employees/' + employeeId + '/files/view/';
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(apiKey + ':')));
            req.setHeader('Content-Type', 'application/json');
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            System.debug('Response from BambooHR: ' + res.getBody());
            
            if (res.getStatusCode() == 200) {
                // Parse the XML response
                DOM.Document docm = new DOM.Document();
                docm.load(res.getBody());
                DOM.XmlNode rootNode = docm.getRootElement();
                
                // Iterate through category nodes
                List<DOM.XmlNode> categoryNodes = rootNode.getChildElements();
                for (DOM.XmlNode categoryNode : categoryNodes) {
                    String categoryId = categoryNode.getAttributeValue('id', null); // Category ID
                    String categoryName = '';
                    
                    // Find the 'name' child element for category
                    List<DOM.XmlNode> categoryChildNodes = categoryNode.getChildElements();
                    for (DOM.XmlNode childNode : categoryChildNodes) {
                        if (childNode.getName() == 'name') {
                            categoryName = childNode.getText(); // Category Name
                            break;
                        }
                    }

                    System.debug('Category ID: ' + categoryId);
                    System.debug('Category Name: ' + categoryName);

                    // Iterate through file nodes within the category
                    for (DOM.XmlNode fileNode : categoryNode.getChildElements()) {
                        if (fileNode.getName() == 'file') {
                            String fileId = fileNode.getAttributeValue('id', null); // File ID
                            String fileName = '';
                            
                            // Find the 'name' child element for file
                            for (DOM.XmlNode fileChildNode : fileNode.getChildElements()) {
                                if (fileChildNode.getName() == 'name') {
                                    fileName = fileChildNode.getText(); // File Name
                                    break;
                                }
                            }

                            System.debug('File ID: ' + fileId);
                            System.debug('File Name: ' + fileName);

                            // Create BambooFileInfo and flair__Employee_Document__c records
                            BambooFileInfo fileInfo = new BambooFileInfo(fileId, employeeId);
                            fileDataList.add(fileInfo);
                            
                            flair__Employee_Document__c doc = new flair__Employee_Document__c();
                            doc.BambooHR_Employee_Id__c = employeeId;
                            doc.BambooHR_File_Id__c = fileId;
                            doc.Name = fileName;
                            doc.Category_Id__c = categoryName;
                            doc.flair__Visibility__c = 'HR+Manager+Employee';
                            doc.flair__Document_Category__c = 'a14Pu00000U6NvTIAV'; // Use category name
                            doc.flair__Employee1__c = getEmployeeRecordId(employeeId); // Get Employee record ID
                            
                            documentsToInsert.add(doc);
                        }
                    }
                }
            } else {
                System.debug('Error response from BambooHR: ' + res.getBody());
            }
            
            // Insert documents into Salesforce
            if (!documentsToInsert.isEmpty()) {
                insert documentsToInsert;
                System.debug('Inserted ' + documentsToInsert.size() + ' Employee_Document__c records.');
            }
        } catch (Exception e) {
            System.debug('Exception while retrieving or inserting file data: ' + e.getMessage());
        }
    }
}