// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

struct certModel{
        string non_functional_property;
        string target_of_certification;
        mapping(uint => function()) evidence_collection_model; //statically initialized before deploying. It CANNOT be changed.
        bool evaluation_function; //statically initialized before deploying. It CANNOT be changed.
        address certModelAddr;
        address oracleAddr;
    }