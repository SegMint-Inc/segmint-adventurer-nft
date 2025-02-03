// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "../../BaseTest.sol";

contract UpdateMetadataConcreteTest is BaseTest {
    function test_WhenUpdateMetadataIsCalled() external {
        uint256 totalSupply = adventurer.totalSupply();

        vm.prank({ msgSender: users.admin });
        vm.expectEmit();
        emit BatchMetadataUpdate({ _fromTokenId: 1, _toTokenId: totalSupply });
        adventurer.updateMetadata();
    }
}
