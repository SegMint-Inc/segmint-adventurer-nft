// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../../BaseTest.sol";

contract SetTokenRoyaltyConcreteTest is BaseTest {
    uint96 internal constant NEW_FEE_NUMERATOR = 100;

    function test_RevertWhen_CallerIsNotAdmin() external {
        vm.prank({ msgSender: users.eve });
        vm.expectRevert(Ownable.Unauthorized.selector);
        adventurer.setTokenRoyalty({ tokenId: 1, receiver: users.treasury, feeNumerator: NEW_FEE_NUMERATOR });
    }

    function test_WhenCallerIsAdmin() external {
        vm.prank({ msgSender: users.admin });
        adventurer.setTokenRoyalty({ tokenId: 1, receiver: users.treasury, feeNumerator: NEW_FEE_NUMERATOR });

        uint256 purchaseAmount = 1 ether;
        (address receiver, uint256 royaltyAmount) = adventurer.royaltyInfo({ tokenId: 1, salePrice: purchaseAmount });
        uint256 expectedRoyaltyAmount = (purchaseAmount * NEW_FEE_NUMERATOR) / MAX_BPS;

        assertEq(receiver, users.treasury);
        assertEq(royaltyAmount, expectedRoyaltyAmount);
    }
}
