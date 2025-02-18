@isTest
global class MockBambooHRCallout implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setHeader('Content-Type', 'application/pdf');

        // Simulating a binary PDF file content as Base64
        Blob dummyBlob = Blob.valueOf('Dummy PDF content');
        String base64Encoded = EncodingUtil.base64Encode(dummyBlob);
        res.setBody(base64Encoded);

        return res;
    }
}