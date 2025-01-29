// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../../BaseTest.sol";

contract SetTokenRoyaltyFuzzTest is BaseTest {
    function testFuzz_RevertWhen_CallerIsNotAdmin(address nonAdmin) external {
        vm.assume(nonAdmin != users.admin && nonAdmin != address(0));
        vm.prank({ msgSender: nonAdmin });
        vm.expectRevert(Ownable.Unauthorized.selector);
        adventurer.setTokenRoyalty({ tokenId: 1, receiver: users.treasury, feeNumerator: 0 });
    }

    function testFuzz_WhenCallerIsAdmin(uint256 tokenId, uint256 feeNumerator, uint256 salePrice) external {
        tokenId = bound(tokenId, 1, adventurer.totalSupply());
        feeNumerator = bound(feeNumerator, 0, MAX_BPS);
        salePrice = bound(salePrice, 1 wei, 1 ether);

        vm.prank({ msgSender: users.admin });
        adventurer.setTokenRoyalty({ tokenId: tokenId, receiver: users.treasury, feeNumerator: uint96(feeNumerator) });

        (address royaltyReceiver, uint256 royaltyAmount) = adventurer.royaltyInfo(tokenId, salePrice);
        uint256 expectedRoyaltyAmount = salePrice * feeNumerator / MAX_BPS;

        assertEq(royaltyReceiver, users.treasury);
        assertEq(royaltyAmount, expectedRoyaltyAmount);
    }
}
