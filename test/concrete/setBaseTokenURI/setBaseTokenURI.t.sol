// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "../../BaseTest.sol";

contract SetBaseTokenURIConcreteTest is BaseTest {
    string internal constant NEW_BASE_TOKEN_URI = "https://example.com";

    function test_RevertWhen_CallerIsNotAdmin() external {
        vm.prank({ msgSender: users.eve });
        vm.expectRevert(Ownable.Unauthorized.selector);
        adventurer.setBaseTokenURI({ newBaseTokenURI: NEW_BASE_TOKEN_URI });
    }

    function test_WhenCallerIsAdmin() external {
        vm.prank({ msgSender: users.admin });
        adventurer.setBaseTokenURI({ newBaseTokenURI: NEW_BASE_TOKEN_URI });
        assertEq(adventurer.baseTokenURI(), NEW_BASE_TOKEN_URI);
    }
}
