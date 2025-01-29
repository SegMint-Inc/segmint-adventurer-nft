// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../../BaseTest.sol";

contract SetDefaultRoyaltyFuzzTest is BaseTest {
    uint96 internal constant NEW_FEE_NUMERATOR = 100;

    function testFuzz_RevertWhen_CallerIsNotAdmin(address nonAdmin, uint96 feeNumerator) external {
        vm.assume(nonAdmin != users.admin && nonAdmin != address(0));
        vm.assume(feeNumerator <= MAX_BPS);

        vm.prank({ msgSender: nonAdmin });
        vm.expectRevert(Ownable.Unauthorized.selector);
        adventurer.setDefaultRoyalty({ receiver: users.treasury, feeNumerator: feeNumerator });
    }

    function testFuzz_WhenCallerIsAdmin(
        address receiver,
        uint256 tokenId,
        uint96 feeNumerator,
        uint256 salePrice
    )
        external
    {
        vm.assume(receiver != address(0));
        tokenId = bound(tokenId, 1, adventurer.totalSupply());
        vm.assume(feeNumerator <= MAX_BPS);
        salePrice = bound(salePrice, 1 wei, 1 ether);

        vm.prank({ msgSender: users.admin });
        adventurer.setDefaultRoyalty(receiver, feeNumerator);

        (address royaltyReceiver, uint256 royaltyAmount) = adventurer.royaltyInfo(tokenId, salePrice);
        uint256 expectedRoyaltyAmount = salePrice * feeNumerator / MAX_BPS;

        assertEq(receiver, royaltyReceiver);
        assertEq(royaltyAmount, expectedRoyaltyAmount);
    }
}
