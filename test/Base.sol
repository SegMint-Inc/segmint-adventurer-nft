// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import "forge-std/Test.sol";

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IAccessRegistry } from "../src/interfaces/IAccessRegistry.sol";
import { IAdventurer } from "../src/interfaces/IAdventurer.sol";
import { Adventurer } from "../src/Adventurer.sol";
import { Characters } from "../src/types/DataTypes.sol";

abstract contract Base is Script, Test {
    /// Core contracts.
    Adventurer public adventurer;

    /// Storage slot where implementation address is stored for ERC1967 proxies.
    bytes32 public implementationSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// State variables required for deployment, these must be defined before setup in the inheriting contract.
    address public owner;
    address public admin;
    address public signer;
    string public baseTokenURI;
    IAccessRegistry public accessRegistry;

    function coreSetup() public {
        adventurer = new Adventurer();
        ERC1967Proxy adventurerProxy = new ERC1967Proxy({
            implementation: address(adventurer),
            _data: abi.encodeWithSelector(
                IAdventurer.initialize.selector,
                owner,
                admin,
                signer,
                accessRegistry,
                baseTokenURI
            )
        });

        /// Route all future calls to `adventurer` via the proxy.
        adventurer = Adventurer(address(adventurerProxy));
    }
}
