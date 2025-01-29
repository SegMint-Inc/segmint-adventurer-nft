// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../../BaseTest.sol";

contract SetSignerFuzzTest is BaseTest {
    function testFuzz_RevertWhen_CallerIsNotAdmin(address nonAdmin) external {
        vm.assume(nonAdmin != users.admin && nonAdmin != address(0));
        vm.prank({ msgSender: nonAdmin });
        vm.expectRevert(Ownable.Unauthorized.selector);
        adventurer.setSigner({ newSigner: users.signer.addr });
    }

    modifier whenCallerIsAdmin() {
        vm.startPrank({ msgSender: users.admin });
        _;
    }

    function testFuzz_RevertWhen_NewSignerIsZeroAddress(uint256) external whenCallerIsAdmin {
        vm.expectRevert(IAdventurer.ZeroAddress.selector);
        adventurer.setSigner({ newSigner: address(0) });
    }

    function testFuzz_WhenNewSignerIsNotZeroAddress(address newSigner) external whenCallerIsAdmin {
        vm.assume(newSigner != address(0));

        vm.expectEmit();
        emit SignerUpdated({ oldSigner: users.signer.addr, newSigner: newSigner });
        adventurer.setSigner({ newSigner: newSigner });
        assertEq(adventurer.signer(), newSigner);
    }
}
