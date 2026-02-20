// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console2} from "forge-std/Script.sol";
import {CLPc} from "../src/CLPc.sol";
import {MockZKPassportVerifier} from "../src/mocks/MockZKPassportVerifier.sol";
import {ZKPassportIdentityRegistryAdapter} from "../src/ZKPassportIdentityRegistryAdapter.sol";

contract Deploy is Script {
    function run() external returns (address verifier, address identityRegistryAdapter, address token) {
        uint256 pk = vm.envUint("DEPLOYER_PK");
        address admin = vm.addr(pk);

        vm.startBroadcast(pk);

        MockZKPassportVerifier v = new MockZKPassportVerifier();
        ZKPassportIdentityRegistryAdapter registryAdapter = new ZKPassportIdentityRegistryAdapter(address(v));

        // Importante: el admin del mock queda como msg.sender (deployer) por constructor.
        // Y CLPc admin/minter/pauser queda en `admin`.
        CLPc t = new CLPc(address(registryAdapter), admin);

        vm.stopBroadcast();

        console2.log("Admin:", admin);
        console2.log("Verifier:", address(v));
        console2.log("IdentityRegistryAdapter:", address(registryAdapter));
        console2.log("Token:", address(t));

        return (address(v), address(registryAdapter), address(t));
    }
}

