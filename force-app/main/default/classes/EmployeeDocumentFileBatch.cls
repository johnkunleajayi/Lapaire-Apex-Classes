public class EmployeeDocumentFileBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {


    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, BambooHR_Employee_Id__c FROM flair__Employee__c WHERE BambooHR_Employee_Id__c != NULL'
        );
    }

    // ... (rest of the execute() and finish() methods remain exactly the same as the previous corrected version)
    public void execute(Database.BatchableContext bc, List<flair__Employee__c> scope) {
        List<flair__Employee_Document__c> documentsToInsert = new List<flair__Employee_Document__c>();
        Map<String, List<FileInformation>> employeeFiles = new Map<String, List<FileInformation>>();

        for (flair__Employee__c employee : scope) {
            try {
                BambooHR_Configuration__mdt config = BambooHR_Configuration__mdt.getInstance('Default');
                if (config == null) {
                    System.debug('No BambooHR configuration found in custom metadata.');
                    continue;
                }

                String apiEndpoint = config.API_Endpoint__c;
                String apiKey = config.API_Key__c;
                String organization = config.Organization__c;

                String endpoint = apiEndpoint + organization + '/v1/employees/' + employee.BambooHR_Employee_Id__c + '/files/view/';
                HttpRequest req = new HttpRequest();
                req.setEndpoint(endpoint);
                req.setMethod('GET');
                req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(apiKey + ':')));
                req.setHeader('Content-Type', 'application/json');

                Http http = new Http();
                HttpResponse res = http.send(req);

                if (res.getStatusCode() == 200) {
                    // Parse the XML response (Apex DOM parsing is a bit different)
                    Dom.Document doc = new Dom.Document();
                    doc.load(res.getBody());
                    Dom.XmlNode rootNode = doc.getRootElement();

                    List<Dom.XmlNode> categoryNodes = rootNode.getChildElements();
                    for (Dom.XmlNode categoryNode : categoryNodes) {
                        String categoryId = categoryNode.getAttributeValue('id', null);
                        String categoryName = '';

                        for (Dom.XmlNode childNode : categoryNode.getChildElements()) {
                            if (childNode.getName() == 'name') {
                                categoryName = childNode.getText();
                                break;
                            }
                        }

                        for (Dom.XmlNode fileNode : categoryNode.getChildElements()) {
                            if (fileNode.getName() == 'file') {
                                String fileId = fileNode.getAttributeValue('id', null);
                                String fileName = '';

                                for (Dom.XmlNode fileChildNode : fileNode.getChildElements()) {
                                    if (fileChildNode.getName() == 'name') {
                                        fileName = fileChildNode.getText();
                                        break;
                                    }
                                }

                                if (!employeeFiles.containsKey(employee.BambooHR_Employee_Id__c)) {
                                    employeeFiles.put(employee.BambooHR_Employee_Id__c, new List<FileInformation>());
                                }
                                employeeFiles.get(employee.BambooHR_Employee_Id__c).add(new FileInformation(fileId, fileName, categoryName));
                            }
                        }
                    }
                } else {
                    System.debug('Error response from BambooHR for employee ' + employee.BambooHR_Employee_Id__c + ': ' + res.getBody());
                }

            } catch (Exception e) {
                System.debug('Exception while retrieving file data for employee ' + employee.BambooHR_Employee_Id__c + ': ' + e.getMessage());
            }
        }

        // DML AFTER all callouts
        for (String employeeId : employeeFiles.keySet()) {
            List<FileInformation> files = employeeFiles.get(employeeId);
            Id employeeRecordId = getEmployeeRecordId(employeeId);
            if (employeeRecordId != null) {
                for (FileInformation fileInfo : files) {
                    flair__Employee_Document__c doc = new flair__Employee_Document__c();
                    doc.BambooHR_Employee_Id__c = employeeId;
                    doc.BambooHR_File_Id__c = fileInfo.fileId;
                    doc.Name = fileInfo.fileName.length() > 80 ? fileInfo.fileName.substring(0, 80) : fileInfo.fileName;
                    doc.Category_Id__c = fileInfo.categoryName;
                    doc.flair__Document_Category__c = 'a14Pu00000U6NvTIAV'; 
                    doc.flair__Employee1__c = employeeRecordId;
                    doc.flair__Visibility__c = 'HR+Manager+Employee';
                    documentsToInsert.add(doc);
                }
            } else {
                System.debug('No Employee record found for BambooHR ID: ' + employeeId);
            }
        }

        if (!documentsToInsert.isEmpty()) {
            insert documentsToInsert;
            System.debug('Inserted ' + documentsToInsert.size() + ' flair__Employee_Document__c records.');
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Batch process complete.');
    }

    private class FileInformation {
        public String fileId;
        public String fileName;
        public String categoryName;

        public FileInformation(String fileId, String fileName, String categoryName) {
            this.fileId = fileId;
            this.fileName = fileName;
            this.categoryName = categoryName;
        }
    }

    private Id getEmployeeRecordId(String bambooEmployeeId) {
        List<flair__Employee__c> employeeRecord = [
            SELECT Id
            FROM flair__Employee__c
            WHERE Country_Name__c = 'Burkina Faso' AND BambooHR_Employee_Id__c = :bambooEmployeeId
            LIMIT 1
        ];
        return employeeRecord.isEmpty() ? null : employeeRecord[0].Id;
    }
}