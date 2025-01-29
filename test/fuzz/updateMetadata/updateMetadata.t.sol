// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../../BaseTest.sol";

contract UpdateMetadataFuzzTest is BaseTest {
    function testFuzz_RevertWhen_CallerIsNotAdmin(address nonAdmin) external {
        vm.assume(nonAdmin != users.admin && nonAdmin != address(0));
        vm.prank({ msgSender: nonAdmin });
        vm.expectRevert(Ownable.Unauthorized.selector);
        adventurer.updateMetadata();
    }

    function test_WhenCallerIsAdmin(uint256) external {
        uint256 totalSupply = adventurer.totalSupply();

        vm.prank({ msgSender: users.admin });
        vm.expectEmit();
        emit BatchMetadataUpdate({ _fromTokenId: 1, _toTokenId: totalSupply });
        adventurer.updateMetadata();
    }
}
