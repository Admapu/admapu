// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console2} from "forge-std/Script.sol";
import {ClaimCLPc} from "../src/ClaimCLPc.sol";

contract DeployClaim is Script {
    function run() external returns (address claim) {
        uint256 pk = vm.envUint("DEPLOYER_PK");
        address admin = vm.addr(pk);
        address token = vm.envAddress("TOKEN");
        address identityRegistry = vm.envAddress("IDENTITY_REGISTRY_ADAPTER");
        uint256 claimAmount = vm.envUint("CLAIM_AMOUNT");

        vm.startBroadcast(pk);

        ClaimCLPc c = new ClaimCLPc(token, identityRegistry, claimAmount, admin);

        vm.stopBroadcast();

        console2.log("Admin:", admin);
        console2.log("Token:", token);
        console2.log("IdentityRegistryAdapter:", identityRegistry);
        console2.log("ClaimAmount:", claimAmount);
        console2.log("Claim:", address(c));

        return address(c);
    }
}
