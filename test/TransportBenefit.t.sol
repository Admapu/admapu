// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";

import {CLPc} from "../src/CLPc.sol";
import {TransportBenefit} from "../src/TransportBenefit.sol";
import {MockIdentityRegistry} from "../src/mocks/MockIdentityRegistry.sol";

contract TransportBenefitTest is Test {
    MockIdentityRegistry private registry;
    CLPc private token;
    TransportBenefit private transport;

    address private admin = address(this);
    address private eligibleUser = address(0xBEEF);
    address private unverifiedUser = address(0xCAFE);
    address private notEligibleUser = address(0xD00D);
    address private forwarder = address(0xF0A2);
    address private outsider = address(0xAAAA);

    uint256 private constant BENEFIT_AMOUNT = 250 * 10 ** 8;

    function setUp() public {
        vm.warp(1735689600);

        registry = new MockIdentityRegistry(admin);
        token = new CLPc(address(registry), admin);
        transport = new TransportBenefit(address(token), address(registry), BENEFIT_AMOUNT, admin);

        token.grantRole(token.MINTER_ROLE(), address(transport));

        registry.setVerifiedChilean(eligibleUser, true);
        registry.setSchoolTransport(eligibleUser, true);

        registry.setSchoolTransport(unverifiedUser, true);
        registry.setVerifiedChilean(notEligibleUser, true);
    }

    function testClaimSucceedsForEligibleUser() public {
        uint256 period = transport.currentPeriod();

        vm.prank(eligibleUser);
        transport.claim();

        assertTrue(transport.claimedByPeriod(eligibleUser, period));
        assertEq(token.balanceOf(eligibleUser), BENEFIT_AMOUNT);
    }

    function testClaimRevertsWhenAlreadyClaimedInCurrentPeriod() public {
        uint256 period = transport.currentPeriod();

        vm.prank(eligibleUser);
        transport.claim();

        vm.prank(eligibleUser);
        vm.expectRevert(abi.encodeWithSelector(TransportBenefit.AlreadyClaimed.selector, eligibleUser, period));
        transport.claim();
    }

    function testClaimSucceedsAgainInNextPeriod() public {
        vm.prank(eligibleUser);
        transport.claim();

        vm.warp(block.timestamp + transport.PERIOD_DURATION());

        vm.prank(eligibleUser);
        transport.claim();

        assertEq(token.balanceOf(eligibleUser), BENEFIT_AMOUNT * 2);
    }

    function testClaimRevertsWhenUserIsNotVerified() public {
        vm.prank(unverifiedUser);
        vm.expectRevert(abi.encodeWithSelector(TransportBenefit.NotVerified.selector, unverifiedUser));
        transport.claim();
    }

    function testClaimRevertsWhenUserIsNotEligibleForTransport() public {
        vm.prank(notEligibleUser);
        vm.expectRevert(abi.encodeWithSelector(TransportBenefit.NotEligible.selector, notEligibleUser));
        transport.claim();
    }

    function testPausedBlocksClaim() public {
        transport.setPaused(true);

        vm.prank(eligibleUser);
        vm.expectRevert(TransportBenefit.PausedError.selector);
        transport.claim();
    }

    function testForwardedClaimSucceeds() public {
        transport.setTrustedForwarder(forwarder);

        bytes memory claimCall = abi.encodeWithSelector(transport.claim.selector);
        bytes memory forwardedCall = abi.encodePacked(claimCall, bytes20(eligibleUser));

        vm.prank(forwarder);
        (bool ok,) = address(transport).call(forwardedCall);
        assertTrue(ok);

        assertEq(token.balanceOf(eligibleUser), BENEFIT_AMOUNT);
    }

    function testNonTrustedForwarderCannotSpoofSender() public {
        transport.setTrustedForwarder(forwarder);

        bytes memory claimCall = abi.encodeWithSelector(transport.claim.selector);
        bytes memory spoofedCall = abi.encodePacked(claimCall, bytes20(eligibleUser));

        vm.prank(outsider);
        (bool ok, bytes memory revertData) = address(transport).call(spoofedCall);
        assertFalse(ok);
        assertEq(revertData, abi.encodeWithSelector(TransportBenefit.NotVerified.selector, outsider));
    }
}
