@isTest
public class BambooHRMockResponseTest {
    @isTest
    static void testMockResponse() {
        // Create a mock response with status code 200 and a sample JSON body
        Integer expectedStatusCode = 200;
        String expectedBody = '{"status": "success", "message": "Mock response received"}';

        BambooHRMockResponse mockResponse = new BambooHRMockResponse(expectedStatusCode, expectedBody);

        // Create a mock HTTP request
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.bamboohr.com/mock-endpoint');
        request.setMethod('GET');

        // Get the mock response
        HttpResponse response = mockResponse.respond(request);

        // Assertions to validate the response
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(expectedStatusCode, response.getStatusCode(), 'Status code should match');
        System.assertEquals(expectedBody, response.getBody(), 'Response body should match');
    }
}