// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "../../BaseTest.sol";

contract InitializeFuzzTest is BaseTest {
    Adventurer internal nonInitializedAdventurer;

    function testFuzz_RevertWhen_TheContractIsAlreadyInitialized(uint256) external {
        vm.expectRevert("ERC721A__Initializable: contract is already initialized");
        adventurer.initialize({
            _owner: owner,
            _admin: admin,
            _signer: signer,
            _treasury: treasury,
            _baseTokenURI: baseTokenURI
        });
    }

    modifier whenTheContractIsNotInitialized() {
        bytes32 implementation = vm.load({ target: address(adventurer), slot: implementationSlot });
        ERC1967Proxy proxy = new ERC1967Proxy({ implementation: address(uint160(uint256(implementation))), _data: "" });

        nonInitializedAdventurer = Adventurer(address(proxy));
        _;
    }

    function testFuzz_RevertWhen_TheOwnerIsTheZeroAddress(uint256) external whenTheContractIsNotInitialized {
        vm.expectRevert(IAdventurer.ZeroAddress.selector);
        nonInitializedAdventurer.initialize({
            _owner: address(0),
            _admin: admin,
            _signer: signer,
            _treasury: treasury,
            _baseTokenURI: baseTokenURI
        });
    }

    modifier whenTheOwnerIsNotTheZeroAddress() {
        owner = users.owner;
        _;
    }

    function testFuzz_RevertWhen_TheAdminIsTheZeroAddress(uint256)
        external
        whenTheContractIsNotInitialized
        whenTheOwnerIsNotTheZeroAddress
    {
        vm.expectRevert(IAdventurer.ZeroAddress.selector);
        nonInitializedAdventurer.initialize({
            _owner: owner,
            _admin: address(0),
            _signer: signer,
            _treasury: treasury,
            _baseTokenURI: baseTokenURI
        });
    }

    modifier whenTheAdminIsNotTheZeroAddress() {
        admin = users.admin;
        _;
    }

    function testFuzz_RevertWhen_TheSignerIsTheZeroAddress(uint256)
        external
        whenTheContractIsNotInitialized
        whenTheOwnerIsNotTheZeroAddress
        whenTheAdminIsNotTheZeroAddress
    {
        vm.expectRevert(IAdventurer.ZeroAddress.selector);
        nonInitializedAdventurer.initialize({
            _owner: owner,
            _admin: admin,
            _signer: address(0),
            _treasury: treasury,
            _baseTokenURI: baseTokenURI
        });
    }

    function testFuzz_WhenTheSignerIsNotTheZeroAddress(
        address newOwner,
        address newAdmin,
        address newSigner,
        address newTreasury,
        string calldata newBaseTokenURI
    )
        external
        whenTheContractIsNotInitialized
        whenTheOwnerIsNotTheZeroAddress
        whenTheAdminIsNotTheZeroAddress
    {
        vm.assume(
            newOwner != address(0) && newAdmin != address(0) && newSigner != address(0) && newTreasury != address(0)
        );
        vm.assume(bytes(newBaseTokenURI).length < 32);

        nonInitializedAdventurer.initialize({
            _owner: newOwner,
            _admin: newAdmin,
            _signer: newSigner,
            _treasury: newTreasury,
            _baseTokenURI: newBaseTokenURI
        });

        assertEq(nonInitializedAdventurer.name(), "Abstract Adventurers");
        assertEq(nonInitializedAdventurer.symbol(), "ADVNT");
        assertEq(nonInitializedAdventurer.owner(), newOwner);
        assertTrue(nonInitializedAdventurer.hasAllRoles({ user: newAdmin, roles: AccessRoles.ADMIN_ROLE }));
        assertEq(nonInitializedAdventurer.signer(), newSigner);
        assertEq(nonInitializedAdventurer.baseTokenURI(), newBaseTokenURI);
        uint256 treasuryAllocation = nonInitializedAdventurer.TREASURY_ALLOCATION();
        assertEq(nonInitializedAdventurer.balanceOf({ owner: newTreasury }), treasuryAllocation);
        assertEq(nonInitializedAdventurer.totalSupply(), treasuryAllocation);
    }
}
