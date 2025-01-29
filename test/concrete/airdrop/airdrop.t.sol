// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../../BaseTest.sol";

contract AirdropConcreteTest is BaseTest {
    address[] internal accounts;

    function test_RevertWhen_TheCallerIsNotTheAdmin() external {
        vm.prank({ msgSender: users.eve });
        vm.expectRevert(Ownable.Unauthorized.selector);
        adventurer.airdrop({ accounts: new address[](1) });
    }

    modifier whenTheCallerIsTheAdmin() {
        vm.startPrank({ msgSender: users.admin });
        _;
    }

    function test_RevertWhen_TheAccountsArrayIsZeroLength() external whenTheCallerIsTheAdmin {
        vm.expectRevert(IAdventurer.ZeroLengthArray.selector);
        adventurer.airdrop({ accounts: new address[](0) });
    }

    modifier whenTheAccountsArrayIsNonZeroLength() {
        for (uint256 i = 0; i < 20; i++) {
            accounts.push(vm.createWallet({ walletLabel: vm.toString(i) }).addr);
        }
        _;
    }

    function test_RevertWhen_TheNewAmountOfMintedTokensIsGreaterThanTheTotalSupply()
        external
        whenTheCallerIsTheAdmin
        whenTheAccountsArrayIsNonZeroLength
    {
        uint256 remainder = adventurer.MAX_TOKENS() - adventurer.totalSupply();
        adventurer.adminMint({ receiver: users.treasury, quantity: remainder });

        vm.expectRevert(IAdventurer.MintExceedsTotalSupply.selector);
        adventurer.airdrop(accounts);
    }

    modifier whenTheNewAmountOfMintedTokensIsLessThanTheTotalSupply() {
        _;
    }

    function test_RevertWhen_AnAccountInTheArrayHasAlreadyClaimed()
        external
        whenTheCallerIsTheAdmin
        whenTheAccountsArrayIsNonZeroLength
    {
        adventurer.toggleMint();
        vm.stopPrank(); // Stop admin prank.

        bytes memory signature = getMintSignature({ account: users.alice });
        vm.prank({ msgSender: users.alice });
        adventurer.mint(signature);
        accounts[0] = users.alice;

        vm.prank({ msgSender: users.admin });
        vm.expectRevert(IAdventurer.AccountHasClaimed.selector);
        adventurer.airdrop(accounts);
    }

    function test_WhenNoAccountsInTheArrayHaveClaimed()
        external
        whenTheCallerIsTheAdmin
        whenTheAccountsArrayIsNonZeroLength
    {
        adventurer.airdrop(accounts);

        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            assertTrue(adventurer.hasClaimed(account));
            assertEq(adventurer.balanceOf({ owner: account }), 1);
        }

        uint256 expectedTotalSupply = adventurer.TREASURY_ALLOCATION() + accounts.length;
        assertEq(adventurer.totalSupply(), expectedTotalSupply);
    }
}
