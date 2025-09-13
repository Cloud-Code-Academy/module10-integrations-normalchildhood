/*
 * DummyJSONCallout Class Description:
 *
 * This class, DummyJSONCallout, facilitates HTTP callouts to an external system (presumably 'DummyJsonUser' in this context)
 * to either fetch or send user information based on a given identifier. The class supports both GET (to fetch data)
 * and POST (to send data) operations.
 *
 * Overview of HTTP Callouts:
 *
 * HTTP callouts are a way for Salesforce to communicate with external systems using HTTP protocols. Through HTTP callouts,
 * you can invoke external web services, collect data from them, or send data for further processing. Apex provides
 * classes that enable you to both send and receive HTTP data. The primary classes for this are `HttpRequest`, which
 * represents the request you're sending, and `HttpResponse`, which represents the response you receive.
 *
 * Best Practices:
 * 1. Handle Exceptions: Always handle exceptions that might be thrown, to ensure your code doesn't break unexpectedly.
 * 2. Named Credentials: Use Named Credentials to store endpoint URLs and authentication details securely.
 * 3. Test Callouts: Use mock classes and interfaces to test HTTP callouts without making actual callouts.
 *
 * For more detailed information on HTTP callouts in Apex, refer to the official Salesforce documentation:
 * https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_classes_restful_http_httprequest.htm
 */

