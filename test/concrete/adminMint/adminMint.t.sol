// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../../BaseTest.sol";

contract AdminMintConcreteTest is BaseTest {
// function test_RevertWhen_CallerIsNotAdmin() external {
//     vm.prank({ msgSender: users.eve });
//     vm.expectRevert(Ownable.Unauthorized.selector);
//     adventurer.adminMint({ receiver: users.treasury, quantity: 1 });
// }

// modifier whenCallerIsAdmin() {
//     vm.startPrank({ msgSender: users.admin });
//     _;
// }

// function test_WhenRemainderIsGreaterThanMaxBatchSize() external whenCallerIsAdmin {
//     uint256 totalSupply = adventurer.TOTAL_SUPPLY();
//     adventurer.mintRemainder({ receiver: users.treasury });
//     assertEq(adventurer.balanceOf({ owner: users.treasury }), totalSupply);
// }

// function test_WhenRemainderIsLessThanOrEqualToMaxBatchSize() external whenCallerIsAdmin {
//     // it should mint all remaining tokens in one batch
//     vm.skip(true);
// }
}
