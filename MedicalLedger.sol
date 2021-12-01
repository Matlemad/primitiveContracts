// SPDX-License-Identifier: GPL-3.0
 
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;
 
import "@openzeppelin/contracts/access/Ownable.sol";
 
// primitive Patient-centric registry for Clinical Trials (not ready for production, privacy must be upgraded)
 
// Owner can be a DataCoop DAO, governed by voting

// a whitelist of DataClients is implemented, trusted Clients can be added by the DataCoop DAO

// Exams are added in the form of a URI (a link) that retrieve the records from a hypothetical Healthcare IPFS
 
contract MedicalLedger is Ownable {
 
    address payable dataCoopTreasury; // the wallet of the DataCoop
 
    event PatientEdit(address patient, bool allowance);
    event DoctorEdit(address doctor, bool allowance);
    event ClientEdit(address client, bool allowance);
    event TreasuryAdded(address wallet);
    event ExamRequest(string testResult);
 
    struct Exam {
        uint examId; // e.g. "000" is blood test, "056" is xRay etc
        string resultsURI; // a hypothetical IPFS of Hospitals
    }
 
    Exam[] public exams; // a list of all the exam structs
 
    mapping(address => bool) public patients; // patients addresses are added by the DataCoop
    mapping(address => bool) public doctors; // doctors addresses are added by the DataCoop
    mapping(address => mapping(uint => string)) private patientTestResults; // connects patients' addresses to exam IDs and results
 
    // for Data Clients 
    mapping(address => bool) public trustedClients; // whitelist of trusted Clients
    uint public priceViewExam; // the set price Clients pay to view exams
 
    //modifiers: special requirements for functions
    modifier onlyDoctor {
        require(doctors[msg.sender] == true, "Revert: not a doctor");
        _;
    }
 
    modifier isTrusted {
        require(trustedClients[msg.sender] == true,"Revert: not trusted");
        _;
    }
 
    // Owner DataCoop deploys the contract, adds doctors, sets the first price and adds a treasury wallet address
 
    constructor(address[] memory _newDoctors, uint _newPrice, address payable _treasury) {
        require(_newDoctors.length > 0, "addresses[] required");
        require(_newPrice != 0, "Can't set current price as future price");
        priceViewExam = _newPrice;
        dataCoopTreasury = _treasury;
        for (uint i = 0; i < _newDoctors.length; i++) {
            address newDoctor = _newDoctors[i];
            require(newDoctor != address(0), "invalid address");
            require(!doctors[newDoctor], "Doctor already added");
            doctors[newDoctor] = true;
            emit DoctorEdit(newDoctor, true);
        }
        emit TreasuryAdded(_treasury);
    }
    // Owner DataCoop adds new doctors (can also be done via arrays as above)
    function addDoctor(address _newDoctor) external onlyOwner {
        require(!doctors[_newDoctor], "Officer already allowed");
        doctors[_newDoctor] = true;
        emit DoctorEdit(_newDoctor, true);
    }
 
    // Owner DataCoop removes doctors
    function removeDoctor(address _oldDoc) external onlyOwner {
        require(doctors[_oldDoc], "Cannot delete unassigned account");
        doctors[_oldDoc] = false;
        emit DoctorEdit(_oldDoc, false);
    }
 
    // Owner DataCoop adds new patients
    function addPatient(address _newPatient) external onlyOwner {
        require(!patients[_newPatient], "Patient already saved");
        patients[_newPatient] = true;
        emit PatientEdit(_newPatient, true);
    }
 
    // Owner DataCoop removes old patients
    function removePatient(address _oldPatient) external onlyOwner {
        require(patients[_oldPatient], "Cannot delete unassigned account");
        patients[_oldPatient] = false;
        emit PatientEdit(_oldPatient, false);
    }

    // Owner DataCoop sets a Treasury
    function editTreasury(address _newTreasury) external onlyOwner {
        _newTreasury = dataCoopTreasury;
        emit TreasuryAdded(_newTreasury);
    }

    // Owner DataCoop adds trustworthy clients
    function addClient(address _newClient) external onlyOwner {
        require(!trustedClients[_newClient], "Client already saved");
        trustedClients[_newClient] = true;
        emit ClientEdit(_newClient, true);
    }
 
    // Owner DataCoop removes not trustworthy clients
    function removeClient(address _oldClient) external onlyOwner {
        require(trustedClients[_oldClient], 'Cannot delete unassigned account');
        trustedClients[_oldClient] = false;
        emit ClientEdit(_oldClient, false);
    }
 
    // Doctors only: add/update a patient's exam URI
    function updateExam(address _patient, uint _examId, string memory _resultsURI) public onlyDoctor {
        require(_patient != address(0), "invalid address");
        require(patients[_patient], "Can't add exams to non existing patient");
        exams.push(Exam(_examId, _resultsURI));
        patientTestResults[_patient][_examId] = _resultsURI;
    }
    
    // Owner DataCoop can set a new price for viewing exams URIs
    function setViewPrice(uint _newPrice) external onlyOwner {
        require(_newPrice != priceViewExam && _newPrice != 0, "Can't set current price as future price");
        priceViewExam = _newPrice;
    }
 
    // only trusted addresses (Clients): pay the ViewPrice and retrieve a given Patient's exam URI
    function payPerViewExam(address payable _patient, uint _examId, uint _price) public payable isTrusted {
        require(patients[_patient], "Patient doesn't exist!");
        require(_price >= priceViewExam, 'You must pay to view exam results');
        dataCoopTreasury.call{value: _price};
        emit ExamRequest(patientTestResults[_patient][_examId]);
    }
}
