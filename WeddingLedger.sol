// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/** This primitive WeddingLedger contract works fine for traditional marriage. Needs two basic improvements:
 * 1) divorced addresses cannot re-marry, they should be able to (see registeredAddresses mapping);
 * 2) people cannot marry more than one person. Couples cannot marry other couples etc. Might be done via mapping (address => address[]));
 * */

import "@openzeppelin/contracts/access/Ownable.sol";

contract WeddingLedger is Ownable {
    
    event CoupleOnFire(bytes32);
    event CoupleMarried(bytes32);
    event WillingnessExpressed(bytes32, address);
    event CoupleCrisis(bytes32, address);
    event CoupleBroken(bytes32);
    event CoupleDivorced(bytes32);

    // Struct for who gets married
    struct Couple {
        address wed1;
        address wed2;
        bytes32 weddingID;
        bool wed1Will;
        bool wed2Will;
        bool marriageSettlement;
    }
    
     /**
     * array of officers,
     * array to keep track of all couple's addresses,
     * array for all the weddingIDHash
     * array for all the couples
     * */
    address[] private officers;
    bytes32[] private allWeddingHashes;

     /**
     * mapping for Officers to be allowed to sign
     * mapping for signers to be allowed to signers
     * mapping to return the Couples' status boolean (true: married, false: divorced)
     * mapping to index the Couples by ID
     * */
    mapping(address => bool) public isOfficer;
    mapping(address => bool) private registeredAddresses;
    mapping(bytes32 => Couple) public weddingByHash;
    mapping(address => bytes32) public hashByAddress;

    modifier onlyOfficer() {
        require(isOfficer[msg.sender],"you are no officer");
        _;
    }
    
    modifier isEligible(address _addr) {
        require(registeredAddresses[_addr] == false,"address appears to be already newly-wed!");
        _;
    }
    
     /** constructor sets a first batch of officers
     * maps them to true
     * and pushed their addr into the officers[]
     * */
    constructor(address[] memory _newOfficers) {
        require(_newOfficers.length > 0, "addresses[] required");
        for (uint i = 0; i < _newOfficers.length; i++) {
            address newOfficer = _newOfficers[i];
            require(newOfficer != address(0), "invalid address");
            require(!isOfficer[newOfficer], "Officer not unique");
            isOfficer[newOfficer] = true; // assign in mapping
            officers.push(newOfficer); // push in list 
        }
    }
    
    // onlyOwner who can empower another officer
    function addOfficer(address _newOfficer) external onlyOwner {
        require(!isOfficer[_newOfficer], "Officer not found");
        isOfficer[_newOfficer] = true;
        officers.push(_newOfficer);
    }
   
    // onlyOwner who can remove another officer
    function removeOfficer(address _oldOfficer) external onlyOwner {
        require(isOfficer[_oldOfficer], "Cannot delete unassigned account");
        isOfficer[_oldOfficer] = false;
    }
    
    /** onlyOfficers can set the Couple
     * they need the weds (groom, bride) addresses and a secret date from them to generate an ID
     * then the weds are mapped true, and pushed as signers in the signers[]
     * ultimately, the weddingID is mapped to the new Couple Struct and added to allWeddingHashes[]
     * */
    function setCouple(address _wed1, address _wed2, uint _secretDate) public onlyOfficer isEligible(_wed1) isEligible(_wed2) {
        
        bytes32 weddingIDHash = keccak256(abi.encodePacked(_wed1, _wed2, block.timestamp, _secretDate)); // 1. create wedding hash
        Couple memory currentCouple = Couple(_wed1, _wed2, weddingIDHash, false, false, false); // 2. create couple Struct and assign both for pending (false) expressed willingness of marriage
        
        hashByAddress[_wed1] = weddingIDHash; // 3.a map hashId by address1
        hashByAddress[_wed2] = weddingIDHash; // 3.b map hashId by address2
        
        weddingByHash[weddingIDHash] = currentCouple; // 4.a add marriage hash and map it to Struct
        allWeddingHashes.push(weddingIDHash); // 4.b add marriage hash in array

        registeredAddresses[_wed1] = true;
        registeredAddresses[_wed2] = true; // 5. keep track of registered addresses
        // Optional: event emitter 
    }
    
    function signWedding(bytes32 _weddingHash) public {
        Couple storage currentCouple = weddingByHash[_weddingHash]; // 1. Get current couple by hash
        require(msg.sender == currentCouple.wed1 || msg.sender == currentCouple.wed2, 'You are not invited'); // 2. require signer as one or the other part
        if(msg.sender == currentCouple.wed1) {
            currentCouple.wed1Will = true;  // 3. assign expressed willingness of marriage
        } else if (msg.sender == currentCouple.wed2) {
            currentCouple.wed2Will = true; 
        }
        emit WillingnessExpressed(_weddingHash, msg.sender); // event emitter
        
        if (currentCouple.wed1Will == true && currentCouple.wed2Will == true) {
            emit CoupleOnFire(_weddingHash); // event emitter
        }
    }
    
    function declareWedding(bytes32 _weddingHash) public onlyOfficer {
        Couple storage awaitingCouple = weddingByHash[_weddingHash]; // 1. Get current couple by hash
        require(awaitingCouple.wed1Will == true && awaitingCouple.wed2Will == true, 'No consent yet');
        awaitingCouple.marriageSettlement = true; // 2 update and declare marriage
        emit CoupleMarried(_weddingHash); // event emitter
    }
    
    function signDevorce(bytes32 _weddingHash) public {
        Couple storage currentCouple = weddingByHash[_weddingHash]; // 1. Get current couple by hash
        require(msg.sender == currentCouple.wed1 || msg.sender == currentCouple.wed2, 'You are not invited'); // 2. require signer as one or the other part
        require(currentCouple.marriageSettlement == true, 'You are not married!'); 
        if(msg.sender == currentCouple.wed1) {
            currentCouple.wed1Will = false;  // 3. assign expressed willingness of divorce
        } else if (msg.sender == currentCouple.wed2) {
            currentCouple.wed2Will = false; 
        }
        emit CoupleCrisis(_weddingHash, msg.sender); // event emitter
        
        if (currentCouple.wed1Will == false && currentCouple.wed2Will == false) {
            emit CoupleBroken(_weddingHash); // event emitter
        }
    }
    
    function declareDevorce(bytes32 _weddingHash) public onlyOfficer {
        Couple storage awaitingCouple = weddingByHash[_weddingHash]; // 1. Get current couple by hash
        require(awaitingCouple.wed1Will == false && awaitingCouple.wed2Will == false, 'No consent yet');
        awaitingCouple.marriageSettlement = false; // 2 update and declare marriage
        emit CoupleDivorced(_weddingHash); // event emitter
    }
}
