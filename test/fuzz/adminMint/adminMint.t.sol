// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "../../BaseTest.sol";

contract AdminMintFuzzTest is BaseTest {
    function testFuzz_RevertWhen_CallerIsNotAdmin(address nonAdmin) external {
        vm.assume(nonAdmin != users.admin && nonAdmin != address(0));
        vm.prank({ msgSender: nonAdmin });
        vm.expectRevert(Ownable.Unauthorized.selector);
        adventurer.adminMint({ receiver: users.treasury, quantity: 1 });
    }

    modifier whenCallerIsAdmin() {
        vm.startPrank({ msgSender: users.admin });
        _;
    }

    function testFuzz_RevertWhen_TheNewAmountOfMintedTokensIsGreaterThanTheTotalSupply(uint256 amount)
        external
        whenCallerIsAdmin
    {
        uint256 remainingTokens = adventurer.MAX_TOKENS() - adventurer.totalSupply();
        amount = bound(amount, remainingTokens + 1, 10_000);

        vm.expectRevert(IAdventurer.MintExceedsTotalSupply.selector);
        adventurer.adminMint({ receiver: users.treasury, quantity: amount });
    }

    function testFuzz_WhenTheNewAmountOfMintedTokensIsLessThanTheTotalSupply(
        uint256 amount,
        address receiver
    )
        external
        whenCallerIsAdmin
    {
        amount = bound(amount, 1, adventurer.MAX_TOKENS() - adventurer.totalSupply());
        vm.assume(receiver != address(0));
        assumeNotForgeAddress({ addr: receiver });
        assumeNotPrecompile({ addr: receiver });

        uint256 oldTotalSupply = adventurer.totalSupply();
        uint256 oldUserBalance = adventurer.balanceOf({ owner: receiver });

        adventurer.adminMint({ receiver: receiver, quantity: amount });

        assertEq(adventurer.balanceOf({ owner: receiver }), oldUserBalance + amount);
        assertEq(adventurer.totalSupply(), oldTotalSupply + amount);
    }
}
