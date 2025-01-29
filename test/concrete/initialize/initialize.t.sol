// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../../BaseTest.sol";

contract InitializeConcreteTest is BaseTest {
    Adventurer internal nonInitializedAdventurer;

    function test_RevertWhen_TheContractIsAlreadyInitialized() external {
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

    function test_RevertWhen_TheOwnerIsTheZeroAddress() external whenTheContractIsNotInitialized {
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

    function test_RevertWhen_TheAdminIsTheZeroAddress()
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

    function test_RevertWhen_TheSignerIsTheZeroAddress()
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

    function test_WhenTheSignerIsNotTheZeroAddress()
        external
        whenTheContractIsNotInitialized
        whenTheOwnerIsNotTheZeroAddress
        whenTheAdminIsNotTheZeroAddress
    {
        nonInitializedAdventurer.initialize({
            _owner: owner,
            _admin: admin,
            _signer: users.signer.addr,
            _treasury: treasury,
            _baseTokenURI: baseTokenURI
        });

        assertEq(nonInitializedAdventurer.name(), "Abstract Adventurers");
        assertEq(nonInitializedAdventurer.symbol(), "ADVNT");
        assertEq(nonInitializedAdventurer.owner(), users.owner);
        assertTrue(nonInitializedAdventurer.hasAllRoles({ user: users.admin, roles: AccessRoles.ADMIN_ROLE }));
        assertEq(nonInitializedAdventurer.signer(), users.signer.addr);
        assertEq(nonInitializedAdventurer.baseTokenURI(), baseTokenURI);
        uint256 treasuryAllocation = nonInitializedAdventurer.TREASURY_ALLOCATION();
        assertEq(nonInitializedAdventurer.balanceOf({ owner: users.treasury }), treasuryAllocation);
        assertEq(nonInitializedAdventurer.totalSupply(), treasuryAllocation);
        assertTrue(nonInitializedAdventurer.supportsInterface({ interfaceId: 0x49064906 }));
        assertTrue(nonInitializedAdventurer.supportsInterface({ interfaceId: 0x2a55205a }));
        assertTrue(nonInitializedAdventurer.supportsInterface({ interfaceId: 0x80ac58cd }));
    }
}
