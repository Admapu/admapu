// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console2} from "forge-std/Script.sol";
import {TransportBenefit} from "../src/TransportBenefit.sol";

contract DeployTransport is Script {
    function run() external returns (address transportBenefit) {
        uint256 pk = vm.envUint("DEPLOYER_PK");
        address admin = vm.addr(pk);
        address token = vm.envAddress("TOKEN");
        address identityRegistry = vm.envAddress("IDENTITY_REGISTRY_ADAPTER");
        uint256 benefitAmount = vm.envUint("TRANSPORT_BENEFIT_AMOUNT");

        vm.startBroadcast(pk);

        TransportBenefit t = new TransportBenefit(token, identityRegistry, benefitAmount, admin);

        vm.stopBroadcast();

        console2.log("Admin:", admin);
        console2.log("Token:", token);
        console2.log("IdentityRegistryAdapter:", identityRegistry);
        console2.log("TransportBenefitAmount:", benefitAmount);
        console2.log("TransportBenefit:", address(t));

        return address(t);
    }
}
