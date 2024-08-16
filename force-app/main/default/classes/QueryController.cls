public with sharing class QueryController {
    @AuraEnabled
    public static List<Patient__c> searchPatientAccounts(String patientSearchTerm) {
        try {
            System.debug('searchPatientAccount' + patientSearchTerm);
            String searchTerm = '%' + patientSearchTerm + '%';
            String query = 'SELECT Name, Id, firstName__c, mi__c, lastName__c, dob__c, sex__c, mrn__c, address__c, city__c, country__c, zipCode__c, phone__c, state__c, email__c, Treating_Physician_Information__c, Ordering_Account__c FROM Patient__c WHERE ' +
                           'firstName__c LIKE :searchTerm OR lastName__c LIKE :searchTerm or address__c LIKE: searchTerm or email__c LIKE:searchTerm or mrn__c LIKE: searchTerm';
            return Database.query(query);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Patient__c getPatientFromId(String patientId) {
        
        if (String.isBlank(patientId)) {
            System.debug('Patient ID cannot be null or empty.');
            throw new AuraHandledException('Patient ID cannot be null or empty.');
        }
        try{
            String query = 'SELECT Name, Id, firstName__c, mi__c, lastName__c, dob__c, sex__c, mrn__c, address__c, city__c, country__c, zipCode__c, phone__c, state__c, email__c, Treating_Physician_Information__c, Ordering_Account__c FROM Patient__c WHERE Id = :patientId';    
            List<Patient__c> results = Database.query(query);
            if (results != null && !results.isEmpty()) {
                return results[0];
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException('An error occurred while fetching the patient: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Id checkPatientAlreadyExists(String mrn, Date dob){
        try {
            String query = 'SELECT Id FROM Patient__c WHERE MRN__c = :mrn AND DOB__c = :dob';
            List<Patient__c> results = Database.query(query);
            if (results != null && !results.isEmpty()) {
                return results[0].Id;
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException('An error occurred while fetching the patient: ' + e.getMessage());
        }
    }  
    
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////            

    @AuraEnabled
    public static List<Treating_Physician_Information__c> searchPhysicianAccounts(String physicianSearchTerm) {
        try {
            
            String searchTerm = '%' + physicianSearchTerm + '%';
            String query = 'SELECT Name, Id, FirstName__c, LastName__c, Phone__c, Email__c, NPI__c, Ordering_Account__c FROM Treating_Physician_Information__c WHERE ' +
                    'FirstName__c LIKE :searchTerm OR LastName__c LIKE :searchTerm OR NPI__c LIKE :searchTerm';
            return Database.query(query);
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

    }
    
    @AuraEnabled
    public static Treating_Physician_Information__c getPhysicianFromId(String physicianId) {
        if (String.isBlank(physicianId)) {
            throw new AuraHandledException('Physician ID cannot be null or empty.');
        }
        
        try {
            String query = 'SELECT Name, Id, FirstName__c, LastName__c, Phone__c, Email__c, NPI__c, Ordering_Account__c FROM Treating_Physician_Information__c WHERE Id = :physicianId';
            List<Treating_Physician_Information__c> results = Database.query(query);
            if (results != null && !results.isEmpty()) {
                System.debug('Physician: ' + results[0]);
                return results[0];
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException('An error occurred while fetching the physician: ' + e.getMessage());
        }
    }

    @AuraEnabled    
    public static Id checkPhysicianAlreadyExists(String npi){
        try {
            String query = 'SELECT Id FROM Treating_Physician_Information__c WHERE NPI__c = :npi';
            List<Treating_Physician_Information__c> results = Database.query(query);
            if (results != null && !results.isEmpty()) {
                return results[0].Id;
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException('An error occurred while fetching the physician: ' + e.getMessage());
        }
    }
    
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    @AuraEnabled
    public static Ordering_Account__c getFacilityFromId(String facilityId) {
        if (String.isBlank(facilityId)) {
            System.debug('Facility ID cannot be null or empty.');
            throw new AuraHandledException('Facility ID cannot be null or empty.');
        }
        
        try {
            String query = 'SELECT Name, Id, FacilityName__c, Address__c, City__c, State__c, ZipCode__c, Country__c, Phone__c, Email__c FROM Ordering_Account__c WHERE Id = :facilityId';
            List<Ordering_Account__c> results = Database.query(query);
            if (results != null && !results.isEmpty()) {
                return results[0];
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException('An error occurred while fetching the facility: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Ordering_Account__c> searchFacilityAccounts(String facilitySearchTerm) {
        try {
            String searchTerm = '%' + facilitySearchTerm + '%';
            String query = 'SELECT Name, Id, FacilityName__c, Address__c, City__c, State__c, ZipCode__c, Country__c, Phone__c, Email__c FROM Ordering_Account__c WHERE ' +
                           'FacilityName__c LIKE :searchTerm OR Address__c LIKE :searchTerm';
            List<Ordering_Account__c> res = Database.query(query);
            return res;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    
    @AuraEnabled
    public static Id checkFacilityAlreadyExists(Ordering_Account__c orderingFacilityInfo){
        try {
            // Normalize input values
            String normalizedFacilityName = '%' + orderingFacilityInfo.FacilityName__c.toLowerCase() + '%';
            String normalizedAddress = '%' + orderingFacilityInfo.Address__c.toLowerCase() + '%';
            String normalizedZipCode = '%' + orderingFacilityInfo.ZipCode__c.toLowerCase() + '%';
            String normalizedCity = '%' + orderingFacilityInfo.City__c.toLowerCase() + '%';
            String normalizedState = '%' + orderingFacilityInfo.State__c.toLowerCase() + '%';
            String normalizedCountry = '%' + orderingFacilityInfo.Country__c.toLowerCase() + '%';

            // Construct the query
            String query = 'SELECT Id FROM Ordering_Account__c WHERE ' +
                        'FacilityName__c LIKE :normalizedFacilityName AND ' +
                        'Address__c LIKE :normalizedAddress AND ' +
                        'City__c LIKE :normalizedCity AND ' +
                        'State__c LIKE :normalizedState AND ' +
                        'ZipCode__c LIKE :normalizedZipCode AND ' +
                        'Country__c LIKE :normalizedCountry';

            // Execute the query
            List<Ordering_Account__c> results = Database.query(query);

            // Check for matching results
            if (results != null && !results.isEmpty()) {
                return results[0].Id;
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException('An error occurred while fetching the facility: ' + e.getMessage());
        }
    }

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@AuraEnabled
public static PatientToOrder__c getPatientToOrder(String patientId){
    try {
        String query = 'SELECT Id,Test_Order_1__c,Test_Order_2__c,Test_Order_3__c,Test_Order_4__c,Test_Order_5__c FROM PatientToOrder__c WHERE Patient__c = :patientId LIMIT 1';

        List<PatientToOrder__c> results = Database.query(query);
        if (results != null && !results.isEmpty()) {
            return results[0];
        }
        return null;
        
    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
}




}
