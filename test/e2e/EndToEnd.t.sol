// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "../BaseTest.sol";

contract EndToEndTest is BaseTest {
    /**
     * @dev This test emulates the entire flow of the minting process. It starts with the contract being initialized
     * and 550 tokens being allocated to the treasury. Then, the airdrop to OG users is commenced consisting of
     * minting 120 tokens. The minting is then toggled on and 6000 regular users mint 1 token each. Finally, minting
     * is toggled off and the remaining tokens are minted to the treasury.
     */
    function test_EndToEnd() external {
        // Confirm treasury amount has been allocated.
        assertEq(adventurer.balanceOf({ owner: users.treasury }), adventurer.TREASURY_ALLOCATION());

        // Commence airdrop of 120 tokens to OG users.
        uint256 airdropAmount = 120;
        address[] memory airdropUsers = new address[](airdropAmount);
        for (uint256 i = 0; i < airdropAmount; i++) {
            airdropUsers[i] = vm.createWallet({ walletLabel: string.concat(vm.toString(i), "airdrop") }).addr;
        }

        vm.prank({ msgSender: users.admin });
        adventurer.airdrop({ accounts: airdropUsers });

        // Confirm each airdrop user has received 1 token.
        for (uint256 i = 0; i < airdropAmount; i++) {
            address airdropUser = airdropUsers[i];
            assertTrue(adventurer.hasClaimed({ account: airdropUser }));
            assertEq(adventurer.balanceOf({ owner: airdropUser }), 1);
        }

        // Toggle minting.
        assertFalse(adventurer.mintable());
        vm.expectEmit();
        emit MintStateUpdated({ oldMintState: false, newMintState: true });
        vm.prank({ msgSender: users.admin });
        adventurer.toggleMint();
        assertTrue(adventurer.mintable());

        // Mint 6000 tokens as regular users.
        uint256 mintAmount = 6000;
        address[] memory mintUsers = getAccounts({ amount: mintAmount });
        bytes memory signature;

        // Confirm each minting user has received 1 token.
        for (uint256 i = 0; i < mintAmount; i++) {
            address mintUser = mintUsers[i];
            signature = getMintSignature({ account: mintUser });

            vm.prank({ msgSender: mintUser });
            adventurer.mint(signature);

            assertTrue(adventurer.hasClaimed({ account: mintUser }));
            assertEq(adventurer.balanceOf({ owner: mintUser }), 1);
        }

        // Toggle minting.
        assertTrue(adventurer.mintable());
        vm.expectEmit();
        emit MintStateUpdated({ oldMintState: true, newMintState: false });
        vm.prank({ msgSender: users.admin });
        adventurer.toggleMint();
        assertFalse(adventurer.mintable());

        // Mint remaining tokens to treasury.
        uint256 remainingTokens = adventurer.MAX_TOKENS() - adventurer.totalSupply();
        uint256 oldTreasuryBalance = adventurer.balanceOf({ owner: users.treasury });
        uint256 oldTotalSupply = adventurer.totalSupply();

        vm.prank({ msgSender: users.admin });
        adventurer.adminMint({ receiver: users.treasury, quantity: remainingTokens });

        // Confirm treasury has received all remaining tokens.
        assertEq(adventurer.balanceOf({ owner: users.treasury }), oldTreasuryBalance + remainingTokens);
        assertEq(adventurer.totalSupply(), oldTotalSupply + remainingTokens);
        assertEq(adventurer.totalSupply(), adventurer.MAX_TOKENS());
    }
}
