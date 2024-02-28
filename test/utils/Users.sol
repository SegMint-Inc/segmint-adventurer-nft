// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Vm} from "forge-std/Vm.sol";

struct Users {
    /// Admin wallet
    Vm.Wallet admin;
    /// Signer wallet
    Vm.Wallet signer;
    /// Treasury wallet
    Vm.Wallet treasury;
    /// Standard wallet
    Vm.Wallet alice;
    /// Standard wallet
    Vm.Wallet bob;
    /// Malicious user
    Vm.Wallet eve;
}
