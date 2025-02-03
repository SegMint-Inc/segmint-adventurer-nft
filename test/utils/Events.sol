// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import { IAdventurer } from "../../src/interfaces/IAdventurer.sol";

abstract contract Events {
    /// { IAdventurer } Events.
    event SignerUpdated(address indexed oldSigner, address indexed newSigner);
    event BaseTokenURIUpdated(string oldBaseTokenURI, string newBaseTokenURI);
    event MintStateUpdated(bool oldMintState, bool newMintState);

    /// { IERC4906 } Events.
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}
