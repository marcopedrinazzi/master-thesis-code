// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "./evidenceTypeDeclaration.sol";
import "./certModelDeclaration.sol";

contract Certificate{

    struct cert_type{  
        address certmodel_addr;
        evidenceType[] evidence;
        //metrics - HOW CAN I ENCODE THEM? SHOULD WE OMIT THEM RIGHT NOW?
    }
    
    cert_type public cert;

    constructor(CertificationModel m){
        cert.certmodel_addr= m.getCertModelAddress();
        for (uint i = 0; i < m.SIZE(); i++) {
            cert.evidence[i].testName = m.getEvidenceTestName(i);
            cert.evidence[i].output = m.getEvidenceOutput(i);
            cert.evidence[i].result = m.getEvidenceResult(i);
        }
    }

}

contract CertificationModel{

    certModel public model;
    uint public constant SIZE = 1; //size of the evidence collection model
    evidenceType[SIZE] public evidence; 
    event testResult(bool res);

    constructor(string memory _non_functional_property, string memory _target_of_certification, address _oracleAddr){
        model.non_functional_property = _non_functional_property;
        model.target_of_certification = _target_of_certification;
        model.evidence_collection_model[0]=test1;
        //evaluation function
        model.certModelAddr = address(this);
        model.oracleAddr = _oracleAddr;
    }

    function run() public {
        model.evidence_collection_model[0]();
    }

    function test1() private { //messo da public a private
        APIConsumer api = APIConsumer(model.oracleAddr);
        api.requestCompletedData();
    }

    function collectEvidenceTest1() public {
        APIConsumer api = APIConsumer(model.oracleAddr);
        emit testResult(api.result());
        if(api.result() == true){
            evidence[0].testName = "test1";
            evidence[0].output = api.result();
            evidence[0].result = true;
        }
        else{
            evidence[0].testName = "test1";
            evidence[0].output = api.result();
            evidence[0].result = false;
        }
    }

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



contract CertificationExecutionAndAward {
   
    CertificationModel m;

    constructor(address _addr){
        m = CertificationModel(_addr);
    }

    //view computation

    //cert model execution
    function runCertModel() public{
        m.run(); //con mtest1 va
    }

    function evidenceCollection() public{
        m.collectEvidenceTest1();
    }

    //result aggregation

    //certificate award https://solidity-by-example.org/new-contract/
    function evaluateAndCreate(bytes32 salt) public returns(address){
        uint count = 0;
        for (uint i = 0; i < m.SIZE(); i++) {
            if(m.getEvidenceResult(i) == true){
                count++;
            }
        }
        if(count == m.SIZE()){
            Certificate d = new Certificate{salt: salt}(m);
            return address(d);
        }
        else{
            return address(0);
        }
    }
    
}

contract APIConsumer is ChainlinkClient, ConfirmedOwner {

    using Chainlink for Chainlink.Request;
    bool public result;
    bytes32 private jobId;
    uint256 private fee;
    event RequestCompleted(bytes32 indexed requestId, bool result);

    constructor() ConfirmedOwner(msg.sender) {
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        setChainlinkOracle(0xCC79157eb46F5624204f47AB42b3906cAA40eaB7);
        jobId = "c1c5e92880894eb6b27d3cae19670aa3";
        fee =  0.1 * 10**18; // (Varies by network and job)
    }


    function requestCompletedData() public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        req.add("get", "http://jsonplaceholder.typicode.com/todos/4");
        req.add("path","completed");
        return sendChainlinkRequest(req, fee);
    }


    function fulfill(bytes32 _requestId, bool _result) public recordChainlinkFulfillment(_requestId) {
        emit RequestCompleted(_requestId, _result);
        result = _result;
    }


    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }

}