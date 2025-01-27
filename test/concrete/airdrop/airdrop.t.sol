// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../../BaseTest.sol";

contract AirdropConcreteTest is BaseTest {
    function test_RevertWhen_CallerIsNotAdmin() external {
        address[] memory accounts = new address[](1);
        accounts[0] = users.eve;

        vm.prank({ msgSender: users.eve });
        vm.expectRevert(Ownable.Unauthorized.selector);
        adventurer.airdrop(accounts);
    }

    modifier whenCallerIsAdmin() {
        vm.startPrank({ msgSender: users.admin });
        _;
    }

    function test_RevertWhen_AccountsArrayIsEmpty() external whenCallerIsAdmin {
        vm.expectRevert(IAdventurer.ZeroLengthArray.selector);
        adventurer.airdrop({ accounts: new address[](0) });
    }

    function test_RevertWhen_AccountsLengthDoesNotMatchTheAirdropAllocation() external whenCallerIsAdmin {
        address[] memory accounts = new address[](1);
        accounts[0] = users.alice;

        vm.expectRevert(IAdventurer.InvalidAirdropAmount.selector);
        adventurer.airdrop(accounts);
    }

    function test_RevertWhen_AirdropIsAlreadyComplete() external whenCallerIsAdmin {
        uint256 airdropAllocation = adventurer.AIRDROP_ALLOCATION();
        address[] memory accounts = new address[](airdropAllocation);
        for (uint256 i = 0; i < airdropAllocation; i++) {
            accounts[i] = vm.createWallet({ walletLabel: vm.toString(i) }).addr;
        }

        adventurer.airdrop(accounts);
        vm.expectRevert(IAdventurer.AirdropComplete.selector);
        adventurer.airdrop(accounts);
    }

    modifier whenAirdropConditionsAreValid() {
        _;
    }

    function test_RevertWhen_AnAccountInArrayHasAlreadyClaimed()
        external
        whenCallerIsAdmin
        whenAirdropConditionsAreValid
    {
        uint256 airdropAllocation = adventurer.AIRDROP_ALLOCATION();
        address[] memory accounts = new address[](airdropAllocation);
        for (uint256 i = 0; i < airdropAllocation; i++) {
            accounts[i] = vm.createWallet({ walletLabel: vm.toString(i) }).addr;
        }
        accounts[0] = accounts[1];

        vm.expectRevert(IAdventurer.AccountHasClaimed.selector);
        adventurer.airdrop(accounts);
    }

    function test_WhenNoAccountsHaveClaimed() external whenCallerIsAdmin whenAirdropConditionsAreValid {
        uint256 airdropAllocation = adventurer.AIRDROP_ALLOCATION();
        address[] memory accounts = new address[](airdropAllocation);
        for (uint256 i = 0; i < airdropAllocation; i++) {
            accounts[i] = vm.createWallet({ walletLabel: vm.toString(i) }).addr;
        }

        adventurer.airdrop(accounts);

        uint256 treasuryAllocation = adventurer.TREASURY_ALLOCATION();
        assertTrue(adventurer.airdropped());
        assertEq(adventurer.totalSupply(), airdropAllocation + treasuryAllocation);
        for (uint256 i = 0; i < airdropAllocation; i++) {
            address account = accounts[i];
            assertTrue(adventurer.hasClaimed({ account: account }));
            assertEq(adventurer.balanceOf({ owner: account }), 1);
        }
    }
}
