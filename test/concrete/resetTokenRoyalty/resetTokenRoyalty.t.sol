// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "../../BaseTest.sol";

contract ResetTokenRoyaltyConcreteTest is BaseTest {
    function test_RevertWhen_CallerIsNotAdmin() external {
        vm.prank({ msgSender: users.eve });
        vm.expectRevert(Ownable.Unauthorized.selector);
        adventurer.resetTokenRoyalty({ tokenId: 1 });
    }

    function test_WhenCallerIsAdmin() external {
        // it should reset the token royalty
        vm.prank({ msgSender: users.admin });
        adventurer.resetTokenRoyalty({ tokenId: 1 });

        (address receiver, uint256 royaltyAmount) = adventurer.royaltyInfo({ tokenId: 1, salePrice: 1 ether });
        assertEq(receiver, address(0));
        assertEq(royaltyAmount, 0);
    }
}
