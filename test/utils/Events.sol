// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Characters } from "../../src/types/DataTypes.sol";
import { IAccessRegistry } from "../../src/interfaces/IAccessRegistry.sol";

abstract contract Events {
    /// { IAdventurer } Events.
    event AdventurerClaimed(address indexed account, bytes32 indexed profileId, Characters character);
    event AdventurerTransformed(address indexed account, uint256 burntTokenId, uint256 transformedId);
    event SignerUpdated(address indexed oldSigner, address indexed newSigner);
    event AccessRegistryUpdated(IAccessRegistry indexed oldAccessRegistry, IAccessRegistry indexed newAccessRegistry);
    event BaseTokenURIUpdated(string oldBaseTokenURI, string newBaseTokenURI);
    event CharacterSupplyUpdated(Characters indexed character, uint256 amount);
}