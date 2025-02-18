public class BambooHRFileProcessingQueueable implements Queueable {
    public flair__Employee__c employee;

    public BambooHRFileProcessingQueueable(flair__Employee__c employee) {
        this.employee = employee;
    }

    public void execute(QueueableContext context) {
        BambooHR_Configuration__mdt config = BambooHR_Configuration__mdt.getInstance('Default');
        if (config == null) {
            System.debug('No BambooHR configuration found in custom metadata.');
            return;
        }

        String apiEndpoint = config.API_Endpoint__c;
        String apiKey = config.API_Key__c;
        String organization = config.Organization__c;
        List<flair__Employee_Document__c> documentsToInsert = new List<flair__Employee_Document__c>();

        String endpoint = apiEndpoint + organization + '/v1/employees/' + employee.BambooHR_Employee_Id__c + '/files/view/';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(apiKey + ':')));
        req.setHeader('Content-Type', 'application/json');

        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug('Response from BambooHR: ' + res.getBody());

        if (res.getStatusCode() == 200) {
            DOM.Document docm = new DOM.Document();
            docm.load(res.getBody());
            DOM.XmlNode rootNode = docm.getRootElement();

            for (DOM.XmlNode categoryNode : rootNode.getChildElements()) {
                String categoryId = categoryNode.getAttributeValue('id', null);
                String categoryName = '';

                for (DOM.XmlNode childNode : categoryNode.getChildElements()) {
                    if (childNode.getName() == 'name') {
                        categoryName = childNode.getText();
                        break;
                    }
                }

                for (DOM.XmlNode fileNode : categoryNode.getChildElements()) {
                    if (fileNode.getName() == 'file') {
                        String fileId = fileNode.getAttributeValue('id', null);
                        String fileName = '';

                        for (DOM.XmlNode fileChildNode : fileNode.getChildElements()) {
                            if (fileChildNode.getName() == 'name') {
                                fileName = fileChildNode.getText();
                                break;
                            }
                        }

                        // Truncate the file name to 80 characters
                        if (fileName.length() > 80) {
                            fileName = fileName.substring(0, 80);
                        }

                        flair__Employee_Document__c doc = new flair__Employee_Document__c();
                        doc.BambooHR_Employee_Id__c = employee.BambooHR_Employee_Id__c;
                        doc.BambooHR_File_Id__c = fileId;
                        doc.Name = fileName;
                        doc.Category_Id__c = categoryId;
                        doc.flair__Document_Category__c = 'a14QH000003SY5FYAW';
                        doc.flair__Employee1__c = employee.Id;

                        documentsToInsert.add(doc);
                        break; // Stop after inserting the first file
                    }
                }
            }

            // Insert records asynchronously to avoid hitting DML limits
            if (!documentsToInsert.isEmpty()) {
                insert documentsToInsert;
                System.debug('Inserted Employee_Document__c records.');
            }
        }
    }
}