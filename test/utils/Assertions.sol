// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {Characters} from "../../src/types/DataTypes.sol";
import {IAccessRegistry} from "../../src/interfaces/IAccessRegistry.sol";
import {IAdventurer} from "../../src/interfaces/IAdventurer.sol";

abstract contract Assertions is Test {
    /// Asserts two {IAccessRegistry} values match.
    function assertEq(IAccessRegistry a, IAccessRegistry b) internal {
        assertEq(address(a), address(b));
    }

    /// Asserts two {IAccessRegistry.AccessType} values match.
    function assertEq(IAccessRegistry.AccessType a, IAccessRegistry.AccessType b) internal {
        assertEq(uint256(a), uint256(b));
    }

    /// Asserts two {Characters} enum values match.
    function assertEq(Characters a, Characters b) internal {
        assertEq(uint256(a), uint256(b));
    }

    /// Asserts two {IAdventurer.ClaimState} enum values match.
    function assertEq(IAdventurer.ClaimState a, IAdventurer.ClaimState b) internal {
        assertEq(uint256(a), uint256(b));
    }
}
