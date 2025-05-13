/*
 * DummyJSONCalloutMockGenerator Class Description:
 * 
 * The DummyJSONCalloutMockGenerator class serves as a mock for HTTP callouts to the DummyJsonUser service. This mock allows you to simulate 
 * the behavior of an HTTP callout in test methods, without making a call to the actual external service. This ensures that test methods 
 * are kept isolated and are not dependent on the availability or behavior of the external service.
 * 
 * Overview of HttpCalloutMock:
 * 
 * 1. Isolation: By using HttpCalloutMock, test methods can avoid dependencies on external services.
 * 2. Flexibility: Allows simulating different HTTP responses based on the request, aiding in testing various scenarios.
 * 3. Efficiency: Reduces the test execution time as actual callouts are not made.
 * 4. Governance: Salesforce enforces that actual HTTP callouts cannot be made from test methods. HttpCalloutMock provides a way to test methods that make callouts.
 * 
 * For more detailed information on HttpCalloutMock, refer to the official Salesforce documentation: 
 * https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_interface_httpcalloutmock.htm
 */
public with sharing class DummyJSONCalloutMockGenerator implements HttpCalloutMock {
	public static String DUMMY_JSON_USER_PAYLOAD = '{"id": 1, "firstName":"Johnny", "lastName":"Test", "email": "test@example.com", "phone": "+123456789", "birthDate": "1990-01-01", "address": {"address": "123 Test St", "city": "Test City", "postalCode": "12345", "state": "TS", "country": "Testland"}}';

	public HTTPResponse respond(HTTPRequest req) {
		// Create a fake response
		HttpResponse res = new HttpResponse();
		res.setHeader('Content-Type', 'application/json');

		// Check if the request is a POST request
		if (req.getMethod() == 'POST') {
			// Return a success response for the POST request
			res.setBody('{"status": "success"}');
		} else {
			// Return the dummy user details for the GET request
			res.setBody(DUMMY_JSON_USER_PAYLOAD);
		}
		res.setStatusCode(200);
		return res;
	}
}