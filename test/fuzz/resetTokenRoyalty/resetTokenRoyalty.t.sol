// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "../../BaseTest.sol";

contract ResetTokenRoyaltyFuzzTest is BaseTest {
    function testFuzz_RevertWhen_CallerIsNotAdmin(address nonAdmin) external {
        vm.assume(nonAdmin != users.admin && nonAdmin != address(0));
        vm.prank({ msgSender: nonAdmin });
        vm.expectRevert(Ownable.Unauthorized.selector);
        adventurer.resetTokenRoyalty({ tokenId: 1 });
    }

    function testFuzz_WhenCallerIsAdmin(uint256 tokenId, uint256 salePrice) external {
        tokenId = bound(tokenId, 1, adventurer.totalSupply());
        salePrice = bound(salePrice, 1 wei, 1 ether);

        vm.prank({ msgSender: users.admin });
        adventurer.resetTokenRoyalty(tokenId);

        (address receiver, uint256 royaltyAmount) = adventurer.royaltyInfo(tokenId, salePrice);
        assertEq(receiver, address(0));
        assertEq(royaltyAmount, 0);
    }
}
