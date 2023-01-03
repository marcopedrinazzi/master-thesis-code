// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "./evidenceTypeDeclaration.sol"; //declaration of evidenceType struct
import "./certModelDeclaration.sol"; //declaration of certModel struct

contract Certificate{

    struct cert_type{  
        address certmodel_addr;
        bytes32 hashed_evidence; //changed datatype from array to single var. It is not needed to have an array on the PoC
    }
    
    bytes32 public hashed_cert; //state variable (so memorized in the blockchain) that stores the certification data

    /*Constructor: when i iniate the smart contract, the certificate state variable is initialized with the certification data.
    The constructor takes as a parameter the certification model to "link" it to the certificate and to get the needed information:
    - the certification model address 
    - the evidences
    
    To populate the certificate transactions are executed to the proper functions
    */
   constructor(CertificationModel m){
        cert_type memory cert;
        cert.certmodel_addr = m.getCertModelAddress();
        cert.hashed_evidence = m.hashed_evidence();

        //save cert memory variable offchain

        hashed_cert = keccak256(abi.encode(cert.certmodel_addr, cert.hashed_evidence));
    }


}

contract CertificationModel{

    certModel public model; //state variable contianing the 
    uint public constant SIZE = 1; //size of the evidence collection model
    bool public evidenceResult; //state variable needed for certificate creation
    bytes32 public hashed_evidence; //state variable, the hashed evidence of the test

    constructor(string memory _non_functional_property, string memory _target_of_certification, address _apiConsumerAddr, address _preCoordinatorAddr, bytes32 _jobId){
        model.non_functional_property = _non_functional_property; //init non functional property
        model.target_of_certification = _target_of_certification; //init target of certification
        model.evidence_collection_model[0]=test1; // init evidence collection model
        model.certModelAddr = address(this);
        model.apiConsumerAddr = _apiConsumerAddr;
        model.preCoordinatorAddr = _preCoordinatorAddr;
        model.jobId = _jobId;
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
        api.requestIdData(model.preCoordinatorAddr,model.jobId); //it executes the test
    }

    //this function collects the evidence of the test
    function collectEvidenceTest1() private {
        APIConsumer api = APIConsumer(model.apiConsumerAddr);
        uint256 expectedOutput = 4;
        evidenceType memory evidence;
        if(api.result() == expectedOutput){
            evidence.testName = "test1";
            evidence.output = api.result();
            evidence.result = true; //result is true because it is what i expect
            evidenceResult = true;
        }
        else{
            evidence.testName = "test1";
            evidence.output = api.result();
            evidence.result = false;
            evidenceResult = false;
        }

        //saved real evidence data (now in memory) off chain

        hashed_evidence = keccak256(abi.encode(evidence.testName, evidence.output, evidence.result));

    }


    function getCertModelAddress() public view returns(address){
        return model.certModelAddr;
        
    }

    
}


//this contract is the orchestrator of the certification process
contract CertificationExecutionAndAward {
   
    CertificationModel m; //certification model 
    event Address(address);
    event Count(uint256);

    constructor(address _certModelAddr){
        m = CertificationModel(_certModelAddr); //it gets initiated with a certification model since it needs to execute it
    }

    //view computation

    //cert model execution
    function runCertModel() public{
        m.run(); //con mtest1 va
    }
    //evidence collection - it is executed in another transaction to let the oracle get the data on chain (because it requires time to bring data on chain)
    function evidenceCollection() public{
        m.collectEvidence();
    }

    function evaluatationFunction() private returns(bool){
        uint256 count = 0;
        if(m.evidenceResult() == true){ //if all the evidence result are true, the count is increased (here we have only 1 evidence result, hence the if)
            count++;
        }
        emit Count(count);
        if(count == m.SIZE()){//if the count is equal to the size of the evidence collection model, the evaluation function returns true
            return true;
        }
        else{
            return false;
        }
    }

    // result aggregation and certificate award https://solidity-by-example.org/new-contract/
    function evaluateAndCreate() public{
        bool result;

        result = evaluatationFunction(); //by separating the evaluation function in another function, we add flexibility and respect the traditional cert scheme
        
        if(result == true){ 
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
    uint256 public result; //result of the API call - it is the ID of http://jsonplaceholder.typicode.com/todos/4 (expected to be =4)
    uint256 constant private FEE = 5 * (0.1 * 10**18); // 5 (the number of oracles (in the well-known list) in the network) * 0.1 LINK

    // Initialize the link token and the job_id. The JobId is the service agreement ID generated by the preCoordinator
    constructor() ConfirmedOwner(msg.sender) {
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB); 
        //ChainLink Goerli Testnet Oracle:0xCC79157eb46F5624204f47AB42b3906cAA40eaB7
    }


    /* Create a Chainlink request to retrieve API response, find the target
    data (id field) (the expected behavior of the test is that id is equal to 4).
    The parameter is the adddress of the PreCoordinator contract.

    THE JOBID is used as a parameter to keep the approach more versatile (see Notion)
    */
    function requestIdData(address _oracleAddr, bytes32 jobId) public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        req.add("get", "http://jsonplaceholder.typicode.com/todos/4");
        req.add("path","id");
        req.addInt("times", 1);
        return sendChainlinkRequestTo(_oracleAddr, req, FEE);
    }

    //Receive the response in the form of uint256
    function fulfill(bytes32 _requestId, uint256 _result) public recordChainlinkFulfillment(_requestId) {
        result = _result;
    }


    //Allow withdraw of Link tokens from the contract
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }

}