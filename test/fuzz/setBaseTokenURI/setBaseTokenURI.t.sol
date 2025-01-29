// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../../BaseTest.sol";

contract SetBaseTokenURIFuzzTest is BaseTest {
    function testFuzz_RevertWhen_CallerIsNotAdmin(address nonAdmin, string calldata newBaseTokenURI) external {
        vm.assume(nonAdmin != users.admin && nonAdmin != address(0));
        vm.assume(bytes(newBaseTokenURI).length < 32);

        vm.prank({ msgSender: nonAdmin });
        vm.expectRevert(Ownable.Unauthorized.selector);
        adventurer.setBaseTokenURI(newBaseTokenURI);
    }

    function testFuzz_WhenCallerIsAdmin(string calldata newBaseTokenURI) external {
        vm.assume(bytes(newBaseTokenURI).length < 32);

        vm.prank({ msgSender: users.admin });
        adventurer.setBaseTokenURI(newBaseTokenURI);
        assertEq(adventurer.baseTokenURI(), newBaseTokenURI);
    }
}
