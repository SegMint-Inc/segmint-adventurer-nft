// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../../BaseTest.sol";

contract MintRemainderConcreteTest is BaseTest {
    function test_RevertWhen_CallerIsNotAdmin() external {
        vm.prank({ msgSender: users.eve });
        vm.expectRevert(Ownable.Unauthorized.selector);
        adventurer.mintRemainder({ receiver: users.treasury });
    }

    modifier whenCallerIsAdmin() {
        _;
    }

    function test_WhenRemainderIsGreaterThanMaxBatchSize() external whenCallerIsAdmin {
        vm.expectEmit();
        // it should mint tokens in batches of max size
        // it should mint remaining tokens in final batch
        vm.skip(true);
    }

    function test_WhenRemainderIsLessThanOrEqualToMaxBatchSize() external whenCallerIsAdmin {
        // it should mint all remaining tokens in one batch
        vm.skip(true);
    }
}
