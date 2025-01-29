// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../../BaseTest.sol";

contract AdminMintConcreteTest is BaseTest {
    function test_RevertWhen_CallerIsNotAdmin() external {
        vm.prank({ msgSender: users.eve });
        vm.expectRevert(Ownable.Unauthorized.selector);
        adventurer.adminMint({ receiver: users.treasury, quantity: 1 });
    }

    modifier whenCallerIsAdmin() {
        vm.startPrank({ msgSender: users.admin });
        _;
    }

    function test_RevertWhen_TheNewAmountOfMintedTokensIsGreaterThanTheTotalSupply() external whenCallerIsAdmin {
        uint256 remainder = adventurer.MAX_TOKENS() - adventurer.totalSupply();
        vm.expectRevert(IAdventurer.MintExceedsTotalSupply.selector);
        adventurer.adminMint({ receiver: users.treasury, quantity: remainder + 1 });
    }

    function test_WhenTheNewAmountOfMintedTokensIsLessThanTheTotalSupply() external whenCallerIsAdmin {
        uint256 amount = 50;
        uint256 oldTotalSupply = adventurer.totalSupply();
        uint256 oldUserBalance = adventurer.balanceOf({ owner: users.alice });

        adventurer.adminMint({ receiver: users.alice, quantity: amount });

        assertEq(adventurer.balanceOf({ owner: users.alice }), oldUserBalance + amount);
        assertEq(adventurer.totalSupply(), oldTotalSupply + amount);
    }
}
