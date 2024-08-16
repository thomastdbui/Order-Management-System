import { LightningElement, track} from 'lwc';
import handleOrderTestApex from '@salesforce/apex/OrderTestHandler.handleOrderTest';
import searchPatientAccounts from '@salesforce/apex/QueryController.searchPatientAccounts';
import searchPhysicianAccounts from '@salesforce/apex/QueryController.searchPhysicianAccounts';
import searchFacilityAccounts from '@salesforce/apex/QueryController.searchFacilityAccounts';
import getFacilityFromId from '@salesforce/apex/QueryController.getFacilityFromId';
import getPhysicianFromId from '@salesforce/apex/QueryController.getPhysicianFromId';



export default class OrderForm extends LightningElement {

   
    @track patientPhoneNumber = '';
    @track physicianPhoneNumber = '';
    @track orderingPhoneNumber= '';
    @track isFormSubmitted = false;


    sexOptions = [
        { label: 'Male', value: 'male' },
        { label: 'Female', value: 'female' }
    ];

    testOptions = [
        { label: 'F1CDx', value: 'F1CDx' },
        { label: 'F1Heme', value: 'F1Heme' },
        { label: 'F1LCDx', value: 'F1LCDx' }
    ];

    @track apexError;

    patientId;
    physicianId;
    facilityId;

    

    handlePatientPhoneChange(event) {
        this.patientPhoneNumber = event.target.value;
        // Remove non-digits
        let cleaned = ('' + this.patientPhoneNumber).replace(/\D/g, '');
        let match = cleaned.match(/^(\d{3})(\d{3})(\d{4})$/);
        if (match) {
            this.patientPhoneNumber = match[1] + '-' + match[2] + '-' + match[3];
        }
    }

    handlePhysicianPhoneChange(event) {
        this.physicianPhoneNumber = event.target.value;
        // Remove non-digits
        let cleaned = ('' + this.physicianPhoneNumber).replace(/\D/g, '');
        let match = cleaned.match(/^(\d{3})(\d{3})(\d{4})$/);
        if (match) {
            this.physicianPhoneNumber = match[1] + '-' + match[2] + '-' + match[3];
        }
    }

    handleOrderingPhoneChange(event) {
        this.orderingPhoneNumber = event.target.value;
        // Remove non-digits
        let cleaned = ('' + this.orderingPhoneNumber).replace(/\D/g, '');
        let match = cleaned.match(/^(\d{3})(\d{3})(\d{4})$/);
        if (match) {
            this.orderingPhoneNumber = match[1] + '-' + match[2] + '-' + match[3];
        }
    }

    @track patientSearchTerm = '';
    @track patients;
    @track patientError;
    
    patientColumns = [
        {label: 'ID', fieldName: 'Name', type: 'text'},
        { label: 'First Name', fieldName: 'FirstName__c', type: 'text' },
        { label: 'Last Name', fieldName: 'LastName__c', type: 'text' },
        { label: 'Date of Birth', fieldName: 'DOB__c', type: 'text' },
        { label: 'Sex', fieldName: 'Sex__c', type: 'text' },
        { label: 'Middle Initial', fieldName: 'MI__c', type: 'text' },
        { label: 'Address', fieldName: 'Address__c', type: 'text' },
        { label: 'City', fieldName: 'City__c', type: 'text' },
        { label: 'State', fieldName: 'State__c', type: 'text' },
        { label: 'Zip', fieldName: 'ZipCode__c', type: 'text' }
    ];
    
    @track selecteedPatient;

  
    handlePatientInputChange(event) {
        this.patientSearchTerm = event.target.value;
        if (!this.patientSearchTerm) {
            this.patientError = undefined;
        }
        this.searchPatients();
    }

    searchPatients() {
        if (this.patientSearchTerm.length) { // Only search if the term is longer than 2 characters
            searchPatientAccounts({ patientSearchTerm: this.patientSearchTerm })
            .then(result => {
                    if (result.length !== 0) {
                        console.log(result);
                        this.patients = result;
                        this.patientError = undefined;
                    } else {
                        this.patients = undefined; // if there is no result, set accounts to undefined so no empty datatable is shown
                        this.patientError = "No results found!";
                    }
                })
                .catch(error => {
                    this.patientError = error.body.message;
                    this.patients = undefined;
                });

        } else {
            this.patients = undefined;
            this.patientError = undefined;
        }
    }

 


    // Mapping between input names and selectedPatient fields
    patientFieldMapping = {
        firstName: 'FirstName__c',
        lastName: 'LastName__c',
        mi: 'MI__c',
        dob: 'DOB__c',
        sex: 'Sex__c',
        mrn: 'MRN__c',
        patientPhone: 'Phone__c',
        patientEmail: 'Email__c',
        patientAddress: {
            street: 'Address__c',
            postalCode: 'ZipCode__c',
            city: 'City__c',
            province: 'State__c',
            country: 'Country__c'
        }
    };



    renderedCallback() {
        // Ensure the radio group reflects the correct value
        const sexRadioGroup = this.template.querySelector('lightning-radio-group[data-id="patientSex"]');
        if (sexRadioGroup) {
            sexRadioGroup.options = [...this.sexOptions];
        }
        // console.log("should be callbacking" + sexRadioGroup.options)
    }

    

