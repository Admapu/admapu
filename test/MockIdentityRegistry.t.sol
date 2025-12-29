// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "forge-std/Test.sol";
import {MockIdentityRegistry} from "../src/mocks/MockIdentityRegistry.sol";

contract MockIdentityRegistryTest is Test {
  MockIdentityRegistry reg;

  address admin = address(0xA11CE);
  address issuer = address(0x155UER);
  address user = address(0xB0B);

  function setUp() public {
    reg = new MockIdentityRegistry(admin);

    vm.prank(admin);
    reg.grantRole(reg.ISSUER_ROLE(), issuer);
  }

  function testAdminIsIssuerByDefault() public {
    assertTrue(reg.hasRole(reg.ISSUER_ROLE(), admin));
    assertTrue(reg.hasRole(reg.DEFAULT_ADMIN_ROLE(), admin));
  }

  function testNonIssuerCannotSetIdentity() public {
    vm.expectRevert(); // AccessControl revert
    reg.setIdentity(user, true, true, true);
  }

  function testIssuerCanSetIdentityAndRead() public {
    vm.prank(issuer);
    reg.setIdentity(user, true, true, false);

    assertTrue(reg.isVerifiedChilean(user));
    assertTrue(reg.isSenior(user));
    assertFalse(reg.hasChronicMeds(user));

    MockIdentityRegistry.Identity memory id = reg.getIdentity(user);
    assertTrue(id.verifiedChilean);
    assertTrue(id.senior);
    assertFalse(id.chronicMeds);
  }

  function testSettersUpdateIndividually() public {
    vm.prank(issuer);
    reg.setIdentity(user, false, false, false);

    vm.prank(issuer);
    reg.setVerifiedChilean(user, true);

    assertTrue(reg.isVerifiedChilean(user));
    assertFalse(reg.isSenior(user));
    assertFalse(reg.hasChronicMeds(user));

    vm.prank(issuer);
    reg.setSenior(user, true);

    assertTrue(reg.isVerifiedChilean(user));
    assertTrue(reg.isSenior(user));
    assertFalse(reg.hasChronicMeds(user));

    vm.prank(issuer);
    reg.setChronicMeds(user, true);

    assertTrue(reg.isVerifiedChilean(user));
    assertTrue(reg.isSenior(user));
    assertTrue(reg.hasChronicMeds(user));
  }

  function testZeroAddressRejected() public {
    vm.prank(issuer);
    vm.expectRevert(bytes("user=0"));
    reg.setIdentity(address(0), true, true, true);
  }
}

