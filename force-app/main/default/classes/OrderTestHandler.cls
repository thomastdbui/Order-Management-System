public with sharing class OrderTestHandler {

    public static Map<String, Object> parseJson(String inputString) {
        System.debug('input String: ' + inputString);
        String tempKey;
        Object tempValue;
        
        Map<String, Object> input = new Map<String, Object>();
        JSONParser parsedMap = JSON.createParser(inputString);
        
        while(parsedMap.nextToken() != null) {
            if(parsedMap.getCurrentToken() == JSONToken.FIELD_NAME) {
                tempKey = parsedMap.getText();
                parsedMap.nextToken();
                
                if(parsedMap.getCurrentToken() == JSONToken.START_OBJECT) {
                    tempValue = parseJsonObject(parsedMap);
                } else {
                    tempValue = parsedMap.getText();
                }
                
                input.put(tempKey, tempValue);
            }
        }
        
        return input;
    }
    
    public static Map<String, Object> parseJsonObject(JSONParser parser) {
        Map<String, Object> nestedMap = new Map<String, Object>();
        String nestedKey;
        Object nestedValue;
        
        while(parser.nextToken() != JSONToken.END_OBJECT) {
            if(parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                nestedKey = parser.getText();
                parser.nextToken();
                
                if(parser.getCurrentToken() == JSONToken.START_OBJECT) {
                    nestedValue = parseJsonObject(parser);
                } else {
                    nestedValue = parser.getText();
                }
                
                nestedMap.put(nestedKey, nestedValue);
            }
        }
        
        return nestedMap;
    }
    public static void fillNextEmptyField(sObject obj, Object value) {
        Map<String, Object> populatedFields = obj.getPopulatedFieldsAsMap();
        // System.debug(populatedFields);
        for (Integer i = 1; i <= 5; i++) { // Adjust the limit as per your needs
            String fieldName = 'Test_Order_' + i + '__c';
            if (!populatedFields.containsKey(fieldName)) {
                obj.put(fieldName, value);
                break;
            }
        }
    }


    @AuraEnabled 
    public static String handleOrderTest(String inputString, String patientId, String physicianId, String facilityId) {

        Savepoint sp = Database.setSavepoint();

        try {      
            

            String tempKey;
            String tempValue;
            
            Map<String, Object> input = parseJson(inputString);

            

            // Check CRUD permissions
            if (!Schema.sObjectType.Patient__c.isCreateable() ||
                !Schema.sObjectType.Treating_Physician_Information__c.isCreateable() ||
                !Schema.sObjectType.Ordering_Account__c.isCreateable() ||
                !Schema.sObjectType.TestOrder__c.isCreateable() ||
                !Schema.sObjectType.PatientToOrder__c.isCreateable()) {
                return 'Error: Insufficient permissions to create records';
            }

            // Extract patient information
            Patient__c patientInfo = new Patient__c(
                FirstName__c = (String) input.get('firstName'),
                LastName__c = (String) input.get('lastName'),
                MI__c = (String) input.get('mi'),
                DOB__c = Date.valueOf((String) input.get('dob')),
                Sex__c = (String) input.get('sex'),
                MRN__c = (String) input.get('mrn'),
                Address__c = (String) ((Map<String, Object>) input.get('patientAddress')).get('street'),
                ZipCode__c = (String) ((Map<String, Object>) input.get('patientAddress')).get('postalCode'),
                City__c = (String) ((Map<String, Object>) input.get('patientAddress')).get('city'),
                State__c = (String) ((Map<String, Object>) input.get('patientAddress')).get('province'),
                Country__c = (String) ((Map<String, Object>) input.get('patientAddress')).get('country'),
                Phone__c = (String) input.get('patientPhone'),
                Email__c = (String) input.get('patientEmail')
            );
            // Insert records into Salesforce
            
            Id existingPatientId = QueryController.checkPatientAlreadyExists(patientInfo.MRN__c, patientInfo.DOB__c);
            if (existingPatientId != null) {
                patientInfo.id = existingPatientId;
                System.debug('upsert Patient ' + patientInfo.id);
                upsert patientInfo;
            } else {
                System.debug('insert Patient ' + patientInfo.id);
                insert patientInfo;
            }

            
            // Extract ordering facility information
            Ordering_Account__c orderingFacilityInfo = new Ordering_Account__c(
                FacilityName__c = (String) input.get('orderingFacilityName'),
                Address__c = (String) ((Map<String, Object>) input.get('orderingAddress')).get('street'),
                ZipCode__c = (String) ((Map<String, Object>) input.get('orderingAddress')).get('postalCode'),
                City__c = (String) ((Map<String, Object>) input.get('orderingAddress')).get('city'),
                State__c = (String) ((Map<String, Object>) input.get('orderingAddress')).get('province'),
                Country__c = (String) ((Map<String, Object>) input.get('orderingAddress')).get('country'),
                Phone__c = (String) input.get('orderingPhone'),
                Email__c = (String) input.get('orderingEmail')
                );
                System.debug('orderingFacilityInfo: ' + orderingFacilityInfo);
                

            Id existingFacilityId = QueryController.checkFacilityAlreadyExists(orderingFacilityInfo);
            if (existingFacilityId != null) {
                orderingFacilityInfo.id = existingFacilityId;
                System.debug('upsert Facility ' + orderingFacilityInfo.id);
                upsert orderingFacilityInfo;
            } else {
                System.debug('inserted Facility ' + orderingFacilityInfo.id);
                insert orderingFacilityInfo;
            }
                
            // Extract physician information
            Treating_Physician_Information__c physicianInfo = new Treating_Physician_Information__c(
                FirstName__c = (String) input.get('physicianFirstName'),
                LastName__c = (String) input.get('physicianLastName'),
                Phone__c = (String) input.get('physicianPhone'),
                Email__c = (String) input.get('physicianEmail'),
                NPI__c = (String) input.get('physicianNpi'),
                Ordering_Account__c = orderingFacilityInfo.Id
            );
            System.debug('physicianInfo: ' + physicianInfo);
            

            Id existingPhysicianId = QueryController.checkPhysicianAlreadyExists(physicianInfo.NPI__c);
            if (existingPhysicianId != null) {
                physicianInfo.id = existingPhysicianId;
                System.debug('upsert Physician ' + physicianInfo.id);
                upsert physicianInfo;
            } else {
                System.debug('inserted Physician ' + physicianInfo.id);
                insert physicianInfo;
            }

            // Create new TestOrder__c record
            TestOrder__c newObjectInfo = new TestOrder__c(
                Ordering_Account__c = orderingFacilityInfo.Id,
                Patient__c = patientInfo.Id,
                Treating_Physician_Information__c = physicianInfo.Id,
                TestMenu__c = (String) input.get('testMenu')
            );

            System.debug('newObjectInfo: ' + newObjectInfo);

            insert newObjectInfo;


            PatientToOrder__c patientToOrder = QueryController.getPatientToOrder(patientInfo.Id);
            if (patientToOrder == null) {
                patientToOrder = new PatientToOrder__c(
                    Patient__c = patientInfo.Id
                );
                insert patientToOrder;
            }

            System.debug('patientToOrder: ' + patientToOrder);

            fillNextEmptyField(patientToOrder, newObjectInfo.Id);

            System.debug('patientToOrder: ' + patientToOrder);

            update patientToOrder;

            // Add two new fields
            patientInfo.Treating_Physician_Information__c = physicianInfo.Id;
            patientInfo.Ordering_Account__c = orderingFacilityInfo.Id;
            patientInfo.patientToOrder__c = patientToOrder.Id;

            // Insert records into Salesforce
            update patientInfo;          

            return 'Form data received and saved in Salesforce';
    
        } catch (Exception e) {
            // Rollback to the savepoint if any of the inserts fail
            Database.rollback(sp);
            
            System.debug('General Exception: ' + e.getMessage());
            System.debug('Source: ' + e.getCause());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            System.debug('Exception Type: ' + e.getTypeName());
            throw new AuraHandledException(e.getMessage());

        }
    }

}