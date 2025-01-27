// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Vm } from "forge-std/Vm.sol";

struct Users {
    /// Owner
    address payable owner;
    /// Admin
    address payable admin;
    /// Treasury
    address payable treasury;
    /// Standard User
    address payable alice;
    /// Standard User
    address payable bob;
    /// Malicious User
    address payable eve;
    /// Signer
    Vm.Wallet signer;
}
