// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./Base.sol";

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Ownable } from "@solady/src/auth/Ownable.sol";
import { ECDSA } from "@solady/src/utils/ECDSA.sol";
import { Constants } from "./utils/Constants.sol";
import { Assertions } from "./utils/Assertions.sol";
import { Events } from "./utils/Events.sol";
import { Users } from "./utils/Users.sol";

import { AccessRoles } from "../src/access/AccessRoles.sol";

abstract contract BaseTest is Base, Constants, Assertions, Events {
    using ECDSA for bytes32;

    Users public users;

    function setUp() public virtual {
        _setUpBefore();
        coreSetup();
        _setUpAfter();
    }

    function _setUpBefore() internal {
        createUsers();

        owner = users.owner;
        admin = users.admin;
        signer = users.signer.addr;
        treasury = users.treasury;
        baseTokenURI = "https://www.segmint.io/api/adventurers/";
    }

    function _setUpAfter() internal {
        vm.label({ account: address(adventurer), newLabel: "Adventurer Proxy" });

        bytes32 implementation = vm.load({ target: address(adventurer), slot: implementationSlot });
        vm.label({ account: address(uint160(uint256(implementation))), newLabel: "Adventurer Implementation" });
    }

    /**
     * Helper function used to create users.
     */
    function createUsers() internal {
        users.owner = createUser({ name: "Owner" });
        users.admin = createUser({ name: "Admin" });
        users.treasury = createUser({ name: "Treasury" });
        users.alice = createUser({ name: "Alice" });
        users.bob = createUser({ name: "Bob" });
        users.eve = createUser({ name: "Eve" });
        users.signer = vm.createWallet({ walletLabel: "Signer" });
    }

    /**
     * Helper function used to create a user.
     */
    function createUser(string memory name) internal returns (address payable) {
        address user = vm.createWallet({ walletLabel: name }).addr;
        vm.label({ account: user, newLabel: name });
        vm.deal({ account: user, newBalance: DEFAULT_ETH_BALANCE });
        assertEq(user.balance, DEFAULT_ETH_BALANCE);
        return payable(user);
    }

    /**
     * Helper function used to get a mint signature.
     */
    function getMintSignature(address account) public view returns (bytes memory) {
        bytes32 digest = keccak256(abi.encodePacked(account)).toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign({ privateKey: users.signer.privateKey, digest: digest });
        return abi.encodePacked(r, s, v);
    }
}
