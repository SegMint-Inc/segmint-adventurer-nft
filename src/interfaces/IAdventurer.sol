// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title IAdventurer
 * @notice Interface for Adventurer.
 */
interface IAdventurer {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           ERRORS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Thrown when the zero address is provided as input.
     */
    error ZeroAddress();

    /**
     * Thrown when the recovered signer doesn't match the set signer.
     */
    error SignerMismatch();

    /**
     * Thrown when an address has already claimed an adventurer.
     */
    error AccountHasClaimed();

    /**
     * Thrown when an input array has zero length.
     */
    error ZeroLengthArray();

    /**
     * Thrown when the amount of tokens to airdrop does not match the allocation amount.
     */
    error InvalidAirdropAmount();

    /**
     * Thrown when the airdrop is already complete.
     */
    error AirdropComplete();

    /**
     * Thrown when the mint is not active.
     */
    error MintInactive();

    /**
     * Thrown when the mint exceeds the total supply.
     */
    error MintExceedsTotalSupply();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Emitted when the signer address is updated.
     * @param oldSigner Old signer address.
     * @param newSigner New signer address.
     */
    event SignerUpdated(address indexed oldSigner, address indexed newSigner);

    /**
     * Emitted when the base token URI is updated.
     * @param oldBaseTokenURI Old base token URI value.
     * @param newBaseTokenURI New base token URI value.
     */
    event BaseTokenURIUpdated(string oldBaseTokenURI, string newBaseTokenURI);

    /**
     * Emitted when the mint state is updated.
     * @param oldMintState Old mint state value.
     * @param newMintState New mint state value.
     */
    event MintStateUpdated(bool oldMintState, bool newMintState);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         FUNCTIONS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Function used to initialize storage of the proxy contract.
     * @param _owner Owner address.
     * @param _admin Admin address.
     * @param _signer Signer address.
     * @param _treasury Treasury address.
     * @param _baseTokenURI Starting base token URI.
     */
    function initialize(
        address _owner,
        address _admin,
        address _signer,
        address _treasury,
        string calldata _baseTokenURI
    )
        external;

    /**
     * Function used to mint during the mint phase.
     * @param signature Signed message digest.
     */
    function mint(bytes calldata signature) external;

    /**
     * Function used to airdrop adventurers to a list of accounts, this function is only callable once
     * and will be called after deployment prior to the mint phase.
     * @param accounts List of accounts to airdrop to.
     */
    function airdrop(address[] calldata accounts) external;

    /**
     * Function used to mint the remainder of the supply to the treasury.
     * @param receiver Address to mint to.
     * @param quantity Quantity of tokens to mint.
     */
    function adminMint(address receiver, uint256 quantity) external;

    /**
     * Function used to emit an ERC4906 event to update the metadata for all existing tokens.
     */
    function updateMetadata() external;

    /**
     * Function used to update the signer address.
     * @param newSigner New signer address.
     */
    function setSigner(address newSigner) external;

    /**
     * Function used to set a new base token URI.
     * @param newBaseTokenURI New base token URI value.
     */
    function setBaseTokenURI(string calldata newBaseTokenURI) external;

    /**
     * Function used to toggle the mint state.
     */
    function toggleMint() external;

    /**
     * Function used to view if an account has claimed an adventurer.
     * @param account Account to check.
     */
    function hasClaimed(address account) external view returns (bool);
}
