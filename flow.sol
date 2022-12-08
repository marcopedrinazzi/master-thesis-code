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
        for(uint256 i = 0; i<m.SIZE(); i++){
            evidenceType storage ev = cert.evidence.push();
            ev.testName = m.getEvidenceTestName(0);
            ev.output = m.getEvidenceOutput(0);
            ev.result = m.getEvidenceResult(0);
            //cert.evidence[i].testName = m.getEvidenceTestName(0);
            //cert.evidence[i].output = m.getEvidenceOutput(0);
            //cert.evidence[i].result = m.getEvidenceResult(0);
        }
        
        //metrics??
    }

    //get function for the evidences.

}

contract CertificationModel{

    certModel public model; //state variable contianing the 
    uint public constant SIZE = 1; //size of the evidence collection model
    evidenceType[SIZE] public evidence; //state variable, an array to store the evidence of the tests

    constructor(string memory _non_functional_property, string memory _target_of_certification, address _apiConsumerAddr, address _preCoordinatorAddr){
        model.non_functional_property = _non_functional_property; //init non functional property
        model.target_of_certification = _target_of_certification; //init target of certification
        model.evidence_collection_model[0]=test1; // init evidence collection model
        //evaluation function - so far it's not needed
        model.certModelAddr = address(this);
        model.apiConsumerAddr = _apiConsumerAddr;
        model.preCoordinatorAddr = _preCoordinatorAddr;
    }

    //this function executes the evidence collection model
    function run() public {
        model.evidence_collection_model[0]();
    }

    function collectEvidence() public {
        collectEvidenceTest1();
    }

    function test1() private {
        APIConsumer api = APIConsumer(model.apiConsumerAddr); //init of the Oracle
        api.requestCompletedData(model.preCoordinatorAddr); //it executes the test
    }

    //this function collects the evidence of the test
    function collectEvidenceTest1() private {
        APIConsumer api = APIConsumer(model.apiConsumerAddr);
        if(api.result() == 4){
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
    function getEvidenceTestName(uint256 index) public view returns(string memory){
        return evidence[index].testName;
    }

    function getEvidenceOutput(uint256 index) public view returns(uint256){
        return evidence[index].output;
    }

    function getEvidenceResult(uint256 index) public view returns(bool){
        return evidence[index].result;
    }

    function getCertModelAddress() public view returns(address){
        return model.certModelAddr;
    }

    
}


//this contract is the orchestrator of the certification process
contract CertificationExecutionAndAward {
   
    CertificationModel m; //certification model 
    event Address(address);

    constructor(address _certModelAddr){
        m = CertificationModel(_certModelAddr); //it gets initiated with a certification model since it needs to execute it
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
    function evaluateAndCreate() public{
        uint256 count = 0;
        for (uint256 i = 0; i < m.SIZE(); i++) {
            if(m.getEvidenceResult(i) == true){ //if all the result are true, the count is increased
                count++;
            }
        }
        if(count == m.SIZE()){ //if the count is equal to the size of the evidence collection model, the certificate smart contract is created  
            Certificate d = new Certificate(m);
            emit Address(address(d));
        }
        else{
            emit Address(address(0));
        }
    }
    
}

//Oracle - ChainLink
contract APIConsumer is ChainlinkClient, ConfirmedOwner {

    using Chainlink for Chainlink.Request;
    uint256 public result; //result of the API call
    bytes32 private jobId;
    uint256 private fee;
    event RequestCompleted(bytes32 indexed requestId, uint256 result);

    // Initialize the link token and the job_id. The JobId is the service agreement ID generated by the preCoordinator
    constructor() ConfirmedOwner(msg.sender) {
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB); 
        //setChainlinkOracle(0xCC79157eb46F5624204f47AB42b3906cAA40eaB7); //ChainLink Goerli Testnet Oracle:0xCC79157eb46F5624204f47AB42b3906cAA40eaB7
        jobId = 0x6baf04b7905cb31543133908490f48c477c29fd7e8fdf92f48f8a4e742fca9e3; 
        fee =  4 * (0.1 * 10**18); // 4 (the number of oracles in the network) * 0.1 LINK
    }


    /* Create a Chainlink request to retrieve API response, find the target
    data (completed field) (the expected behavior of the test is that completed is true).
    The parameter is the adddress of the PreCoordinator contract.
    */
    function requestCompletedData(address _oracleAddr) public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        req.add("get", "http://jsonplaceholder.typicode.com/todos/4");
        req.add("path","id");
        req.addInt("times", 1);
        return sendChainlinkRequestTo(_oracleAddr, req, fee);
    }

    //Receive the response in the form of bool
    function fulfill(bytes32 _requestId, uint256 _result) public recordChainlinkFulfillment(_requestId) {
        emit RequestCompleted(_requestId, _result);
        result = _result;
    }

    //Allow withdraw of Link tokens from the contract
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }

}