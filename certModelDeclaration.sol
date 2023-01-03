// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

struct certModel{
        string non_functional_property;
        string target_of_certification;
        mapping(uint => function()) evidence_collection_model; //statically initialized before deploying. It CANNOT be changed.
        address certModelAddr;
        address apiConsumerAddr;
        address preCoordinatorAddr;
        bytes32 jobId;
    }

/* The evidence collection model is kept as a mapping even though there is only a single test that produces
a single evidence (that is used as a normal variable and not as an array) because otherwise the concept of having a function
assigned to a variable wouldnt be possible because solidity doesnt have the function data type*/