// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "./evidenceTypeDeclaration.sol"; //declaration of evidenceType struct
import "./certModelDeclaration.sol"; //declaration of certModel struct

contract Certificate{

    struct cert_type{  
        address certmodel_addr;
        mapping(string => bytes32) hashed_evidence; //"test name" maps to hashed_evidence 
    }
    
    cert_type public cert;

   constructor(CertificationModel m){
        cert.certmodel_addr = m.getCertModelAddress();
        for(uint256 i = 0;i<m.SIZE();i++){
            string memory testName = m.getTestName(i);
            cert.hashed_evidence[testName] = m.hashed_evidence(testName);
        }   
    }

    function getCertModelAddress() public view returns(address){
        return cert.certmodel_addr;
    }

    function getHashedEvidence(string memory index) public view returns(bytes32){
        return cert.hashed_evidence[index];
    }

}

contract CertificationModel{

    certModel public model; 
    uint public constant SIZE = 4; //size of the evidence collection model
    mapping(string => bool) public evidenceResult; //test name maps to evidence result (true/false)
    mapping(string => bytes32) public hashed_evidence; //test name maps to hashed_evidence 
    mapping(bytes32 => string) public evidenceRetrieval; //hashed_evidence maps to storage addres
    string public storage_address = "An IP address"; //storage address

    constructor(string memory _non_functional_property, string memory _target_of_certification, address _apiConsumerAddr, address _preCoordinatorAddr, bytes32 _jobIdHeartBleed, bytes32 _jobIdObservatory, bytes32 _jobIdSslyze, bytes32 _jobIdWebvulnscan){
        model.non_functional_property = _non_functional_property; //init non functional property
        model.target_of_certification = _target_of_certification; //init target of certification
        model.evidence_collection_model[0]=heartbleed; // init evidence collection model
        model.evidence_collection_model[1]=observatory; // init evidence collection model
        model.evidence_collection_model[2]=sslyze; // init evidence collection model
        model.evidence_collection_model[3]=webvulnscan; // init evidence collection model
        model.evidence_collection_model_names[0]="heartbleed test"; // init evidence collection model
        model.evidence_collection_model_names[1]="observatory test"; // init evidence collection model
        model.evidence_collection_model_names[2]="sslyze test"; // init evidence collection model
        model.evidence_collection_model_names[3]="web vuln scan test";
        model.certModelAddr = address(this);
        model.apiConsumerAddr = _apiConsumerAddr;
        model.preCoordinatorAddr = _preCoordinatorAddr;
        model.jobId["heartbleed test"] = _jobIdHeartBleed;
        model.jobId["observatory test"] = _jobIdObservatory; 
        model.jobId["sslyze test"] = _jobIdSslyze;
        model.jobId["web vuln scan test"] = _jobIdWebvulnscan;
    }

    //this function executes the evidence collection model
    function run() public{
        model.evidence_collection_model[0]();
        model.evidence_collection_model[1]();
        model.evidence_collection_model[2]();
        model.evidence_collection_model[3]();
    }

    function collectEvidence() public{
        collectEvidenceHeartbleed();
        collectEvidenceObservatory();
        collectEvidenceSslyze();
        collectEvidenceWebvulnscan();
    }

    function heartbleed() private {
        APIConsumer api = APIConsumer(model.apiConsumerAddr); //init of the Oracle
        //0xeb6103219b07ee393be30dce604b89b594bb6a95e1781517cf929d41c24507aa
        api.requestHeartbleed(model.preCoordinatorAddr, model.jobId["heartbleed test"]); //it executes the test
    }

    function observatory() private {
        APIConsumer api = APIConsumer(model.apiConsumerAddr); //init of the Oracle
        //0xeb6103219b07ee393be30dce604b89b594bb6a95e1781517cf929d41c24507aa
        api.requestObservatory(model.preCoordinatorAddr, model.jobId["observatory test"]); //it executes the test
    }

    function sslyze() private {
        APIConsumer api = APIConsumer(model.apiConsumerAddr); //init of the Oracle
        //0xbab987921eb6059a7941bd1d99ddc73be18ec40a45967537d2476ef1e902c174
        api.requestSslyze(model.preCoordinatorAddr, model.jobId["sslyze test"]); //it executes the test
    }

    function webvulnscan() private {
        APIConsumer api = APIConsumer(model.apiConsumerAddr); //init of the Oracle
        //0x25554f13bb29bd3654f7684ebbde1cf8ccfb54aff7f56d3986eba973e3c7f44e
        api.requestWebvulnscan(model.preCoordinatorAddr, model.jobId["web vuln scan test"]); //it executes the test
    }


    //this function collects the evidence of the test
    function collectEvidenceHeartbleed() private {
        APIConsumer api = APIConsumer(model.apiConsumerAddr);
        uint256 expectedOutput = 1;
        evidenceType memory evidence;
        bytes32 support_evRetr;

        if(api.resultHeartbleed() == expectedOutput){
            evidence.testName = "heartbleed test";
            evidence.output = api.resultHeartbleed();
            evidence.result = true; //result is true because it is what i expect
            evidenceResult["heartbleed test"] = true;
        }
        else{
            evidence.testName = "heartbleed test";
            evidence.output = api.resultHeartbleed();
            evidence.result = false;
            evidenceResult["heartbleed test"] = false;
        }

        hashed_evidence["heartbleed test"] = keccak256(abi.encode(evidence.testName, evidence.output, evidence.result));
        
        support_evRetr = hashed_evidence["heartbleed test"];
        evidenceRetrieval[support_evRetr] = storage_address; //not tested
    }

    //this function collects the evidence of the test
    function collectEvidenceObservatory() private {
        APIConsumer api = APIConsumer(model.apiConsumerAddr);
        uint256 expectedOutput = 1;
        evidenceType memory evidence;
        bytes32 support_evRetr;

        if(api.resultObservatory() == expectedOutput){
            evidence.testName = "observatory test";
            evidence.output = api.resultObservatory();
            evidence.result = true; //result is true because it is what i expect
            evidenceResult["observatory test"] = true;
        }
        else{
            evidence.testName = "observatory test";
            evidence.output = api.resultObservatory();
            evidence.result = false;
            evidenceResult["observatory test"] = false;
        }

        hashed_evidence["observatory test"] = keccak256(abi.encode(evidence.testName, evidence.output, evidence.result));
        
        support_evRetr = hashed_evidence["observatory test"];
        evidenceRetrieval[support_evRetr] = storage_address; //not tested
    }

    //this function collects the evidence of the test
    function collectEvidenceSslyze() private {
        APIConsumer api = APIConsumer(model.apiConsumerAddr);
        uint256 expectedOutput = 1;
        evidenceType memory evidence;
        bytes32 support_evRetr;

        if(api.resultSslyze() == expectedOutput){
            evidence.testName = "sslyze test";
            evidence.output = api.resultSslyze();
            evidence.result = true; //result is true because it is what i expect
            evidenceResult["sslyze test"] = true;
        }
        else{
            evidence.testName = "sslyze test";
            evidence.output = api.resultSslyze();
            evidence.result = false;
            evidenceResult["sslyze test"] = false;
        }

        hashed_evidence["sslyze test"] = keccak256(abi.encode(evidence.testName, evidence.output, evidence.result));
        
        support_evRetr = hashed_evidence["sslyze test"];
        evidenceRetrieval[support_evRetr] = storage_address; //not tested
    }

    //this function collects the evidence of the test
    function collectEvidenceWebvulnscan() private {
        APIConsumer api = APIConsumer(model.apiConsumerAddr);
        uint256 expectedOutput = 1;
        evidenceType memory evidence;
        bytes32 support_evRetr;

        if(api.resultWebvulnscan() == expectedOutput){
            evidence.testName = "web vuln scan test";
            evidence.output = api.resultWebvulnscan();
            evidence.result = true; //result is true because it is what i expect
            evidenceResult["web vuln scan test"] = true;
        }
        else{
            evidence.testName = "web vuln scan test";
            evidence.output = api.resultWebvulnscan();
            evidence.result = false;
            evidenceResult["web vuln scan test"] = false;
        }

        hashed_evidence["web vuln scan test"] = keccak256(abi.encode(evidence.testName, evidence.output, evidence.result));
        
        support_evRetr = hashed_evidence["web vuln scan test"];
        evidenceRetrieval[support_evRetr] = storage_address; //not tested
    }


    function getCertModelAddress() public view returns(address){
        return model.certModelAddr; 
    }

    function getTestName(uint256 index) public view returns(string memory){
        return model.evidence_collection_model_names[index]; 
    }

    /*function getEvidenceResult(string memory index) public view returns(bool){
        return evidenceResult[index];
    }

    function getHashedEvidence(string memory index) public view returns(bytes32){
        return hashed_evidence[index];
    }*/
   
}


