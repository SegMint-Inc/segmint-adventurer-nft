// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IAccessRegistry } from "./IAccessRegistry.sol";
import { Characters } from "../types/DataTypes.sol";

interface IAdventurer {
    /**
     * Thrown when the zero address is provided as input.
     */
    error ZeroAddressInvalid();

    /**
     * Thrown when the recovered signer doesn't match the set signer.
     */
    error SignerMismatch();

    /**
     * Thrown when the current claim state doesn't match the intended claim state.
     */
    error InvalidClaimState();

    /**
     * Thrown when a profile identifier has already claimed an adventurer.
     */
    error ProfileHasClaimed();

    /**
     * Thrown when an undefined character type is provided.
     */
    error UndefinedCharacterType();

    /**
     * Thrown when a character supply is exhuasted.
     */
    error CharacterSupplyExhausted();

    /**
     * Thrown when an adventurer is already transformed.
     */
    error AlreadyTransformed();

    /**
     * Thrown when the caller is not the owner of the token.
     */
    error CallerNotOwner();

    /**
     * Thrown when the token identifier does not exist.
     */
    error NonExistentTokenId();

    /**
     * Thrown when two input arrays differ in length.
     */
    error ArrayLengthMismatch();

    /**
     * Thrown when an input array has zero length.
     */
    error ZeroLengthArray();

    /**
     * Emitted when an adventurer is claimed.
     * @param account Account that claimed the adventurer.
     * @param profileId SegMint profile identifier.
     * @param character Type of adventurer that was claimed.
     */
    event AdventurerClaimed(address indexed account, bytes32 indexed profileId, Characters character);

    /**
     * Emitted when an adventurer is transformed.
     * @param account Account that transformed the adventurer.
     * @param burntTokenId Unique token identifier that was transformed.
     * @param transformedId Transformed token identifier.
     */
    event AdventurerTransformed(address indexed account, uint256 burntTokenId, uint256 transformedId);

    /**
     * Emitted when the signer address is updated.
     * @param oldSigner Old signer address.
     * @param newSigner New signer address.
     */
    event SignerUpdated(address indexed oldSigner, address indexed newSigner);

    /**
     * Emitted when the Access Registry is updated.
     * @param oldAccessRegistry Old Access Registry address.
     * @param newAccessRegistry New Access Registry address.
     */
    event AccessRegistryUpdated(IAccessRegistry indexed oldAccessRegistry, IAccessRegistry indexed newAccessRegistry);

    /**
     * Emitted when the base token URI is updated.
     * @param oldBaseTokenURI Old base token URI value.
     * @param newBaseTokenURI New base token URI value.
     */
    event BaseTokenURIUpdated(string oldBaseTokenURI, string newBaseTokenURI);

    /**
     * Emitted when the supply for a character is updated.
     * @param character Adventurer character type.
     * @param amount Amount added to the supply.
     */
    event CharacterSupplyUpdated(Characters indexed character, uint256 amount);

    /**
     * Function used to initialize storage of the proxy contract.
     * @param _owner Owner address.
     * @param _admin Admin address.
     * @param _signer Signer address.
     * @param _accessRegistry Access Registry address.
     * @param _baseTokenURI Starting base token URI.
     */
    function initialize(
        address _owner,
        address _admin,
        address _signer,
        address _accessRegistry,
        string memory _baseTokenURI
    ) external;

    /**
     * Function used to update the signer address.
     * @param newSigner New signer address.
     */
    function setSigner(address newSigner) external;

    /**
     * Function used to update the Access Registry address.
     * @param newAccessRegistry New Access Registry address.
     */
    function setAccessRegistry(IAccessRegistry newAccessRegistry) external;

    enum ClaimState {
        CLOSED,
        ACTIVE
    }
}