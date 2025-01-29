// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../../BaseTest.sol";

contract MintFuzzTest is BaseTest {
    function testFuzz_RevertWhen_TheMintIsInactive(uint256) external {
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

    function testFuzz_RevertWhen_TheNewAmountOfMintedTokensIsGreaterThanTheTotalSupply(address account)
        external
        whenTheMintIsActive
    {
        vm.assume(account != address(0));
        assumeNotForgeAddress({ addr: account });
        assumeNotPrecompile({ addr: account });

        vm.prank({ msgSender: users.admin });
        adventurer.adminMint({ receiver: users.treasury, quantity: 6450 });

        bytes memory signature = getMintSignature(account);

        vm.prank({ msgSender: account });
        vm.expectRevert(IAdventurer.MintExceedsTotalSupply.selector);
        adventurer.mint(signature);
    }

    modifier whenTheNewAmountOfMintedTokensIsLessThanTheTotalSupply() {
        _;
    }

    function testFuzz_RevertWhen_TheAccountHasAlreadyClaimed(address account)
        external
        whenTheMintIsActive
        whenTheNewAmountOfMintedTokensIsLessThanTheTotalSupply
    {
        vm.assume(account != address(0));
        assumeNotForgeAddress({ addr: account });
        assumeNotPrecompile({ addr: account });

        bytes memory signature = getMintSignature(account);

        vm.startPrank({ msgSender: account });
        adventurer.mint(signature);
        vm.expectRevert(IAdventurer.AccountHasClaimed.selector);
        adventurer.mint(signature);
    }

    modifier whenTheAccountHasNotClaimed() {
        _;
    }

    function testFuzz_RevertWhen_TheSignatureIsInvalid(address account)
        external
        whenTheMintIsActive
        whenTheNewAmountOfMintedTokensIsLessThanTheTotalSupply
        whenTheAccountHasNotClaimed
    {
        vm.assume(account != address(0) && account != users.alice);
        assumeNotForgeAddress({ addr: account });
        assumeNotPrecompile({ addr: account });

        bytes memory signature = getMintSignature({ account: users.alice });

        vm.prank({ msgSender: account });
        vm.expectRevert(IAdventurer.SignerMismatch.selector);
        adventurer.mint(signature);
    }

    function testFuzz_WhenTheSignatureIsValid(address account)
        external
        whenTheMintIsActive
        whenTheNewAmountOfMintedTokensIsLessThanTheTotalSupply
        whenTheAccountHasNotClaimed
    {
        vm.assume(account != address(0));
        assumeNotForgeAddress({ addr: account });
        assumeNotPrecompile({ addr: account });

        bytes memory signature = getMintSignature(account);
        uint256 oldTotalSupply = adventurer.totalSupply();

        vm.prank({ msgSender: account });
        adventurer.mint(signature);

        assertTrue(adventurer.hasClaimed(account));
        assertEq(adventurer.balanceOf({ owner: account }), 1);
        assertEq(adventurer.totalSupply(), oldTotalSupply + 1);
    }
}