//this contract is the orchestrator of the certification process
contract CertificationExecutionAndAward {
   
    CertificationModel m; //certification model 
    address public cloud_service_provider=0xbB2182Fef5bD32B4f04cd341f866B704De18B237;
    address public certificate_address;
    
    //event Address(address);
    event Count(uint256);

    constructor(address _certModelAddr){
        m = CertificationModel(_certModelAddr); //it gets initiated with a certification model since it needs to execute it
    }

    //view computation

    //cert model execution
    function runCertModel() public onlyCSP{
        m.run(); 
    }
    //evidence collection - it is executed in another transaction to let the oracle get the data on chain (because it requires time to bring data on chain)
    function evidenceCollection() public onlyCSP{
        m.collectEvidence();
    }

    function evaluatationFunction() private returns(bool){
        uint256 count = 0;
        
        for(uint256 i = 0; i<m.SIZE(); i++){
            if(m.evidenceResult(m.getTestName(i)) == true){ //if all the evidence result are true, the count is increased (here we have only 1 evidence result, hence the if)
                count++;
            }
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
    function evaluateAndCreate() public onlyCSP{
        bool result;

        result = evaluatationFunction(); //by separating the evaluation function in another function, we add flexibility and respect the traditional cert scheme
        
        if(result == true){ 
            Certificate d = new Certificate(m);
            certificate_address = address(d);
        }
        else{
            certificate_address = address(0);
        }
    }

    // Modifier to check that the caller is the owner of
    // the contract.
    modifier onlyCSP() {
        require(msg.sender == cloud_service_provider, "Only the CSP can execute this function");
        // Underscore is a special character only used inside
        // a function modifier and it tells Solidity to
        // execute the rest of the code.
        _;
    }

}

//Oracle - ChainLink
contract APIConsumer is ChainlinkClient, ConfirmedOwner {

    using Chainlink for Chainlink.Request;
    uint256 public resultHeartbleed;
    uint256 public resultObservatory;
    uint256 public resultSslyze;
    uint256 public resultWebvulnscan;
    uint256 constant private FEE = 5 * (0.1 * 10**18); // 5 (the number of oracles (in the well-known list) in the network) * 0.1 LINK

    constructor() ConfirmedOwner(msg.sender) {
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB); 
    }

    //Both functions need to be public to allow message/internal calls
    function requestHeartbleed(address _oracleAddr, bytes32 jobId) public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfillHeartbleed.selector);
        req.add("get", "https://marcopedrinazzi.github.io/tesi5-frontend/evidence/heartbleed.json");
        req.add("path","status");
        req.addInt("times", 1);
        return sendChainlinkRequestTo(_oracleAddr, req, FEE);
    }

    function requestObservatory(address _oracleAddr, bytes32 jobId) public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfillObservatory.selector);
        req.add("get", "https://marcopedrinazzi.github.io/tesi5-frontend/evidence/observatory.json");
        req.add("path","status");
        req.addInt("times", 1);
        return sendChainlinkRequestTo(_oracleAddr, req, FEE);
    }

    function requestSslyze(address _oracleAddr, bytes32 jobId) public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfillSslyze.selector);
        req.add("get", "https://marcopedrinazzi.github.io/tesi5-frontend/evidence/sslyze.json");
        req.add("path","status");
        req.addInt("times", 1);
        return sendChainlinkRequestTo(_oracleAddr, req, FEE);
    }

    function requestWebvulnscan(address _oracleAddr, bytes32 jobId) public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfillWebvulnscan.selector);
        req.add("get", "https://marcopedrinazzi.github.io/tesi5-frontend/evidence/web-vuln-scan.json");
        req.add("path","status");
        req.addInt("times", 1);
        return sendChainlinkRequestTo(_oracleAddr, req, FEE);
    }

    //Receive the response
    function fulfillHeartbleed(bytes32 _requestId, uint256 _result) public recordChainlinkFulfillment(_requestId){
        resultHeartbleed = _result;
    }

    //Receive the response
    function fulfillObservatory(bytes32 _requestId, uint256 _result) public recordChainlinkFulfillment(_requestId){
        resultObservatory = _result;
    }

    //Receive the response
    function fulfillSslyze(bytes32 _requestId, uint256 _result) public recordChainlinkFulfillment(_requestId){
        resultSslyze = _result;
    }

    //Receive the response
    function fulfillWebvulnscan(bytes32 _requestId, uint256 _result) public recordChainlinkFulfillment(_requestId){
        resultWebvulnscan = _result;
    }


    //Allow withdraw of Link tokens from the contract
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }
    

}