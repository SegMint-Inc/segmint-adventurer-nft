// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./BaseTest.sol";

contract AdventurerTest is BaseTest {

    function setUp() public override {
        super.setUp();
    }

    /**
     * Ensures the test environment was initialized correctly.
     */
    function test_Deployment() public {
        assertEq(adventurer.name(), "Adventurer");
        assertEq(adventurer.symbol(), "ADVNT");
        assertEq(adventurer.owner(), address(this));
        assertEq(adventurer.signer(), users.signer.addr);
        assertEq(adventurer.accessRegistry(), accessRegistry);
        assertTrue(adventurer.hasAllRoles({ user: users.admin.addr, roles: AccessRoles.ADMIN_ROLE }));
    }

}
