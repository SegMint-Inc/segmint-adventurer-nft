// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {
    ERC721AUpgradeable,
    ERC721ABurnableUpgradeable
} from "@erc721a-upgradeable/extensions/ERC721ABurnableUpgradeable.sol";
import { IERC721AUpgradeable } from "@erc721a-upgradeable/interfaces/IERC721AUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableRoles } from "@solady/src/auth/OwnableRoles.sol";
import { ECDSA } from "@solady/src/utils/ECDSA.sol";
import { ERC2981 } from "@solady/src/tokens/ERC2981.sol";
import { AccessRoles } from "./access/AccessRoles.sol";
import { IAdventurer } from "./interfaces/IAdventurer.sol";
import { IERC4906 } from "./interfaces/IERC4906.sol";

/**
 * @title Adventurer
 */
contract Adventurer is
    IAdventurer,
    IERC4906,
    ERC2981,
    OwnableRoles,
    ERC721ABurnableUpgradeable,
    Initializable,
    UUPSUpgradeable
{
    using ECDSA for bytes32;

    uint256 public constant TOTAL_SUPPLY = 7000;
    uint256 public constant AIRDROP_ALLOCATION = 200;
    uint256 public constant TREASURY_ALLOCATION = 550;

    string private __baseTokenURI;
    address public signer;

    /// @dev Flag indicating if the airdrop is complete.
    bool public airdropped;

    /// @dev Flag indicating if the mint is active.
    bool public mintable;

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
        address _treasury,
        string calldata _baseTokenURI
    )
        external
        initializerERC721A
        initializer
    {
        /// @dev No zero check for `_treasury` as `_mintERC2309` will revert if the `to` address is zero.
        if (_owner == address(0) || _admin == address(0) || _signer == address(0)) revert ZeroAddress();

        __ERC721A_init({ name_: "Abstract Adventurers", symbol_: "ADVNT" });
        _initializeOwner({ newOwner: _owner });
        _grantRoles({ user: _admin, roles: AccessRoles.ADMIN_ROLE });

        signer = _signer;
        __baseTokenURI = _baseTokenURI;

        uint256 batchSize = 50;
        uint256 batchCount = TREASURY_ALLOCATION / batchSize;

        /// Mint treasury allocation in batches of 50 tokens to prevent potential gas issues.
        for (uint256 i = 0; i < batchCount; i++) {
            _mint({ to: _treasury, quantity: batchSize });
        }
    }

    /**
     * @inheritdoc IAdventurer
     */
    function mint(bytes calldata signature) external {
        if (!mintable) revert MintInactive();
        if (_getAux({ owner: msg.sender }) == 1) revert AccountHasClaimed();
        _setAux({ owner: msg.sender, aux: 1 });

        bytes32 digest = keccak256(abi.encodePacked(msg.sender)).toEthSignedMessageHash();
        if (signer != digest.recover(signature)) revert SignerMismatch();

        _mint({ to: msg.sender, quantity: 1 });
    }

    /**
     * @inheritdoc IAdventurer
     */
    function airdrop(address[] calldata accounts) external onlyRoles(AccessRoles.ADMIN_ROLE) {
        if (accounts.length == 0) revert ZeroLengthArray();
        if (accounts.length != AIRDROP_ALLOCATION) revert InvalidAirdropAmount();
        if (airdropped) revert AirdropComplete();
        airdropped = true;

        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];

            /// @dev Sanity check to ensure the same `account` has not been provided more than once.
            if (_getAux({ owner: account }) == 1) revert AccountHasClaimed();
            _setAux({ owner: account, aux: 1 });

            _mint({ to: account, quantity: 1 });
        }
    }

    /**
     * @inheritdoc IAdventurer
     */
    function mintRemainder(address receiver) external onlyRoles(AccessRoles.ADMIN_ROLE) {
        uint256 remainder = TOTAL_SUPPLY - _totalMinted();
        _mint({ to: receiver, quantity: remainder });
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
        if (newSigner == address(0)) revert ZeroAddress();
        address oldSigner = signer;
        signer = newSigner;
        emit SignerUpdated(oldSigner, newSigner);
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
    function toggleMint() external onlyRoles(AccessRoles.ADMIN_ROLE) {
        bool oldFlag = mintable;
        mintable = !oldFlag;
        emit MintStateUpdated({ oldMintState: oldFlag, newMintState: mintable });
    }

    /**
     * @inheritdoc IAdventurer
     */
    function hasClaimed(address account) external view returns (bool) {
        return _getAux({ owner: account }) == 1;
    }

    /**
     * Overriden to acknowledge support for IERC4906 and IERC2981.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable, ERC2981)
        returns (bool)
    {
        return interfaceId == 0x49064906 // IERC4906
            || ERC2981.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           ERC2981                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Function used to set the default royalty information.
     * @param receiver Address to receive royalties
     * @param feeNumerator Fee numerator out of 10000
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyRoles(AccessRoles.ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * Function used to delete the default royalty information.
     */
    function deleteDefaultRoyalty() external onlyRoles(AccessRoles.ADMIN_ROLE) {
        _deleteDefaultRoyalty();
    }

    /**
     * Function used to set token specific royalty information.
     * @param tokenId Token ID to set royalty for
     * @param receiver Address to receive royalties
     * @param feeNumerator Fee numerator out of 10000
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    )
        external
        onlyRoles(AccessRoles.ADMIN_ROLE)
    {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * Function used to reset token specific royalty information.
     * @param tokenId Token ID to reset royalty for
     */
    function resetTokenRoyalty(uint256 tokenId) external onlyRoles(AccessRoles.ADMIN_ROLE) {
        _resetTokenRoyalty(tokenId);
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
