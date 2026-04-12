// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

import {CLPc} from "../src/CLPc.sol";
import {ClaimCLPc} from "../src/ClaimCLPc.sol";
import {MockIdentityRegistry} from "../src/mocks/MockIdentityRegistry.sol";

contract ClaimCLPcTest is Test {
    MockIdentityRegistry private registry;
    CLPc private token;
    ClaimCLPc private claimContract;

    address private admin = address(this);
    address private user = address(0xCAFE);
    address private otherUser = address(0xBEEF);
    address private outsider = address(0xD00D);
    address private forwarder = address(0xF0A2);
    address private newOwner = address(0xA11CE);

    uint256 private constant CLAIM_AMOUNT = 100 * 10 ** 8;

    function setUp() public {
        vm.warp(1735689600);

        registry = new MockIdentityRegistry(admin);
        token = new CLPc(address(registry), admin);
        claimContract = new ClaimCLPc(address(token), address(registry), CLAIM_AMOUNT, admin);

        token.grantRole(token.MINTER_ROLE(), address(claimContract));
        registry.setVerifiedChilean(user, true);
    }

    function _scheduleAndExecuteForwarderUpdate(address newForwarder) internal {
        claimContract.setTrustedForwarder(newForwarder);
        vm.warp(block.timestamp + claimContract.TRUSTED_FORWARDER_UPDATE_DELAY());
        claimContract.executeTrustedForwarderUpdate();
    }

    function testClaimSucceedsOnceForVerifiedUser() public {
        vm.prank(user);
        claimContract.claim();

        assertTrue(claimContract.claimed(user));
        assertEq(token.balanceOf(user), CLAIM_AMOUNT);
    }

    function testClaimRevertsForUnverifiedUser() public {
        vm.prank(otherUser);
        vm.expectRevert(abi.encodeWithSelector(ClaimCLPc.NotVerified.selector, otherUser));
        claimContract.claim();
    }

    function testClaimRevertsWhenPaused() public {
        claimContract.setPaused(true);

        vm.prank(user);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        claimContract.claim();
    }

    function testOwnerTransferRequiresAcceptStep() public {
        claimContract.transferOwnership(newOwner);

        assertEq(claimContract.pendingOwner(), newOwner);
        assertEq(claimContract.owner(), admin);

        vm.prank(newOwner);
        claimContract.acceptOwnership();

        assertEq(claimContract.owner(), newOwner);
        assertEq(claimContract.pendingOwner(), address(0));
    }

    function testNonOwnerCannotPause() public {
        vm.prank(outsider);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, outsider));
        claimContract.setPaused(true);
    }

    function testOwnerCanSetTrustedForwarderAfterDelay() public {
        claimContract.setTrustedForwarder(forwarder);

        vm.expectRevert(
            abi.encodeWithSelector(ClaimCLPc.TrustedForwarderUpdateNotReady.selector, block.timestamp + 2 days)
        );
        claimContract.executeTrustedForwarderUpdate();

        vm.warp(block.timestamp + claimContract.TRUSTED_FORWARDER_UPDATE_DELAY());
        claimContract.executeTrustedForwarderUpdate();

        assertEq(claimContract.trustedForwarder(), forwarder);
        assertTrue(claimContract.isTrustedForwarder(forwarder));
    }

    function testOwnerCanCancelTrustedForwarderUpdate() public {
        claimContract.setTrustedForwarder(forwarder);
        claimContract.cancelTrustedForwarderUpdate();

        assertEq(claimContract.pendingTrustedForwarder(), address(0));
        assertEq(claimContract.pendingTrustedForwarderEta(), 0);
    }

    function testForwardedClaimUsesTrustedForwarder() public {
        _scheduleAndExecuteForwarderUpdate(forwarder);

        bytes memory forwardedCall = abi.encodePacked(abi.encodeWithSelector(claimContract.claim.selector), bytes20(user));

        vm.prank(forwarder);
        (bool ok,) = address(claimContract).call(forwardedCall);

        assertTrue(ok);
        assertEq(token.balanceOf(user), CLAIM_AMOUNT);
        assertTrue(claimContract.claimed(user));
    }
}
