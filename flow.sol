// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "./evidenceTypeDeclaration.sol"; //declaration of evidenceType struct
import "./certModelDeclaration.sol"; //declaration of certModel struct

contract Certificate{

    struct cert_type{  
        address certmodel_addr;
        evidenceType[] evidence;
        //metrics - HOW CAN I ENCODE THEM? SHOULD WE OMIT THEM RIGHT NOW (considering the PoC)?
    }
    
    cert_type public cert; //state variable (so memorized in the blockchain) that stores the certification data

    /*Constructor: when i iniate the smart contract, the certificate state variable is initialized with the certification data.
    The constructor takes as a parameter the certification model to "link" it to the certificate and to get the needed information:
    - the certification model address 
    - the evidences
    (- the metrics (?))
    
    To populate the certificate transactions are executed.
    */
    constructor(CertificationModel m){
        cert.certmodel_addr= m.getCertModelAddress();
        for (uint i = 0; i < m.SIZE(); i++) {
            cert.evidence[i].testName = m.getEvidenceTestName(i);
            cert.evidence[i].output = m.getEvidenceOutput(i);
            cert.evidence[i].result = m.getEvidenceResult(i);
        }
        //metrics??
    }

}

contract CertificationModel{

    certModel public model; //state variable contianing the 
    uint public constant SIZE = 1; //size of the evidence collection model
    evidenceType[SIZE] public evidence; //state variable, an array to store the evidence of the tests

    constructor(string memory _non_functional_property, string memory _target_of_certification, address _oracleAddr){
        model.non_functional_property = _non_functional_property; //init non functional property
        model.target_of_certification = _target_of_certification; //init target of certification
        model.evidence_collection_model[0]=test1; // init evidence collection model
        //evaluation function - so far it's not needed
        model.certModelAddr = address(this);
        model.oracleAddr = _oracleAddr;
    }

    //this function executes the evidence collection model
    function run() public {
        model.evidence_collection_model[0]();
    }

    function collectEvidence() public {
        collectEvidenceTest1();
    }

    function test1() private {
        APIConsumer api = APIConsumer(model.oracleAddr); //init of the Oracle
        api.requestCompletedData(0x50183cfd15e17e8452ce9090f2eae2abfc467db4862f78da609642f4f646b9ca, 0x6169e9e0E682E33aA1DD39a75b3c4031b64a7a23); //it executes the test
    }

    //this function collects the evidence of the test
    function collectEvidenceTest1() private {
        APIConsumer api = APIConsumer(model.oracleAddr);
        if(api.result() == true){
            evidence[0].testName = "test1";
            evidence[0].output = api.result();
            evidence[0].result = true; //result is true because it is what i expect
        }
        else{
            evidence[0].testName = "test1";
            evidence[0].output = api.result();
            evidence[0].result = false;
        }
    }

    //get functions needed to create and deploy the certificate smart contract in the following phases
    function getEvidenceTestName(uint index) public view returns(string memory){
        return evidence[index].testName;
    }

    function getEvidenceOutput(uint index) public view returns(bool){
        return evidence[index].output;
    }

    function getEvidenceResult(uint index) public view returns(bool){
        return evidence[index].result;
    }

    function getCertModelAddress() public view returns(address){
        return model.certModelAddr;
    }

    
}


//this contract is the orchestrator of the certification process
contract CertificationExecutionAndAward {
   
    CertificationModel m; //certification model 

    constructor(address _addr){
        m = CertificationModel(_addr); //it gets initiated with a certification model since it needs to execute it
    }

    //view computation

    //cert model execution
    function runCertModel() public{
        m.run(); //con mtest1 va
    }
    //evidence collection - it is executed in another transaction to let the oracle get the data on chain
    function evidenceCollection() public{
        m.collectEvidence();
    }

    

    // result aggregation and certificate award https://solidity-by-example.org/new-contract/
    function evaluateAndCreate(bytes32 salt) public returns(address){
        uint count = 0;
        for (uint i = 0; i < m.SIZE(); i++) {
            if(m.getEvidenceResult(i) == true){ //if all the result are true, the count is increased
                count++;
            }
        }
        if(count == m.SIZE()){ //if the count is equal to the size of the evidence collection model, the certificate smart contract is created  
            Certificate d = new Certificate{salt: salt}(m);
            return address(d); //thanks to the salt it is possible to precompute the deployment address that is returned also as output
        }
        else{
            return address(0); //in case of error the address 0x000000... is returned
        }
    }
    
}

//Oracle - ChainLink
contract APIConsumer is ChainlinkClient, ConfirmedOwner {

    using Chainlink for Chainlink.Request;
    bool public result; //result of the API call
    bytes32 private jobId;
    uint256 private fee;
    event RequestCompleted(bytes32 indexed requestId, bool result);

    // Initialize the link token and target oracle (https://docs.chain.link/any-api/testnet-oracles/)
    constructor() ConfirmedOwner(msg.sender) {
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB); 
        //setChainlinkOracle(0x6169e9e0E682E33aA1DD39a75b3c4031b64a7a23); //originale:0xCC79157eb46F5624204f47AB42b3906cAA40eaB7
        jobId = 0x50183cfd15e17e8452ce9090f2eae2abfc467db4862f78da609642f4f646b9ca; //originale: c1c5e92880894eb6b27d3cae19670aa3
        fee =  3 * (0.1 * 10**18); // (Varies by network and job)
    }


    /* Create a Chainlink request to retrieve API response, find the target
    data (completed field) (the expected behavior of the test is that completed is true).
    */
    function requestCompletedData(bytes32 _jobId, address _addr) public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(_jobId, address(this), this.fulfill.selector);
        req.add("get", "http://jsonplaceholder.typicode.com/todos/4");
        req.add("path","completed");
        return sendChainlinkRequestTo(_addr, req, fee);
    }

    //Receive the response in the form of bool
    function fulfill(bytes32 _requestId, bool _result) public recordChainlinkFulfillment(_requestId) {
        emit RequestCompleted(_requestId, _result);
        result = _result;
    }

    //Allow withdraw of Link tokens from the contract
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }

}