// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

import {CLPc} from "../src/CLPc.sol";
import {MockIdentityRegistry} from "../src/mocks/MockIdentityRegistry.sol";

contract CLPcTest is Test {
    CLPc private token;
    MockIdentityRegistry private registry;

    address private admin = address(this);
    address private minter = address(0xBEEF);
    address private recipient = address(0xCAFE);
    address private outsider = address(0xD00D);
    address private sender = address(0xABCD);
    address private unverified = address(0xF00D);
    address private recipient2 = address(0xCAFE2);
    address private forwarder = address(0xF0A2);

    function setUp() public {
        // Jan 1, 2025 00:00:00 UTC
        vm.warp(1735689600);

        registry = new MockIdentityRegistry(admin);
        token = new CLPc(address(registry), admin);

        // admin has ISSUER_ROLE by default
        registry.setVerifiedChilean(recipient, true);
        registry.setVerifiedChilean(recipient2, true);
    }

    function _scheduleAndExecuteForwarderUpdate(address newForwarder) internal {
        token.setTrustedForwarder(newForwarder);
        vm.warp(block.timestamp + token.TRUSTED_FORWARDER_UPDATE_DELAY());
        token.executeTrustedForwarderUpdate();
    }

    function testAdminHasDefaultAndMinterRoles() public view {
        require(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin), "missing admin role");
        require(token.hasRole(token.MINTER_ROLE(), admin), "missing minter role");
    }

    function testAdminCanGrantMinterRole() public {
        token.grantRole(token.MINTER_ROLE(), minter);
        assertTrue(token.hasRole(token.MINTER_ROLE(), minter));
    }

    function testNonMinterCannotMint() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, outsider, token.MINTER_ROLE()
            )
        );
        vm.prank(outsider);
        token.mint(recipient, 1);
    }

    function testMinterCanMint() public {
        token.grantRole(token.MINTER_ROLE(), minter);

        uint256 amount = 1_000 * 10 ** token.decimals();
        vm.prank(minter);
        token.mint(recipient, amount);

        assertEq(token.balanceOf(recipient), amount);
        assertEq(token.totalSupply(), amount);
    }

    function testMintingPausedBlocksMint() public {
        token.grantRole(token.MINTER_ROLE(), minter);
        token.setMintingPaused(true);

        vm.prank(minter);
        vm.expectRevert(CLPc.MintingIsPaused.selector);
        token.mint(recipient, 1);
    }

    function testAnnualSupplyExceededReverts() public {
        token.grantRole(token.MINTER_ROLE(), minter);

        uint256 max = token.MAX_ANNUAL_SUPPLY();
        vm.prank(minter);
        token.mint(recipient, max);

        vm.prank(minter);
        vm.expectRevert(abi.encodeWithSelector(CLPc.AnnualSupplyExceeded.selector, 1, 0));
        token.mint(recipient, 1);
    }

    function testAnnualSupplyResetsOnNewYear() public {
        token.grantRole(token.MINTER_ROLE(), minter);

        uint256 max = token.MAX_ANNUAL_SUPPLY();
        vm.prank(minter);
        token.mint(recipient, max);

        // Advance ~1 year
        vm.warp(block.timestamp + 31536000);

        vm.prank(minter);
        token.mint(recipient, 1);

        assertEq(token.mintedThisYear(), 1);
        assertEq(token.totalSupply(), max + 1);
    }

    function testTransferSucceedsWhenBothVerified() public {
        registry.setVerifiedChilean(sender, true);

        uint256 amount = 100 * 10 ** token.decimals();
        token.mint(sender, amount);

        vm.prank(sender);
        assertTrue(token.transfer(recipient, amount / 2));

        assertEq(token.balanceOf(sender), amount / 2);
        assertEq(token.balanceOf(recipient), amount / 2);
    }

    function testTransferRevertsForUnverifiedRecipient() public {
        registry.setVerifiedChilean(sender, true);

        uint256 amount = 100 * 10 ** token.decimals();
        token.mint(sender, amount);

        vm.prank(sender);
        (bool ok, bytes memory revertData) =
            address(token).call(abi.encodeWithSelector(token.transfer.selector, unverified, 1));

        assertFalse(ok);
        assertEq(revertData, abi.encodeWithSelector(CLPc.UnverifiedRecipient.selector, unverified));
    }

    function testTransferRevertsForUnverifiedSender() public {
        registry.setVerifiedChilean(sender, true);

        uint256 amount = 100 * 10 ** token.decimals();
        token.mint(sender, amount);

        // Revoke verification
        registry.setVerifiedChilean(sender, false);

        vm.prank(sender);
        (bool ok, bytes memory revertData) =
            address(token).call(abi.encodeWithSelector(token.transfer.selector, recipient, 1));

        assertFalse(ok);
        assertEq(revertData, abi.encodeWithSelector(CLPc.UnverifiedSender.selector, sender));
    }

    function testForwardedTransferSucceedsWhenBothVerified() public {
        registry.setVerifiedChilean(sender, true);
        _scheduleAndExecuteForwarderUpdate(forwarder);

        uint256 amount = 100 * 10 ** token.decimals();
        token.mint(sender, amount);

        bytes memory transferCall = abi.encodeWithSelector(token.transfer.selector, recipient, amount / 2);
        bytes memory forwardedCall = abi.encodePacked(transferCall, bytes20(sender));

        vm.prank(forwarder);
        (bool ok, bytes memory returnData) = address(token).call(forwardedCall);

        assertTrue(ok);
        assertTrue(abi.decode(returnData, (bool)));
        assertEq(token.balanceOf(sender), amount / 2);
        assertEq(token.balanceOf(recipient), amount / 2);
    }

    function testNonTrustedForwarderCannotSpoofSender() public {
        registry.setVerifiedChilean(sender, true);
        _scheduleAndExecuteForwarderUpdate(forwarder);

        uint256 amount = 100 * 10 ** token.decimals();
        token.mint(sender, amount);

        bytes memory transferCall = abi.encodeWithSelector(token.transfer.selector, recipient, 1);
        bytes memory spoofedCall = abi.encodePacked(transferCall, bytes20(sender));

        vm.prank(outsider);
        (bool ok, bytes memory revertData) = address(token).call(spoofedCall);

        assertFalse(ok);
        assertEq(revertData, abi.encodeWithSelector(CLPc.UnverifiedSender.selector, outsider));
    }

    function testAdminCanSetTrustedForwarderAfterDelay() public {
        token.setTrustedForwarder(forwarder);

        vm.expectRevert(
            abi.encodeWithSelector(CLPc.TrustedForwarderUpdateNotReady.selector, block.timestamp + 2 days)
        );
        token.executeTrustedForwarderUpdate();

        vm.warp(block.timestamp + token.TRUSTED_FORWARDER_UPDATE_DELAY());
        token.executeTrustedForwarderUpdate();

        assertEq(token.trustedForwarder(), forwarder);
        assertTrue(token.isTrustedForwarder(forwarder));
    }

    function testAdminCanCancelTrustedForwarderUpdate() public {
        token.setTrustedForwarder(forwarder);
        token.cancelTrustedForwarderUpdate();

        assertEq(token.pendingTrustedForwarder(), address(0));
        assertEq(token.pendingTrustedForwarderEta(), 0);
    }

    function testMintBatchMismatchedArraysReverts() public {
        address[] memory recipients = new address[](1);
        recipients[0] = recipient;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        vm.expectRevert(CLPc.ArraysLengthMismatch.selector);
        token.mintBatch(recipients, amounts);
    }

    function testMintBatchEmptyArraysReverts() public {
        address[] memory recipients = new address[](0);
        uint256[] memory amounts = new uint256[](0);

        vm.expectRevert(CLPc.EmptyBatch.selector);
        token.mintBatch(recipients, amounts);
    }

    function testMintBatchUnverifiedRecipientReverts() public {
        address[] memory recipients = new address[](2);
        recipients[0] = recipient;
        recipients[1] = unverified;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        vm.expectRevert(abi.encodeWithSelector(CLPc.UnverifiedRecipient.selector, unverified));
        token.mintBatch(recipients, amounts);
    }

    function testMintBatchAnnualSupplyExceededReverts() public {
        address[] memory recipients = new address[](2);
        recipients[0] = recipient;
        recipients[1] = recipient2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = token.MAX_ANNUAL_SUPPLY();
        amounts[1] = 1;

        uint256 totalAmount = amounts[0] + amounts[1];

        vm.expectRevert(
            abi.encodeWithSelector(CLPc.AnnualSupplyExceeded.selector, totalAmount, token.MAX_ANNUAL_SUPPLY())
        );
        token.mintBatch(recipients, amounts);
    }

    function testNonAdminCannotSetVerifier() public {
        MockIdentityRegistry newRegistry = new MockIdentityRegistry(admin);

        vm.startPrank(outsider);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, outsider, token.DEFAULT_ADMIN_ROLE()
            )
        );
        token.setIdentityRegistry(address(newRegistry));
        vm.stopPrank();
    }

    function testNonPauserCannotPauseMinting() public {
        vm.startPrank(outsider);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, outsider, token.PAUSER_ROLE()
            )
        );
        token.setMintingPaused(true);
        vm.stopPrank();
    }

    function testNonAdminCannotSetTrustedForwarder() public {
        vm.startPrank(outsider);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, outsider, token.DEFAULT_ADMIN_ROLE()
            )
        );
        token.setTrustedForwarder(forwarder);
        vm.stopPrank();
    }

    function testNonAdminCannotExecuteTrustedForwarderUpdate() public {
        token.setTrustedForwarder(forwarder);
        vm.warp(block.timestamp + token.TRUSTED_FORWARDER_UPDATE_DELAY());

        vm.startPrank(outsider);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, outsider, token.DEFAULT_ADMIN_ROLE()
            )
        );
        token.executeTrustedForwarderUpdate();
        vm.stopPrank();
    }
}
