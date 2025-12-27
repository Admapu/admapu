// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

import {CLPc} from "../src/CLPc.sol";
import {MockZKPassportVerifier} from "../src/mocks/MockZKPassportVerifier.sol";

contract CLPcTest is Test {
    CLPc private token;
    MockZKPassportVerifier private verifier;

    address private admin = address(this);
    address private minter = address(0xBEEF);
    address private recipient = address(0xCAFE);
    address private outsider = address(0xD00D);
    address private sender = address(0xABCD);
    address private unverified = address(0xF00D);
    address private recipient2 = address(0xCAFE2);

    function setUp() public {
        vm.warp(1735689600);
        verifier = new MockZKPassportVerifier();
        token = new CLPc(address(verifier), admin);

        verifier.verify(recipient);
        verifier.verify(recipient2);
    }

    function testAdminHasDefaultAndMinterRoles() public view {
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(token.hasRole(token.MINTER_ROLE(), admin));
    }

    function testAdminCanGrantMinterRole() public {
        token.grantRole(token.MINTER_ROLE(), minter);
        assertTrue(token.hasRole(token.MINTER_ROLE(), minter));
    }

    function testNonMinterCannotMint() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                outsider,
                token.MINTER_ROLE()
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

        vm.warp(block.timestamp + 31536000);

        vm.prank(minter);
        token.mint(recipient, 1);

        assertEq(token.mintedThisYear(), 1);
        assertEq(token.totalSupply(), max + 1);
    }

    function testTransferSucceedsWhenBothVerified() public {
        verifier.verify(sender);

        uint256 amount = 100 * 10 ** token.decimals();
        token.mint(sender, amount);

        vm.prank(sender);
        token.transfer(recipient, amount / 2);

        assertEq(token.balanceOf(sender), amount / 2);
        assertEq(token.balanceOf(recipient), amount / 2);
    }

    function testTransferRevertsForUnverifiedRecipient() public {
        verifier.verify(sender);

        uint256 amount = 100 * 10 ** token.decimals();
        token.mint(sender, amount);

        vm.prank(sender);
        vm.expectRevert(abi.encodeWithSelector(CLPc.UnverifiedRecipient.selector, unverified));
        token.transfer(unverified, 1);
    }

    function testTransferRevertsForUnverifiedSender() public {
        verifier.verify(sender);

        uint256 amount = 100 * 10 ** token.decimals();
        token.mint(sender, amount);
        verifier.revoke(sender);

        vm.prank(sender);
        vm.expectRevert(abi.encodeWithSelector(CLPc.UnverifiedSender.selector, sender));
        token.transfer(recipient, 1);
    }

    function testMintBatchMismatchedArraysReverts() public {
        token.grantRole(token.MINTER_ROLE(), minter);

        address[] memory recipients = new address[](1);
        recipients[0] = recipient;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        vm.prank(minter);
        vm.expectRevert(bytes("CLPc: arrays length mismatch"));
        token.mintBatch(recipients, amounts);
    }

    function testMintBatchEmptyArraysReverts() public {
        token.grantRole(token.MINTER_ROLE(), minter);

        address[] memory recipients = new address[](0);
        uint256[] memory amounts = new uint256[](0);

        vm.prank(minter);
        vm.expectRevert(bytes("CLPc: empty arrays"));
        token.mintBatch(recipients, amounts);
    }

    function testMintBatchUnverifiedRecipientReverts() public {
        token.grantRole(token.MINTER_ROLE(), minter);

        address[] memory recipients = new address[](2);
        recipients[0] = recipient;
        recipients[1] = unverified;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        vm.prank(minter);
        vm.expectRevert(abi.encodeWithSelector(CLPc.UnverifiedRecipient.selector, unverified));
        token.mintBatch(recipients, amounts);
    }

    function testMintBatchAnnualSupplyExceededReverts() public {
        token.grantRole(token.MINTER_ROLE(), minter);

        address[] memory recipients = new address[](2);
        recipients[0] = recipient;
        recipients[1] = recipient2;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = token.MAX_ANNUAL_SUPPLY();
        amounts[1] = 1;

        vm.prank(minter);
        vm.expectRevert(
            abi.encodeWithSelector(
                CLPc.AnnualSupplyExceeded.selector,
                token.MAX_ANNUAL_SUPPLY() + 1,
                token.MAX_ANNUAL_SUPPLY()
            )
        );
        token.mintBatch(recipients, amounts);
    }

    function testNonAdminCannotSetVerifier() public {
        MockZKPassportVerifier newVerifier = new MockZKPassportVerifier();

        vm.startPrank(outsider);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                outsider,
                token.DEFAULT_ADMIN_ROLE()
            )
        );
        token.setZkVerifier(address(newVerifier));
        vm.stopPrank();
    }

    function testNonPauserCannotPauseMinting() public {
        vm.startPrank(outsider);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                outsider,
                token.PAUSER_ROLE()
            )
        );
        token.setMintingPaused(true);
        vm.stopPrank();
    }
}
