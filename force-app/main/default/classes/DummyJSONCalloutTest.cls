/*
 * Update the ContactTrigger.trigger to do a callout to the DummyJSONCallout class to retrieve/send user data from the Dummy JSON API.
 * Implement the DummyJSONCallout class to handle the callouts to the Dummy JSON API.
 */
@IsTest
public with sharing class DummyJSONCalloutTest {
	// This test method will test the getDummyJSONUserFromId future method with a mock HTTP response.
	@IsTest
	static void testGetDummyJSONUserFromId() {
		// Create contact
		Contact cont = new Contact(FirstName = 'Test', LastName = 'User', DummyJSON_Id__c = '1');
		insert cont;
		// Register the mock callout class
		Test.setMock(HttpCalloutMock.class, new DummyJSONCalloutMockGenerator());

		// As this is a future method, we need to enclose it in Test.startTest() and Test.stopTest() to ensure it's executed in the test context.
		Test.startTest();
		DummyJSONCallout.getDummyJSONUserFromId('1'); // Call the method with an example userId
		Test.stopTest();

		// After the stopTest, the future method will have run. Now we can check if the contact was created correctly.
		cont = [
			SELECT Email, Phone, Birthdate, MailingStreet, MailingCity, MailingPostalCode, MailingState, MailingCountry
			FROM Contact
			WHERE DummyJSON_Id__c = '1'
		];

		// Assert statements to ensure that the values in the created contact match what was in our mock response.
		System.assertEquals('test@example.com', cont.Email, 'Email does not match your value: ' + cont.Email);
		System.assertEquals('+123456789', cont.Phone, 'Phone does not match your value: ' + cont.Phone);
		System.assertEquals(
			Date.valueOf('1990-01-01'),
			cont.Birthdate,
			'Birthdate does not match your value: ' + cont.Birthdate
		);
		System.assertEquals(
			'123 Test St',
			cont.MailingStreet,
			'MailingStreet does not match your value: ' + cont.MailingStreet
		);
		System.assertEquals(
			'Test City',
			cont.MailingCity,
			'MailingCity does not match your value: ' + cont.MailingCity
		);
		System.assertEquals(
			'12345',
			cont.MailingPostalCode,
			'MailingPostalCode does not match your value: ' + cont.MailingPostalCode
		);
		System.assertEquals('TS', cont.MailingState, 'MailingState does not match your value: ' + cont.MailingState);
		System.assertEquals(
			'Testland',
			cont.MailingCountry,
			'MailingCountry does not match your value: ' + cont.MailingCountry
		);
	}

	@isTest
	static void testPostCreateDummyJSONUser() {
		// Create a dummy contact to simulate the scenario
		Contact testContact = new Contact(
			FirstName = 'John',
			LastName = 'Doe',
			Email = 'john.doe@example.com',
			Phone = '+123456789'
		);
		insert testContact;

		// Set the mock callout class
		Test.setMock(HttpCalloutMock.class, new DummyJSONCalloutMockGenerator());

		// As this is a future method, we need to enclose it in Test.startTest() and Test.stopTest() to ensure it's executed in the test context.
		Test.startTest();
		DummyJSONCallout.postCreateDummyJSONUser(testContact.Id);
		Test.stopTest();

		// Retrieve the updated contact to verify the changes
		Contact updatedContact = [SELECT DummyJSON_Last_Updated__c FROM Contact WHERE Id = :testContact.Id];

		// Ensure that the DummyJSON_Last_Updated__c field was updated
		System.assertNotEquals(
			null,
			updatedContact.DummyJSON_Last_Updated__c,
			'The DummyJSON_Last_Updated__c field should have been updated.'
		);
	}

	@isTest
	static void testGenerateDummyJsonUserPayload() {
		// Prepare test data
		Contact testContact = new Contact(
			FirstName = 'John',
			LastName = 'Doe',
			Email = 'john.doe@example.com',
			Phone = '1234567890',
			DummyJSON_Id__c = '101'
		);
		insert testContact;

		// Call the method
		String payload = DummyJSONCallout.generateDummyJsonUserPayload(testContact.Id);

		// Parse the generated JSON
		Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(payload);

		// Assertions to check if the payload contains the right data
		System.assertEquals(testContact.Id, payloadMap.get('salesforceId'), 'Id does not match.');
		System.assertEquals('John', payloadMap.get('firstName'), 'FirstName does not match.');
		System.assertEquals('Doe', payloadMap.get('lastName'), 'LastName does not match.');
		System.assertEquals('john.doe@example.com', payloadMap.get('email'), 'Email does not match.');
		System.assertEquals('1234567890', payloadMap.get('phone'), 'Phone does not match.');
	}

	@isTest
	static void testCreateContactFromJson() {
		// JSON string that represents the response data
		String jsonResponse = DummyJSONCalloutMockGenerator.DUMMY_JSON_USER_PAYLOAD;

		// Call the method
		Contact cont = DummyJSONCallout.createContactFromJson(jsonResponse);

		// Assertions to check if the Contact object was populated correctly
		System.assertEquals('test@example.com', cont.Email, 'Email does not match.');
		System.assertEquals('+123456789', cont.Phone, 'Phone does not match.');
		System.assertEquals(Date.valueOf('1990-01-01'), cont.Birthdate, 'Birthdate does not match.');
		System.assertEquals('123 Test St', cont.MailingStreet, 'MailingStreet does not match.');
		System.assertEquals('Test City', cont.MailingCity, 'MailingCity does not match.');
		System.assertEquals('12345', cont.MailingPostalCode, 'MailingPostalCode does not match.');
		System.assertEquals('TS', cont.MailingState, 'MailingState does not match.');
		System.assertEquals('Testland', cont.MailingCountry, 'MailingCountry does not match.');
	}

	@IsTest
	static void testContactInsert() {
		//Create 100 contact
		List<Contact> contacts = new List<Contact>();
		for (Integer i = 0; i < 1; i++) {
			contacts.add(new Contact(FirstName = 'Test', LastName = 'User' + i));
		}

		// Register the mock callout class
		Test.setMock(HttpCalloutMock.class, new DummyJSONCalloutMockGenerator());

		// As this is a future method, we need to enclose it in Test.startTest() and Test.stopTest() to ensure it's executed in the test context.
		Test.startTest();
		Database.DMLOptions dml = new Database.DMLOptions();
		dml.DuplicateRuleHeader.allowSave = true;
		dml.DuplicateRuleHeader.runAsCurrentUser = true;
		Database.SaveResult[] sr = Database.insert(contacts, dml);
		Test.stopTest();

		// After the stopTest, the future method will have run. Now we can check if the contact was created correctly.
		contacts = [
			SELECT
				DummyJSON_Id__c,
				Email,
				Phone,
				Birthdate,
				MailingStreet,
				MailingCity,
				MailingPostalCode,
				MailingState,
				MailingCountry
			FROM Contact
			WHERE Id IN :contacts AND DummyJSON_Id__c != NULL
		];
		Assert.isTrue(!contacts.isEmpty(), 'No contacts were created');

		for (Contact cont : contacts) {
			Assert.isTrue(cont.DummyJSON_Id__c.isNumeric(), 'DummyJSON_Id is not numeric string');
			Integer dummyJSONId = Integer.valueOf(cont.DummyJSON_Id__c);
			Assert.isTrue(dummyJSONId >= 0 && dummyJSONId <= 100, 'Expected range of DummyJSON_Id is [0-100]');
		}
	}

	@IsTest
	static void testPostCreateDummyJSONUserAfterInsert() {
		// Create and insert a test contact
		Contact cont = new Contact(
			FirstName = 'Test',
			LastName = 'User',
			Email = 'test@example.com',
			Phone = '+123456789',
			DummyJSON_Id__c = '105'
		);
		insert cont;

		// Update the DummyJSON_Id__c to simulate the scenario where a contact gets a DummyJSON ID
		cont.DummyJSON_Id__c = '1';
		update cont;

		// Register the mock callout class
		Test.setMock(HttpCalloutMock.class, new DummyJSONCalloutMockGenerator());

		// Execute the future method within test context
		Test.startTest();
		DummyJSONCallout.postCreateDummyJSONUser(cont.Id);
		Test.stopTest();

		// Query the contact after the callout
		Contact updatedContact = [
			SELECT DummyJSON_Last_Updated__c, DummyJSON_Id__c
			FROM Contact
			WHERE Id = :cont.Id
		];

		// Verify the contact was updated correctly
		System.assertNotEquals(
			null,
			updatedContact.DummyJSON_Last_Updated__c,
			'DummyJSON_Last_Updated__c should be set after successful callout'
		);
		System.assertEquals('1', updatedContact.DummyJSON_Id__c, 'DummyJSON_Id__c should remain unchanged');
	}
}