    async handlePatientRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        if (selectedRows.length > 0) {
            this.selectedPatient = selectedRows[0];
            this.patientId = this.selectedPatient.Id;
            try {
                if (this.selectedPatient.Treating_Physician_Information__c) {
                    this.selectedPhysician = await getPhysicianFromId({ physicianId: this.selectedPatient.Treating_Physician_Information__c});
                    this.physicianId = this.selectedPhysician.Id;
                    this.autofillPhysician();
                } else {
                    this.selectedPhysician = undefined;
                }
                
                if (this.selectedPatient.Ordering_Account__c) {
                    this.selectedFacility = await getFacilityFromId({ facilityId: this.selectedPatient.Ordering_Account__c});
                    this.facilityId = this.selectedFacility.Id;
                    this.autofillFacility();
                } else {
                    this.selectedFacility = undefined;
                }
            } catch (error) {
                console.log(error);
            }
    
            this.autofillPatient();

            this.patients = undefined; // reset accounts after a patient is selected
        }
    }

    autofillPatient() {
        // Query all relevant inputs within the patient-info div
        const patientInputs = this.template.querySelectorAll('.patient-info lightning-input, .patient-info lightning-combobox');
            
        patientInputs.forEach(input => {
            const fieldName = this.patientFieldMapping[input.name];
            if (fieldName) {
                input.value = this.selectedPatient[fieldName];
            }
        });
        
        // Handle the lightning-radio-group separately
        const sexRadioGroup = this.template.querySelector('lightning-radio-group[data-id="patientSex"]');
        if (sexRadioGroup) {
            const sexFieldName = this.patientFieldMapping[sexRadioGroup.name];
            if (sexFieldName) {
                sexRadioGroup.value = this.selectedPatient[sexFieldName];
                // Force re-rendering of the radio group to ensure the selected value is highlighted
                sexRadioGroup.options = [...this.sexOptions];
                sexRadioGroup.value = this.selectedPatient[sexFieldName];
            }
        }
        
        // Handle the lightning-input-address separately
        const addressInput = this.template.querySelector('lightning-input-address[data-id="patientAddress"]');
        if (addressInput) {
            const addressFields = this.patientFieldMapping.patientAddress;
            Object.keys(addressFields).forEach(key => {
                addressInput[key] = this.selectedPatient[addressFields[key]];
            });
        }
    }



    @track physicianSearchTerm = '';
    @track physicians;
    @track physicianError;
    @track selectedPhysician;
    physicianColumns = [
        { label: 'ID', fieldName: 'Name', type: 'text'},
        { label: 'First Name', fieldName: 'FirstName__c' },
        { label: 'Last Name', fieldName: 'LastName__c' },
        { label: 'Phone', fieldName: 'Phone__c' },
        { label: 'Email', fieldName: 'Email__c' },
        { label: 'NPI', fieldName: 'NPI__c' }
    ];

    physicianFieldMapping = {
        physicianFirstName: 'FirstName__c',
        physicianLastName: 'LastName__c',
        physicianPhone: 'Phone__c',
        physicianEmail: 'Email__c',
        physicianNpi: 'NPI__c',
    };

    handlePhysicianInputChange(event) {
        this.physicianSearchTerm = event.target.value;
        if (!this.physicianSearchTerm) {
            this.physicianError = undefined;
        }
        this.searchPhysicians();
    }

    searchPhysicians() {
        if (this.physicianSearchTerm.length) {
            searchPhysicianAccounts({ physicianSearchTerm: this.physicianSearchTerm})
                .then(result => {
                    if (result.length !== 0) {
                        this.physicians = result;
                        this.physicianError = undefined;
                    } else {
                        this.physicians = undefined; // if there is no result, set accounts to undefined so no empty datatable is shown
                        this.physicianError = "No results found!";
                    }
                })
                .catch(error => {
                    this.physicians = undefined;
                    this.physicianError = error.body.message;
                });
        }
    }

    async handlePhysicianRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        if (selectedRows.length > 0) {

            this.selectedPhysician = selectedRows[0];
            this.physicianId = this.selectedPhysician.Id;

            this.autofillPhysician();


            try {
      
                if (this.selectedPhysician.Ordering_Account__c) {
                    this.selectedFacility = await getFacilityFromId({ facilityId: this.selectedPhysician.Ordering_Account__c});
                    this.facilityId = this.selectedFacility.Id;
                    this.autofillFacility();
                } else {
                    this.selectedFacility = undefined;
                }
            } catch (error) {
                console.log(error);
            }
      
    
            this.physicians = undefined; // reset accounts after a physician is selected
        }
    }

    autofillPhysician() {
        // Query all relevant inputs within the physician-info div
        if (this.selectedPhysician) {
            const physicianInputs = this.template.querySelectorAll('.physician-info lightning-input, .physician-info lightning-combobox');
                
            physicianInputs.forEach(input => {
                const fieldName = this.physicianFieldMapping[input.name];
                if (fieldName) {
                    input.value = this.selectedPhysician[fieldName];
                }
            });
        }
    }





    @track facilities;
    @track facilityError;
    @track facilitySearchTerm = '';
    @track selectedFacility;

    facilityColumns = [
        { label: 'ID', fieldName: 'Name', type: 'text'},
        { label: 'Facility Name', fieldName: 'FacilityName__c' },
        { label: 'Address', fieldName: 'Address__c' },
        { label: 'Zip Code', fieldName: 'ZipCode__c' },
        { label: 'City', fieldName: 'City__c' },
        { label: 'State', fieldName: 'State__c' },
        { label: 'Country', fieldName: 'Country__c' },
        { label: 'Phone', fieldName: 'Phone__c' },
        { label: 'Email', fieldName: 'Email__c' }
    ];
    
  

    facilityFieldMapping = {
        orderingFacilityName: 'FacilityName__c',
        orderingPhone: 'Phone__c',
        orderingEmail: 'Email__c',
        orderingAddress: {
            street: 'Address__c',
            postalCode: 'ZipCode__c',
            city: 'City__c',
            province: 'State__c',
            country: 'Country__c'
        }
    };



    handleFacilityInputChange(event) {
        this.facilitySearchTerm = event.target.value;
        if (!this.facilitySearchTerm) {
            this.facilityError = undefined;
        }
        this.searchFacilities();
    }

    searchFacilities() {
        if (this.facilitySearchTerm.length) {
            searchFacilityAccounts({ facilitySearchTerm: '%' + this.facilitySearchTerm + '%' })
                .then(result => {
                    if (result.length !== 0) {
                        this.facilities = result;
                        this.facilityError = undefined;
                    } else {
                        this.facilities = undefined;
                        this.facilityError = "No results found!";
                    }
                })
                .catch(error => {
                    this.facilityError = error.body.message;
                    this.facilities = undefined;
                });
        } else {
            this.facilities = undefined;
            this.facilityError = undefined;
        }
    }

    handleFacilityRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        if (selectedRows.length > 0) {
            this.selectedFacility = selectedRows[0];
            this.facilityId = this.selectedFacility.Id;

            this.autofillFacility();

            this.facilities = undefined; // reset accounts after a facility is selected
        }
    }

    autofillFacility() {
        // Query all relevant inputs within the facility-info div
        if (this.selectedFacility) {
            
            const facilityInputs = this.template.querySelectorAll('.facility-info lightning-input, .facility-info lightning-combobox');
            
            facilityInputs.forEach(input => {
                const fieldName = this.facilityFieldMapping[input.name];
                if (fieldName) {
                    input.value = this.selectedFacility[fieldName];
                }
            });
            
            // Handle the lightning-input-address separately
            const addressInput = this.template.querySelector('lightning-input-address[data-id="orderingAddress"]');
            if (addressInput) {
                const addressFields = this.facilityFieldMapping.orderingAddress;
                Object.keys(addressFields).forEach(key => {
                    addressInput[key] = this.selectedFacility[addressFields[key]];
                });
            }
        }
    }




    handleOrderTest() {
        // Handle the order test button click
        const inputs = this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-radio-group, lightning-input-address');
        let allValid = true;
        let allErrors = [];

        inputs.forEach(input => {
            if (!input.checkValidity()) {
                input.reportValidity();
                allValid = false;
                allErrors.push({   
                    name:input.name,
                    message:input.validationMessage 
                });
            }
        });
    
        let formData;

        if (allValid) {
            // Collect data and perform the action
            formData = {};
            inputs.forEach(input => {
                if (input.tagName === 'LIGHTNING-INPUT-ADDRESS') {
                    formData[input.dataset.id] = {
                        street: input.street,
                        city: input.city,
                        province: input.province,
                        postalCode: input.postalCode,
                        country: input.country
                    };
                } else {
                    formData[input.name] = input.value;
                }
            });
            console.log('Form Data:', JSON.stringify(formData));   
            console.log('Patient Id:', this.patientId);
            console.log('Physician Id:', this.physicianId);
            console.log('Facility Id:', this.facilityId);

            
            // Send form data to Apex
            handleOrderTestApex({ inputString: JSON.stringify(formData), patientId: this.patientId, physicianId: this.physicianId, facilityId: this.facilityId })
                .then(result => {
                    console.log('Apex Result:', result);
                    this.isFormSubmitted = true;
                })
                .catch(error => {
                    console.error('Error:', error);
                    if (error.body && error.body.message) {
                        console.error('Error Message:', error.body.message);
                    } 
                    if (error.body && error.body.stackTrace) {
                        console.error('Stack Trace:', error.body.stackTrace);
                    }
                });

            // clean up the form
            this.patientId = undefined;
            this.physicianId = undefined;
            this.facilityId = undefined;
            this.selectedPatient = undefined;  
            this.selectedPhysician = undefined;
            this.selectedFacility = undefined;
            this.patients = undefined;
            this.physicians = undefined;
            this.facilities = undefined;

        } else {
            console.error('Form is not valid', allErrors);
        }
    }
   
}
