public class BambooFileProcessorQueueableBatch implements Queueable, Database.AllowsCallouts {
    private List<flair__Employee_Document__c> employeeDocs;
    
    // Constructor to accept the list of Employee_Document__c records
    public BambooFileProcessorQueueableBatch(List<flair__Employee_Document__c> employeeDocs) {
        this.employeeDocs = employeeDocs;
    }
    
    public void execute(QueueableContext context) {
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
        List<flair__Employee_Document__c> docsToUpdate = new List<flair__Employee_Document__c>(); // To track docs with updated checkbox
        
        // Fetch custom metadata values
        BambooHR_Configuration__mdt bambooSettings = BambooHR_Configuration__mdt.getInstance('Default_Configuration');
        String baseBambooUrl = bambooSettings.Base_URL__c;
        String authKey = bambooSettings.Authorization_Key__c;
        
        for (flair__Employee_Document__c doc : employeeDocs) {
            String bambooHrFileUrl = baseBambooUrl + doc.BambooHR_Employee_Id__c + '/files/' + doc.BambooHR_File_Id__c + '/';
            
            try {
                // Make the callout to BambooHR
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint(bambooHrFileUrl);
                request.setMethod('GET');
                request.setHeader('Authorization', 'Basic ' + authKey);
                HttpResponse response = http.send(request);
                
                if (response.getStatusCode() == 200) {
                    // Only mark File_Created__c as true when the file is successfully fetched
                    
                    Blob fileBlob = response.getBodyAsBlob(); //Original Code

                    String contentType = response.getHeader('Content-Type');
                    String fileExtension = contentType.contains('pdf') ? '.pdf' : (contentType.contains('image') ? '.jpg' : '.txt');
                    String fileName = 'EmployeeFile_' + Datetime.now().getTime() + fileExtension;
                    
                    // Create ContentVersion object
                    ContentVersion contentVersion = new ContentVersion();
                    contentVersion.Title = fileName;
                    contentVersion.PathOnClient = fileName;
                    contentVersion.VersionData = fileBlob;
                    contentVersion.IsMajorVersion = true;
                    contentVersionList.add(contentVersion);
                    
                    // Temporarily associate the ContentVersion with the Employee Document
                    ContentDocumentLink tempCdl = new ContentDocumentLink();
                    tempCdl.LinkedEntityId = doc.Id;
                    contentDocumentLinkList.add(tempCdl);
                    
                    // Mark the record as processed (Set File_Created__c to true) only after successful file processing
                    doc.File_Created__c = true;
                    docsToUpdate.add(doc); // Add to update list after marking
                } else {
                    // Log failure but do not update File_Created__c
                    System.debug('Failed to fetch file. Status Code: ' + response.getStatusCode());
                }
            } catch (Exception e) {
                System.debug('Error processing record ' + doc.Id + ': ' + e.getMessage());
            }
        }
        
        // Perform DML outside of the loop for ContentVersion and ContentDocumentLink insertion
        if (!contentVersionList.isEmpty()) {
            try {
                insert contentVersionList;
                
                // Create a Map to store the relationship between ContentVersion.Id and Employee_Document__c.Id
                Map<Id, Id> contentVersionToEmployeeDocMap = new Map<Id, Id>();
                
                // Populate the map after inserting ContentVersions
                for (Integer i = 0; i < contentVersionList.size(); i++) {
                    contentVersionToEmployeeDocMap.put(contentVersionList[i].Id, employeeDocs[i].Id);
                }
                
                // Query ContentVersion to get ContentDocumentId
                List<ContentVersion> insertedContentVersions = [
                    SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersionToEmployeeDocMap.keySet()
                ];
                
                // Create ContentDocumentLinks
                List<ContentDocumentLink> finalContentDocumentLinks = new List<ContentDocumentLink>();
                for (ContentVersion cv : insertedContentVersions) {
                    if (contentVersionToEmployeeDocMap.containsKey(cv.Id)) {
                        ContentDocumentLink cdl = new ContentDocumentLink();
                        cdl.ContentDocumentId = cv.ContentDocumentId;
                        cdl.LinkedEntityId = contentVersionToEmployeeDocMap.get(cv.Id); // Employee_Document__c.Id
                        cdl.ShareType = 'V';
                        cdl.Visibility = 'AllUsers';
                        finalContentDocumentLinks.add(cdl);
                    }
                }
                
                // Insert ContentDocumentLinks
                if (!finalContentDocumentLinks.isEmpty()) {
                    try {
                        insert finalContentDocumentLinks;
                        System.debug('Files uploaded and linked successfully.');
                    } catch (DmlException e) {
                        System.debug('Error inserting ContentDocumentLinks: ' + e.getMessage());
                    }
                }
            } catch (DmlException e) {
                System.debug('Error inserting ContentVersions: ' + e.getMessage());
            }
        }
        
        // Update all Employee Document records with File_Created__c set to true
        if (!docsToUpdate.isEmpty()) {
            try {
                update docsToUpdate; // Bulk update only the modified records
                System.debug('Employee Document records updated successfully.');
            } catch (DmlException e) {
                System.debug('Error updating Employee Document records: ' + e.getMessage());
            }
        }
    }
}