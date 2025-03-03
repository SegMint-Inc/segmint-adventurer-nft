// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "../../BaseTest.sol";

contract SetDefaultRoyaltyConcreteTest is BaseTest {
    uint96 internal constant NEW_FEE_NUMERATOR = 100;

    function test_RevertWhen_CallerIsNotAdmin() external {
        vm.prank({ msgSender: users.eve });
        vm.expectRevert(Ownable.Unauthorized.selector);
        adventurer.setDefaultRoyalty({ receiver: users.treasury, feeNumerator: NEW_FEE_NUMERATOR });
    }

    function test_WhenCallerIsAdmin() external {
        vm.prank({ msgSender: users.admin });
        adventurer.setDefaultRoyalty({ receiver: users.treasury, feeNumerator: NEW_FEE_NUMERATOR });

        uint256 purchaseAmount = 1 ether;
        (address receiver, uint256 royaltyAmount) = adventurer.royaltyInfo({ tokenId: 1, salePrice: purchaseAmount });
        uint256 expectedRoyaltyAmount = (purchaseAmount * NEW_FEE_NUMERATOR) / MAX_BPS;

        assertEq(receiver, users.treasury);
        assertEq(royaltyAmount, expectedRoyaltyAmount);
    }
}
