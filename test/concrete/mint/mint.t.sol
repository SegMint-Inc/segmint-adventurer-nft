// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../../BaseTest.sol";

contract MintConcreteTest is BaseTest {
    function test_RevertWhen_MintIsInactive() external {
        bytes memory signature = getMintSignature({ account: users.alice });
        vm.prank({ msgSender: users.alice });
        vm.expectRevert(IAdventurer.MintInactive.selector);
        adventurer.mint(signature);
    }

    modifier whenMintIsActive() {
        vm.prank({ msgSender: users.admin });
        adventurer.toggleMint();
        _;
    }

    function test_RevertWhen_TheAccountHasAlreadyClaimed() external whenMintIsActive {
        bytes memory signature = getMintSignature({ account: users.alice });
        vm.startPrank({ msgSender: users.alice });
        adventurer.mint(signature);
        vm.expectRevert(IAdventurer.AccountHasClaimed.selector);
        adventurer.mint(signature);
    }

    modifier whenTheAccountHasNotClaimed() {
        _;
    }

    function test_RevertWhen_TheSignatureIsInvalid() external whenMintIsActive whenTheAccountHasNotClaimed {
        bytes memory signature = getMintSignature({ account: users.alice });
        vm.prank({ msgSender: users.eve });
        vm.expectRevert(IAdventurer.SignerMismatch.selector);
        adventurer.mint(signature);
    }

    function test_WhenTheSignatureIsValid() external whenMintIsActive whenTheAccountHasNotClaimed {
        bytes memory signature = getMintSignature({ account: users.alice });
        vm.prank({ msgSender: users.alice });
        adventurer.mint(signature);

        assertTrue(adventurer.hasClaimed({ account: users.alice }));
        uint256 treasuryAllocation = adventurer.TREASURY_ALLOCATION();
        assertEq(adventurer.totalSupply(), treasuryAllocation + 1);
        assertEq(adventurer.balanceOf({ owner: users.alice }), 1);
    }
}
