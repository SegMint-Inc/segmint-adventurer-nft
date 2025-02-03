// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "../../BaseTest.sol";

contract MintConcreteTest is BaseTest {
    function test_RevertWhen_TheMintIsInactive() external {
        bytes memory signature = getMintSignature({ account: users.alice });

        vm.prank({ msgSender: users.alice });
        vm.expectRevert(IAdventurer.MintInactive.selector);
        adventurer.mint(signature);
    }

    modifier whenTheMintIsActive() {
        vm.prank({ msgSender: users.admin });
        adventurer.toggleMint();
        _;
    }

    function test_RevertWhen_TheNewAmountOfMintedTokensIsGreaterThanTheTotalSupply() external whenTheMintIsActive {
        uint256 remainder = adventurer.MAX_TOKENS() - adventurer.totalSupply();
        vm.prank({ msgSender: users.admin });
        adventurer.adminMint({ receiver: users.treasury, quantity: remainder });

        bytes memory signature = getMintSignature({ account: users.alice });

        vm.prank({ msgSender: users.alice });
        vm.expectRevert(IAdventurer.MintExceedsTotalSupply.selector);
        adventurer.mint(signature);
    }

    modifier whenTheNewAmountOfMintedTokensIsLessThanTheTotalSupply() {
        _;
    }

    function test_RevertWhen_TheAccountHasAlreadyClaimed()
        external
        whenTheMintIsActive
        whenTheNewAmountOfMintedTokensIsLessThanTheTotalSupply
    {
        bytes memory signature = getMintSignature({ account: users.alice });

        vm.startPrank({ msgSender: users.alice });
        adventurer.mint(signature);
        vm.expectRevert(IAdventurer.AccountHasClaimed.selector);
        adventurer.mint(signature);
    }

    modifier whenTheAccountHasNotClaimed() {
        _;
    }

    function test_RevertWhen_TheSignatureIsInvalid()
        external
        whenTheMintIsActive
        whenTheNewAmountOfMintedTokensIsLessThanTheTotalSupply
        whenTheAccountHasNotClaimed
    {
        bytes memory signature = getMintSignature({ account: users.alice });

        vm.prank({ msgSender: users.eve });
        vm.expectRevert(IAdventurer.SignerMismatch.selector);
        adventurer.mint(signature);
    }

    function test_WhenTheSignatureIsValid()
        external
        whenTheMintIsActive
        whenTheNewAmountOfMintedTokensIsLessThanTheTotalSupply
        whenTheAccountHasNotClaimed
    {
        bytes memory signature = getMintSignature({ account: users.alice });
        uint256 oldTotalSupply = adventurer.totalSupply();

        vm.prank({ msgSender: users.alice });
        adventurer.mint(signature);

        assertTrue(adventurer.hasClaimed(users.alice));
        assertEq(adventurer.balanceOf({ owner: users.alice }), 1);
        assertEq(adventurer.totalSupply(), oldTotalSupply + 1);
    }
}