public with sharing class DummyJSONCallout {
    
    /*
     * Question 1
     * Fetches user information from an external system https://dummyjson.com/user/{id} ('DummyJsonUser') based on the provided dummy user ID.
     * If the callout is successful and returns an HTTP status of 200, the method will update a contact based on the DummyJSON_Id__c with the data returned from the external system.
     * Use the createContactFromJson method to parse the JSON response and create a Salesforce Contact object.
     * Documentation: https://dummyjson.com/docs/users
     * This callout method should work in triggers
     *
     * @param dummyUserId The ID of the user in the external system to fetch data for.
     */
    
    public static void getDummyJSONUserFromId(String dummyUserId) {
        getDummyJSONUserFromId(new List<String>{ dummyUserId });
    }
    
    @future(callout=true)
    public static void getDummyJSONUserFromId(List<String> dummyUserIds) {
        Http http = new Http();
        List<Contact> contactsToUpsert = new List<Contact>();
        
        for (String userId : dummyUserIds) {
            try {
                HttpRequest request = new HttpRequest();
                request.setEndpoint('callout:DummyJsonUser/' + userId);
                request.setMethod('GET');
                
                HttpResponse response = http.send(request);
                
                if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
                    Contact cont = createContactFromJson(response.getBody());
                    if (cont != null) {
                        cont.DummyJSON_Id__c = userId;
                        contactsToUpsert.add(cont);
                    }
                }
            } catch (Exception e) {
                System.debug('Error fetching user ' + userId + ': ' + e.getMessage());
            }
        }
        
        if (!contactsToUpsert.isEmpty()) {
            upsert contactsToUpsert DummyJSON_Id__c;
        }
    }
    /*
     * Question 2
     * Transforms a JSON response from the external system https://dummyjson.com/users into a Salesforce Contact object.
     * The method parses the JSON string to extract user details and map them to a Salesforce Contact object.
     * The contact fields populated from the JSON include Email, Phone, Birthdate, and various address-related fields.
     * The method is primarily designed to work in conjunction with callouts that fetch user details from the external system.
     *
     * Fields from JSON used to populate Salesforce Contact
     * Fields: Email, Phone, Birthdate, MailingStreet, MailingCity, MailingPostalCode, MailingState, MailingCountry
     *
     * Documentation: https://dummyjson.com/docs/users
     *
     * @param String jsonResponse The JSON string from the external system that contains user details.
     * @return Contact The Salesforce Contact object populated with details from the JSON string.
     */
    @TestVisible // Allows test class to see this method. Since it is private, it would not be visible otherwise.
    
    private static Contact createContactFromJson(String jsonResponse) {
        // Deserialize the JSON string into map of primitive data types.
        Contact cont = new Contact();
        
        try {
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
            
            // Email
            if (data.containsKey('email')) {
                cont.Email = (String) data.get('email');
            }
            // Phone
            if (data.containsKey('phone')) {
                cont.Phone = (String) data.get('phone');
            }
            // Birthdate
            if (data.containsKey('birthDate') && data.get('birthDate') != null) {
                cont.Birthdate = Date.valueOf((String) data.get('birthDate'));
            }
            
            // Address block
            if (data.containsKey('address')) {
                Map<String, Object> addr = (Map<String, Object>) data.get('address');
                
                cont.MailingStreet = (addr.containsKey('address') ? (String) addr.get('address') : null);
                cont.MailingCity = (addr.containsKey('city') ? (String) addr.get('city') : null);
                cont.MailingPostalCode = (addr.containsKey('postalCode') ? String.valueOf(addr.get('postalCode')) : null);
                cont.MailingState = (addr.containsKey('state') ? (String) addr.get('state') : null);
                cont.MailingCountry = (addr.containsKey('country') ? (String) addr.get('country') : null);
            }
        } catch (Exception ex) {
            System.debug('Error parsing DummyJSON response: ' + ex.getMessage());
            return null;
        }
        
        return cont;
    }
    
    
    /*
     * Question 3
     * Sends Contact information to an external system https://dummyjson.com/users/add ('DummyJsonUser') to
     * create or update a user based on the provided Salesforce Contact ID.
     * The method prepares a JSON payload with the contact's information and sends it to the 'DummyJsonUser' add endpoint.
     * If the callout is successful (HTTP status code between 200 and 299), the method updates the contact's
     * 'DummyJSON_Last_Updated__c' field in Salesforce to the current time.
     * Salesforce Contact should be used to generate the JSON payload
     * Fields: Id, FirstName, LastName, Email, Phone
     * This callout method should work in triggers
     *
     * Documentation: https://dummyjson.com/docs/users
     *
     * @param contactId The Salesforce Contact ID used to generate the JSON payload for the external system.
     */
    
    public static void postCreateDummyJSONUser(Id contactId) {
        postCreateDummyJSONUser(new List<Id>{ contactId });
    }
    
    public static void postCreateDummyJSONUser(List<Id> contactIds) {
        if (contactIds == null || contactIds.isEmpty()) {
            return;
        }
        List<Contact> contactList = [SELECT Id FROM Contact WHERE Id IN :contactIds];
        List<Contact> toUpdate = new List<Contact>();
        // Create HTTP request to send.
        Http http = new http();
        
        for (Contact cont : contactList) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:DummyJsonUser');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(generateDummyJsonUserPayload(cont.Id));
            
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() >= 200 && res.getStatusCode() <= 299) {
                cont.DummyJSON_Last_Updated__c = System.now();
                toUpdate.add(cont);
            }
        }
        
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
    
    
    /*
     * Question 4
     * Generates a JSON payload based on a Salesforce Contact's fields to be sent to an external system https://dummyjson.com/users/add for user creation or update.
     * The method queries a contact from Salesforce based on the provided contactId and maps its fields into a JSON payload.
     * The fields from Salesforce Contact that are transformed into the JSON payload include Id, FirstName, LastName, Email, and Phone.
     * The generated JSON payload can be sent to the external system for various operations like creating or updating a user.
     *
     * Fields from Salesforce Contact used to generate JSON payload:
     * Fields: Id => salesforceId, FirstName => firstName, LastName => lastName, Email => email, Phone => phone
     *
     * Documentation: https://dummyjson.com/docs/users
     *
     * @param String contactId The Salesforce Contact ID used to fetch the contact's fields and generate the JSON payload.
     * @return String The JSON string payload that represents the Contact's details.
     */
    @TestVisible // Allows test class to see this method. Since it is private, it would not be visible otherwise.
    private static String generateDummyJsonUserPayload(Id contactId) {
        Contact c = [
        SELECT Id, FirstName, LastName, Email, Phone, DummyJSON_Id__c
        FROM Contact
        WHERE Id = :contactId
        LIMIT 1
    ];
        
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('salesforceId', c.Id);
        payload.put('firstName', c.FirstName);
        payload.put('lastName', c.LastName);
        payload.put('email', c.Email);
        payload.put('phone', c.Phone);
        payload.put('dummyJsonId', c.DummyJSON_Id__c);
        
        return JSON.serialize(payload);
    }
}