// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents






    // Create test data
    Ordering_Account__c testFacility = new Ordering_Account__c(
        FacilityName__c = 'Test Facility',
        Address__c = '123 Test Street',
        City__c = 'Test City',
        State__c = 'Test State',
        ZipCode__c = '12345',
        Country__c = 'Test Country'
    );
    
    // Insert test data
    insert testFacility;
    
    // Create a new Ordering_Account__c object with the same normalized values
    Ordering_Account__c inputFacility = new Ordering_Account__c(
        FacilityName__c = 'test facility',
        Address__c = '123 test street',
        City__c = 'test city',
        State__c = 'test state',
        ZipCode__c = '12345',
        Country__c = 'test country'
    );
    
    // Call the method
    Id resultId = QueryController.checkFacilityAlreadyExists(inputFacility);
    
    // Verify the result
    System.assertEquals(testFacility.Id, resultId, 'The method should return the correct Id for the existing facility.');

