// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../../BaseTest.sol";

contract DeleteDefaultRoyaltyFuzzTest is BaseTest {
    function testFuzz_RevertWhen_CallerIsNotAdmin(address nonAdmin) external {
        vm.assume(nonAdmin != users.admin && nonAdmin != address(0));
        vm.prank({ msgSender: nonAdmin });
        vm.expectRevert(Ownable.Unauthorized.selector);
        adventurer.deleteDefaultRoyalty();
    }

    function testFuzz_WhenCallerIsAdmin() external {
        vm.prank({ msgSender: users.admin });
        adventurer.deleteDefaultRoyalty();

        (address receiver, uint256 royaltyAmount) = adventurer.royaltyInfo({ tokenId: 1, salePrice: 1 ether });
        assertEq(receiver, address(0));
        assertEq(royaltyAmount, 0);
    }
}
