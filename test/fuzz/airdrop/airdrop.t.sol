// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "../../BaseTest.sol";

contract AirdropFuzzTest is BaseTest {
    address[] internal accounts;

    function testFuzz_RevertWhen_TheCallerIsNotTheAdmin(address nonAdmin) external {
        vm.assume(nonAdmin != users.admin && nonAdmin != address(0));
        vm.prank({ msgSender: nonAdmin });
        vm.expectRevert(Ownable.Unauthorized.selector);
        adventurer.airdrop({ accounts: new address[](1) });
    }

    modifier whenTheCallerIsTheAdmin() {
        vm.startPrank({ msgSender: users.admin });
        _;
    }

    function testFuzz_RevertWhen_TheAccountsArrayIsZeroLength(uint256) external whenTheCallerIsTheAdmin {
        vm.expectRevert(IAdventurer.ZeroLengthArray.selector);
        adventurer.airdrop({ accounts: new address[](0) });
    }

    modifier whenTheAccountsArrayIsNonZeroLength() {
        _;
    }

    function testFuzz_RevertWhen_TheNewAmountOfMintedTokensIsGreaterThanTheTotalSupply(uint256 amount)
        external
        whenTheCallerIsTheAdmin
        whenTheAccountsArrayIsNonZeroLength
    {
        amount = bound(amount, adventurer.MAX_TOKENS() - adventurer.totalSupply() + 1, 10_000);
        vm.expectRevert(IAdventurer.MintExceedsTotalSupply.selector);
        adventurer.airdrop({ accounts: new address[](amount) });
    }

    modifier whenTheNewAmountOfMintedTokensIsLessThanTheTotalSupply() {
        _;
    }

    function testFuzz_RevertWhen_AnAccountInTheArrayHasAlreadyClaimed(
        uint256 amount,
        uint256 idx
    )
        external
        whenTheCallerIsTheAdmin
        whenTheAccountsArrayIsNonZeroLength
    {
        amount = bound(amount, 1, 200);
        accounts = getAccounts(amount);
        idx = bound(idx, 0, accounts.length - 1);

        adventurer.toggleMint();
        vm.stopPrank(); // Stop admin prank.

        address mintAccount = accounts[idx];
        bytes memory signature = getMintSignature({ account: mintAccount });
        vm.prank({ msgSender: mintAccount });
        adventurer.mint(signature);

        vm.prank({ msgSender: users.admin });
        vm.expectRevert(IAdventurer.AccountHasClaimed.selector);
        adventurer.airdrop(accounts);
    }

    function testFuzz_WhenNoAccountsInTheArrayHaveClaimed(uint256 amount)
        external
        whenTheCallerIsTheAdmin
        whenTheAccountsArrayIsNonZeroLength
    {
        amount = bound(amount, 1, 200);
        accounts = getAccounts(amount);

        uint256 nextTokenId = adventurer.totalSupply() + 1;

        for (uint256 i = 0; i < accounts.length; i++) {
            vm.expectEmit();
            emit Airdropped({ account: accounts[i], tokenId: nextTokenId });
            nextTokenId++;
        }

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
