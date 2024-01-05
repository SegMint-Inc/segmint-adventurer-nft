// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./BaseTest.sol";

contract AdventurerTest is BaseTest {
    using ECDSA for bytes32;

    modifier initializeClaim() {
        _initializeClaim();
        _;
    }

    function setUp() public override {
        super.setUp();
    }

    /**
     * Ensures the test environment was initialized correctly.
     */
    function test_Deployment() public {
        /// Contract initialization.
        assertEq(adventurer.name(), "Adventurer");
        assertEq(adventurer.symbol(), "ADVNT");
        assertEq(adventurer.owner(), address(this));
        assertEq(adventurer.signer(), users.signer.addr);
        assertEq(adventurer.accessRegistry(), accessRegistry);
        assertTrue(adventurer.hasAllRoles({ user: users.admin.addr, roles: AccessRoles.ADMIN_ROLE }));

        /// AccessRegistry access types.
        assertEq(accessRegistry.accessType({ account: users.alice.addr }), IAccessRegistry.AccessType.RESTRICTED);
        assertEq(accessRegistry.accessType({ account: users.bob.addr }), IAccessRegistry.AccessType.UNRESTRICTED);
    }

    /* `initialize()` Tests */

    function test_Initialize_Fuzzed(address _owner, address _admin, address _signer, address _accessRegistry) public {
        vm.assume(_owner != address(0) && _admin != address(0) && _signer != address(0) && _accessRegistry != address(0));

        bytes32 implementation = vm.load({ target: address(adventurer), slot: implementationSlot });
        ERC1967Proxy proxy = new ERC1967Proxy({
            implementation: address(uint160(uint256(implementation))),
            _data: abi.encodeWithSelector(
                IAdventurer.initialize.selector,
                _owner,
                _admin,
                _signer,
                _accessRegistry,
                ""
            )
        });

        Adventurer newAdventurer = Adventurer(address(proxy));

        assertEq(newAdventurer.name(), "Adventurer");
        assertEq(newAdventurer.symbol(), "ADVNT");
        assertEq(newAdventurer.owner(), _owner);
        assertEq(newAdventurer.signer(), _signer);
        assertEq(address(newAdventurer.accessRegistry()), _accessRegistry);
        assertTrue(newAdventurer.hasAllRoles({ user: _admin, roles: AccessRoles.ADMIN_ROLE }));
    }

    function testCannot_Initialize_Implementation() public {
        bytes32 implementation = vm.load({ target: address(adventurer), slot: implementationSlot });
        Adventurer baseImplementation = Adventurer(address(uint160(uint256(implementation))));

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        baseImplementation.initialize({
            _owner: address(this),
            _admin: users.admin.addr,
            _signer: users.signer.addr,
            _accessRegistry: address(accessRegistry),
            _baseTokenURI: ""
        });
    }

    function testCannot_Initialize_Proxy() public {
        vm.expectRevert("ERC721A__Initializable: contract is already initialized");
        adventurer.initialize({
            _owner: address(this),
            _admin: users.admin.addr,
            _signer: users.signer.addr,
            _accessRegistry: address(accessRegistry),
            _baseTokenURI: ""
        });
    }

    function testCannot_Initialize_ZeroAddressInvalid_Owner() public {
        bytes32 implementation = vm.load({ target: address(adventurer), slot: implementationSlot });

        vm.expectRevert(IAdventurer.ZeroAddressInvalid.selector);
        new ERC1967Proxy({
            implementation: address(uint160(uint256(implementation))),
            _data: abi.encodeWithSelector(
                IAdventurer.initialize.selector,
                address(0),
                users.admin.addr,
                users.signer.addr,
                accessRegistry,
                ""
            )
        });
    }

    function testCannot_Initialize_ZeroAddressInvalid_Admin() public {
        bytes32 implementation = vm.load({ target: address(adventurer), slot: implementationSlot });

        vm.expectRevert(IAdventurer.ZeroAddressInvalid.selector);
        new ERC1967Proxy({
            implementation: address(uint160(uint256(implementation))),
            _data: abi.encodeWithSelector(
                IAdventurer.initialize.selector,
                address(this),
                address(0),
                users.signer.addr,
                accessRegistry,
                ""
            )
        });
    }

    function testCannot_Initialize_ZeroAddressInvalid_Signer() public {
        bytes32 implementation = vm.load({ target: address(adventurer), slot: implementationSlot });

        vm.expectRevert(IAdventurer.ZeroAddressInvalid.selector);
        new ERC1967Proxy({
            implementation: address(uint160(uint256(implementation))),
            _data: abi.encodeWithSelector(
                IAdventurer.initialize.selector,
                address(this),
                users.admin.addr,
                address(0),
                accessRegistry,
                ""
            )
        });
    }

    function testCannot_Initialize_ZeroAddressInvalid_AccessRegistry() public {
        bytes32 implementation = vm.load({ target: address(adventurer), slot: implementationSlot });

        vm.expectRevert(IAdventurer.ZeroAddressInvalid.selector);
        new ERC1967Proxy({
            implementation: address(uint160(uint256(implementation))),
            _data: abi.encodeWithSelector(
                IAdventurer.initialize.selector,
                address(this),
                users.admin.addr,
                users.signer.addr,
                address(0),
                ""
            )
        });
    }

    /* `claimAdventurer()` Tests */

    function test_ClaimAdventurer_Fuzzed(bytes32 profileId, uint256 characterId) public initializeClaim {
        characterId = bound(characterId, 1, 13);

        Characters character = Characters(characterId);
        bytes memory signature = getClaimSignature(users.alice.addr, profileId, character);

        uint256 oldCharacterSupply = adventurer.charactersLeft(character);

        hoax(users.alice.addr);
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit AdventurerClaimed({ account: users.alice.addr, profileId: profileId, character: character });
        adventurer.claimAdventurer(profileId, character, signature);

        assertEq(adventurer.charactersLeft(character), oldCharacterSupply - 1);
        assertTrue(adventurer.profileClaimed(profileId));
        assertEq(adventurer.characterType({ tokenId: 1 }), character);
        assertEq(adventurer.totalSupply(), 1);
    }

    /* Helper Functions */

    function getClaimSignature(
        address account,
        bytes32 profileId,
        Characters character
    ) internal view returns (bytes memory) {
        bytes32 digest = keccak256(abi.encodePacked(account, profileId, character)).toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign({ privateKey: users.signer.privateKey, digest: digest });
        return abi.encodePacked(r, s, v);
    }

    function _initializeClaim() internal {
        startHoax(users.admin.addr);
        adventurer.addCharacterSupply({ characters: _getCharacters(), amounts: _getAmounts() });
        adventurer.toggleClaimState();
        vm.stopPrank();
    }

    function _getCharacters() internal pure returns (Characters[] memory characters) {
        characters = new Characters[](13);
        for (uint256 i = 0; i < characters.length; i++) {
            characters[i] = Characters(i+1);
        }
    }

    function _getAmounts() internal pure returns (uint256[] memory amounts) {
        amounts = new uint256[](13);
        amounts[0] = 120;
        amounts[1] = 200;
        amounts[2] = 300;
        amounts[3] = 400;
        amounts[4] = 500;
        amounts[5] = 750;
        amounts[6] = 1250;
        amounts[7] = 1500;
        amounts[8] = 3500;
        amounts[9] = 5000;
        amounts[10] = 7500;
        amounts[11] = 9000;
        amounts[12] = type(uint256).max;
    }

}
