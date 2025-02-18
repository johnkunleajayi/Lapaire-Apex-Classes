public class BambooHRFileProcessingQueueable2 implements Queueable {
    public flair__Employee_Document__c document;

    public BambooHRFileProcessingQueueable2(flair__Employee_Document__c document) {
        this.document = document;
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

        String endpoint = apiEndpoint + organization + '/v1/employees/' + document.BambooHR_Employee_Id__c + '/files/view/';
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

                        // Create or update the document record
                        document.BambooHR_File_Id__c = fileId;
                        document.Name = fileName;
                        document.Category_Id__c = categoryId;

                        // Update or insert document as required
                        update document;
                        break; // Stop after inserting the first file
                    }
                }
            }
        }
    }
}