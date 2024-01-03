// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { OwnableRoles } from "@solady/src/auth/OwnableRoles.sol";
import { ECDSA } from "@solady/src/utils/ECDSA.sol";
import { ERC721AUpgradeable, ERC721ABurnableUpgradeable } from "@erc721a-upgradeable/extensions/ERC721ABurnableUpgradeable.sol";
import { IERC721AUpgradeable } from "@erc721a-upgradeable/interfaces/IERC721AUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { AccessRoles } from "./access/AccessRoles.sol";
import { IAccessRegistry } from "./interfaces/IAccessRegistry.sol";
import { IAdventurer } from "./interfaces/IAdventurer.sol";
import { IERC4906 } from "./interfaces/IERC4906.sol";
import { Characters } from "./types/DataTypes.sol";

/**
 * @title Adventurer
 */
contract Adventurer is IAdventurer, IERC4906, OwnableRoles, ERC721ABurnableUpgradeable, Initializable, UUPSUpgradeable {
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
     * @inheritdoc IAdventurer
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

        __ERC721A_init({ name_: "Adventurer", symbol_: "ADVNT" });

        _initializeOwner({ newOwner: _owner });
        _grantRoles({ user: _admin, roles: AccessRoles.ADMIN_ROLE });
        signer = _signer;
        accessRegistry = IAccessRegistry(_accessRegistry);
        __baseTokenURI = _baseTokenURI;
    }

    /**
     * @inheritdoc IAdventurer
     */
    function claimAdventurer(
        bytes32 profileId,
        Characters character,
        bytes calldata signature
    ) external checkClaimState(ClaimState.ACTIVE) {
        IAccessRegistry.AccessType accountAccessType = accessRegistry.accessType({ account: msg.sender });
        if (accountAccessType == IAccessRegistry.AccessType.BLOCKED) revert InvalidAccessType();

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
     * @inheritdoc IAdventurer
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

        uint256 newTokenId = _nextTokenId();
        characterType[newTokenId] = Characters.KEYDARA;
        _mint({ to: msg.sender, quantity: 1 });

        emit AdventurerTransformed({ account: msg.sender, burntTokenId: tokenId, transformedId: newTokenId });
    }

    /**
     * @inheritdoc IAdventurer
     */
    function claimAdventurers(Characters character, address receiver) external onlyRoles(AccessRoles.ADMIN_ROLE) {
        if (character == Characters.UNDEFINED) revert UndefinedCharacterType();
        if (receiver == address(0)) revert ZeroAddressInvalid();

        uint256 remainingSupply = charactersLeft[character];
        uint256 startTokenId = _nextTokenId();

        for (uint256 i = 0; i < remainingSupply; i++) {
            characterType[i+startTokenId] = character;
        }

        _mint({ to: receiver, quantity: remainingSupply });
    }

    /**
     * @inheritdoc IAdventurer
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
    function updateMetadata() external onlyRoles(AccessRoles.ADMIN_ROLE) {
        emit BatchMetadataUpdate({ _fromTokenId: _startTokenId(), _toTokenId: _totalMinted() });
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
     * @inheritdoc IAdventurer
     */
    function setBaseTokenURI(string calldata newBaseTokenURI) external onlyRoles(AccessRoles.ADMIN_ROLE) {
        string memory oldBaseTokenURI = __baseTokenURI;
        __baseTokenURI = newBaseTokenURI;

        emit BaseTokenURIUpdated(oldBaseTokenURI, newBaseTokenURI);
    }

    /**
     * @inheritdoc IAdventurer
     */
    function toggleClaimState() external onlyRoles(AccessRoles.ADMIN_ROLE) {
        ClaimState oldClaimState = claimState;
        claimState = claimState == ClaimState.CLOSED ? ClaimState.ACTIVE : ClaimState.CLOSED;
        emit ClaimStateUpdated({ oldClaimState: oldClaimState, newClaimState: claimState });
    }

    /**
     * Overriden to acknowledge support for IERC4906.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721AUpgradeable, IERC721AUpgradeable) returns (bool) {
        return
            interfaceId == 0x49064906 ||  // IERC4906
            super.supportsInterface(interfaceId);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       INTERNAL LOGIC                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _addCharacters(Characters character, uint256 amount) internal {
        if (character == Characters.UNDEFINED) revert UndefinedCharacterType();
        charactersLeft[character] += amount;
        emit CharacterSupplyUpdated(character, amount);
    }

    function _checkClaimState(ClaimState desiredState) internal view {
        if (desiredState != claimState) revert InvalidClaimState();
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     ERC721A OVERRIDES                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseTokenURI;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       UUPSUPGRADEABLE                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _authorizeUpgrade(address) internal override onlyRoles(AccessRoles.ADMIN_ROLE) { }

}
