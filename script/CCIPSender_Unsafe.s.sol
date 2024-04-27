// script/CCIPSender_Unsafe.s.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import {CCIPSender_Unsafe} from "../src/CCIPSender_Unsafe.sol";

contract DeployCCIPSender_Unsafe is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address arbLink = 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E;
        address arbRouter = 0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165;

        CCIPSender_Unsafe sender = new CCIPSender_Unsafe(
            arbLink,
            arbRouter
        );

        console.log(
            "CCIPSender_Unsafe deployed to ",
            address(sender)
        );

        vm.stopBroadcast();
    }
}