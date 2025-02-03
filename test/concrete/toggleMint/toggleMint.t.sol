// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "../../BaseTest.sol";

contract ToggleMintConcreteTest is BaseTest {
    function test_RevertWhen_CallerIsNotAdmin() external {
        vm.prank({ msgSender: users.eve });
        vm.expectRevert(Ownable.Unauthorized.selector);
        adventurer.toggleMint();
    }

    modifier whenCallerIsAdmin() {
        vm.startPrank({ msgSender: users.admin });
        _;
    }

    function test_WhenMintIsInactive() external whenCallerIsAdmin {
        vm.expectEmit();
        emit MintStateUpdated({ oldMintState: false, newMintState: true });
        adventurer.toggleMint();
    }

    function test_WhenMintIsActive() external whenCallerIsAdmin {
        adventurer.toggleMint();

        vm.expectEmit();
        emit MintStateUpdated({ oldMintState: true, newMintState: false });
        adventurer.toggleMint();
    }
}
