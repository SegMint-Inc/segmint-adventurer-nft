// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../../BaseTest.sol";

contract ToggleMintFuzzTest is BaseTest {
    function testFuzz_RevertWhen_CallerIsNotAdmin(address nonAdmin) external {
        vm.assume(nonAdmin != users.admin && nonAdmin != address(0));
        vm.prank({ msgSender: nonAdmin });
        vm.expectRevert(Ownable.Unauthorized.selector);
        adventurer.toggleMint();
    }

    modifier whenCallerIsAdmin() {
        vm.startPrank({ msgSender: users.admin });
        _;
    }

    function test_WhenMintIsInactive(uint256) external whenCallerIsAdmin {
        vm.expectEmit();
        emit MintStateUpdated({ oldMintState: false, newMintState: true });
        adventurer.toggleMint();
    }

    function test_WhenMintIsActive(uint256) external whenCallerIsAdmin {
        adventurer.toggleMint();

        vm.expectEmit();
        emit MintStateUpdated({ oldMintState: true, newMintState: false });
        adventurer.toggleMint();
    }
}
