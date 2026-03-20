// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console2} from "forge-std/Script.sol";
import {ERC2771Forwarder} from "@openzeppelin/contracts/metatx/ERC2771Forwarder.sol";

contract DeployForwarder is Script {
    function run() external returns (address forwarder) {
        uint256 pk = vm.envUint("DEPLOYER_PK");
        string memory forwarderName = vm.envString("FORWARDER_NAME");

        vm.startBroadcast(pk);

        ERC2771Forwarder f = new ERC2771Forwarder(forwarderName);

        vm.stopBroadcast();

        console2.log("Admin:", vm.addr(pk));
        console2.log("ForwarderName:", forwarderName);
        console2.log("Forwarder:", address(f));

        return address(f);
    }
}
