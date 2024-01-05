// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./Base.sol";

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { ECDSA } from "@solady/src/utils/ECDSA.sol";

import { Assertions } from "./utils/Assertions.sol";
import { Errors } from "./utils/Errors.sol";
import { Events } from "./utils/Events.sol";
import { Users } from "./utils/Users.sol";

import { Characters } from "../src/types/DataTypes.sol";

abstract contract BaseTest is Base, Assertions, Errors, Events {
    using stdStorage for StdStorage;

    Users public users;

    function setUp() public virtual {
        _setUpBefore();
        coreSetup();
        _setUpAfter();
    }

    function _setUpBefore() internal {
        /// Create user wallets to be used in testing.
        _createUsers();

        /// Assign state variables.
        owner = address(this);
        admin = users.admin.addr;
        signer = users.signer.addr;
        baseTokenURI = "https://www.segmint.io/api/adventurers/";

        string memory root = vm.projectRoot();
        string memory basePath = string.concat(root, "/test/utils/");
        string memory path = string.concat(basePath, "accessRegistry.json");
        string memory jsonFile = vm.readFile(path);

        /// Etch Access Registry code into specified address.
        accessRegistry = abi.decode(vm.parseJson({ json: jsonFile, key: ".address" }), (IAccessRegistry));
        bytes memory registryCode = abi.decode(vm.parseJson({ json: jsonFile, key: ".code" }), (bytes));
        vm.etch({ target: address(accessRegistry), newRuntimeBytecode: registryCode });

        /// Grant access to Alice and Bob.
        _grantAccess();
    }

    function _setUpAfter() internal {
        vm.label({ account: address(adventurer), newLabel: "Adventurer Proxy" });

        bytes32 implementation = vm.load({ target: address(adventurer), slot: implementationSlot });
        vm.label({ account: address(uint160(uint256(implementation))), newLabel: "Adventurer Implementation" });
    }

    /**
     * Helper function used to create users for testing purposes.
     */
    function _createUsers() internal {
        users.admin = vm.createWallet({ walletLabel: "test.admin" });
        vm.label({ account: users.admin.addr, newLabel: "Admin" });

        users.signer = vm.createWallet({ walletLabel: "test.signer" });
        vm.label({ account: users.signer.addr, newLabel: "Signer" });

        users.alice = vm.createWallet({ walletLabel: "test.alice" });
        vm.label({ account: users.alice.addr, newLabel: "Alice (Standard User)" });

        users.bob = vm.createWallet({ walletLabel: "test.bob" });
        vm.label({ account: users.bob.addr, newLabel: "Bob (Standard User)" });

        users.eve = vm.createWallet({ walletLabel: "test.eve" });
        vm.label({ account: users.eve.addr, newLabel: "Eve (Malicious User)" });
    }

    /**
     * Helper function used to set access types for Alice and Bob.
     */
    function _grantAccess() internal {
        stdstore
            .target(address(accessRegistry))
            .sig(IAccessRegistry.accessType.selector)
            .with_key(users.alice.addr)
            .checked_write(uint256(IAccessRegistry.AccessType.RESTRICTED));

        stdstore
            .target(address(accessRegistry))
            .sig(IAccessRegistry.accessType.selector)
            .with_key(users.bob.addr)
            .checked_write(uint256(IAccessRegistry.AccessType.UNRESTRICTED));
    }

}
