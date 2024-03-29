// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { OwnableRoles } from "@solady/src/auth/OwnableRoles.sol";
import { ECDSA } from "@solady/src/utils/ECDSA.sol";
import { ERC721ABurnableUpgradeable } from "@erc721a-upgradeable/extensions/ERC721ABurnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { AccessRoles } from "./access/AccessRoles.sol";
import { IAccessRegistry } from "./interfaces/IAccessRegistry.sol";
import { IAdventurer } from "./interfaces/IAdventurer.sol";
import { Characters } from "./types/DataTypes.sol";

contract Adventurer is IAdventurer, OwnableRoles, ERC721ABurnableUpgradeable, Initializable, UUPSUpgradeable {
    using ECDSA for bytes32;

    string private __baseTokenURI;

    IAccessRegistry public accessRegistry;
    address public signer;
    ClaimState public claimState;

    /**
     * Maps a profile identifier to whether it has claimed or not.
     */
    mapping(bytes32 profileId => bool hasClaimed) public profileClaimed;

    /**
     * Maps a character type to the remaining supply.
     */
    mapping(Characters character => uint256 remainingSupply) public charactersLeft;

    /**
     * Maps a token identifier to the respective character type.
     */
    mapping(uint256 tokenId => Characters character) public characterType;

    /**
     * Modifier used to check the claim state.
     */
    modifier checkClaimState(ClaimState desiredState) {
        _checkClaimState(desiredState);
        _;
    }

    /**
     * Disable initializers so that storage of the implementation contract cannot be modified.
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * Function used to initialize storage of the proxy contract.
     * @param _owner Owner address.
     * @param _admin Admin address.
     * @param _signer Signer address.
     * @param _accessRegistry Access Registry address.
     */
    function initialize(
        address _owner,
        address _admin,
        address _signer,
        address _accessRegistry,
        string memory _baseTokenURI
    ) initializerERC721A initializer external {
        if (
            _owner == address(0) ||
            _admin == address(0) ||
            _signer == address(0) ||
            _accessRegistry == address(0)
        ) revert ZeroAddressInvalid();

        __baseTokenURI = _baseTokenURI;

        __ERC721A_init({ name_: "Adventurer", symbol_: "ADVNT" });
        _initializeOwner({ newOwner: _owner });
        _grantRoles({ user: _admin, roles: AccessRoles.ADMIN_ROLE });
    }

    /**
     * Function used to claim an adventurer.
     * @param profileId SegMint profile identifier.
     * @param character Adventurer character type being claimed.
     * @param signature Signed message digest.
     */
    function claimAdventurer(
        bytes32 profileId,
        Characters character,
        bytes calldata signature
    ) external checkClaimState(ClaimState.ACTIVE) {
        if (profileClaimed[profileId]) revert ProfileHasClaimed();
        if (character == Characters.UNDEFINED) revert UndefinedCharacterType();
        if (charactersLeft[character]-- == 0) revert CharacterSupplyExhausted();

        bytes32 digest = keccak256(abi.encodePacked(msg.sender, profileId, character));
        if (signer != digest.recover(signature)) revert SignerMismatch();

        profileClaimed[profileId] = true;
        characterType[_nextTokenId()] = character;

        _mint({ to: msg.sender, quantity: 1 });

        emit AdventurerClaimed({ account: msg.sender, profileId: profileId, character: character });
    }

    /**
     * Function used to transform an adventurer into Keydara.
     * @param tokenId Adventurer token identifier.
     * @param signature Signed message digest.
     */
    function transformAdventurer(
        uint256 tokenId,
        bytes calldata signature
    ) external checkClaimState(ClaimState.ACTIVE) {
        if (!_exists(tokenId)) revert NonExistentTokenId();
        if (msg.sender != ownerOf(tokenId)) revert CallerNotOwner();

        bytes32 digest = keccak256(abi.encodePacked(msg.sender, tokenId));
        if (signer != digest.recover(signature)) revert SignerMismatch();

        // Reset the state for the provided adventurer token.
        characterType[tokenId] = Characters.UNDEFINED;
        _burn({ tokenId: tokenId, approvalCheck: false });

        characterType[_nextTokenId()] = Characters.KEYDARA;
        _mint({ to: msg.sender, quantity: 1 });

        emit AdventurerTransformed({ account: msg.sender, tokenId: tokenId });
    }

    /**
     * Function used to add `amount` to the supply of a character.
     * @param characters Array of adventurer character types.
     * @param amounts Array of supply amounts to add.
     */
    function addCharacterSupply(
        Characters[] calldata characters,
        uint256[] calldata amounts
    ) external onlyRoles(AccessRoles.ADMIN_ROLE) {
        if (characters.length != amounts.length) revert ArrayLengthMismatch();
        if (characters.length == 0) revert ZeroLengthArray();

        for (uint256 i = 0; i < characters.length; i++) {
            _addCharacters(characters[i], amounts[i]);
        }
    }

    /**
     * @inheritdoc IAdventurer
     */
    function setSigner(address newSigner) external onlyRoles(AccessRoles.ADMIN_ROLE) {
        if (newSigner == address(0)) revert ZeroAddressInvalid();

        address oldSigner = signer;
        signer = newSigner;

        emit SignerUpdated(oldSigner, newSigner);
    }

    /**
     * @inheritdoc IAdventurer
     */
    function setAccessRegistry(IAccessRegistry newAccessRegistry) external onlyRoles(AccessRoles.ADMIN_ROLE) {
        if (address(newAccessRegistry) == address(0)) revert ZeroAddressInvalid();

        IAccessRegistry oldAccessRegistry = accessRegistry;
        accessRegistry = newAccessRegistry;

        emit AccessRegistryUpdated(oldAccessRegistry, newAccessRegistry);
    }

    /**
     * Function used to set a new base token URI.
     * @param newBaseTokenURI New base token URI value.
     */
    function setBaseTokenURI(string calldata newBaseTokenURI) external onlyRoles(AccessRoles.ADMIN_ROLE) {
        string memory oldBaseTokenURI = __baseTokenURI;
        __baseTokenURI = newBaseTokenURI;

        emit BaseTokenURIUpdated(oldBaseTokenURI, newBaseTokenURI);
    }

    function _addCharacters(Characters character, uint256 amount) internal {
        if (character == Characters.UNDEFINED) revert UndefinedCharacterType();
        charactersLeft[character] += amount;
        emit CharacterSupplyUpdated(character, amount);
    }

    function _checkClaimState(ClaimState desiredState) internal view {
        if (desiredState != claimState) revert InvalidClaimState();
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseTokenURI;
    }

    function _authorizeUpgrade(address) internal override onlyRoles(AccessRoles.ADMIN_ROLE) { }

}
