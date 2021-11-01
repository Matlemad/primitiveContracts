// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract WeddingRegistry {
    
    address[] public officers;
    address[] public signers;
    uint executionBlockNumber;
    bytes32 weddingID;
    
    modifier onlyOfficer {
        require(officers[msg.sender],"you are no officer");
    _;
    }
    
    mapping(address => bool) public isSigner; // chi si sposa deve firmare
    mapping(address => address) public whoMarriesWho; // chi sposa chi
    mapping(uint => mapping(address => address)) public executionDate; // data dell'esecuzione delle funzioni signWedding e signDivorce
    mapping(bool => mapping(address => address)) public areMarried; // stato matrimoniale
    mapping(bytes32 => mapping(address => address)) weddingHasID; // tutte le ID degli stati matrimoniali 
    uint public totalMarriages;
    bytes32[] public weddingIDs;
    
    constructor() {
        // push an array of officers in officers[]
    }
    
    function addOfficer(address _newOfficer) public onlyOfficer {
        officers.push(_newOfficer);
    }
    
    function removeOfficer(address _oldOfficer) public onlyOfficer {
        //remove _oldOfficer from officers[]

    }
    
    function createWedding(address[] memory _partners, string _secretWord) public returns(bytes32) {
         for (uint i = 0; i < _partners.length; i++) {
            address signer = _partners[i];

            require(signer != address(0), "invalid owner");
            require(!isSigner[signer], "owner not unique");

            isSigner[signer] = true;
            signers.push(signer);
            // soddisfare mapping whoMarriesWho
         }
         bytes32 weddingID = keccak256(abi.encodePacked(block.timestamp, _secretWord));
         weddingIDs.push(weddingID);
         // soddisfare mapping weddingHasID
        
    }
    
    function signWedding(bytes32 _weddingID) public {
        // chi può firmare sono i _partners sopra, relativi alla _weddingID
        // soddisfare mapping areMarried
        
        totalMarriages++;
        
    }
    
    function signDivorce() public {
        
    }
    
    
}