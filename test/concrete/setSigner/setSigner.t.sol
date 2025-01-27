// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../../BaseTest.sol";

contract SetSignerConcreteTest is BaseTest {
    function test_RevertWhen_CallerIsNotAdmin() external {
        vm.prank({ msgSender: users.eve });
        vm.expectRevert(Ownable.Unauthorized.selector);
        adventurer.setSigner({ newSigner: users.signer.addr });
    }

    modifier whenCallerIsAdmin() {
        vm.startPrank({ msgSender: users.admin });
        _;
    }

    function test_RevertWhen_NewSignerIsZeroAddress() external whenCallerIsAdmin {
        vm.expectRevert(IAdventurer.ZeroAddress.selector);
        adventurer.setSigner({ newSigner: address(0) });
    }

    function test_WhenNewSignerIsNotZeroAddress() external whenCallerIsAdmin {
        vm.expectEmit();
        emit SignerUpdated({ oldSigner: users.signer.addr, newSigner: users.alice });
        adventurer.setSigner({ newSigner: users.alice });
        assertEq(adventurer.signer(), users.alice);
    }
}
