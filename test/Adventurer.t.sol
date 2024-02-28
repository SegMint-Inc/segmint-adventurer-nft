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
        assertTrue(adventurer.hasAllRoles({user: users.admin.addr, roles: AccessRoles.ADMIN_ROLE}));

        /// AccessRegistry access types.
        assertEq(accessRegistry.accessType({account: users.alice.addr}), IAccessRegistry.AccessType.RESTRICTED);
        assertEq(accessRegistry.accessType({account: users.bob.addr}), IAccessRegistry.AccessType.UNRESTRICTED);
    }

    /* `initialize()` Tests */

    function test_Initialize_Fuzzed(address _owner, address _admin, address _signer, address _accessRegistry) public {
        vm.assume(
            _owner != address(0) && _admin != address(0) && _signer != address(0) && _accessRegistry != address(0)
        );

        bytes32 implementation = vm.load({target: address(adventurer), slot: implementationSlot});
        ERC1967Proxy proxy = new ERC1967Proxy({
            implementation: address(uint160(uint256(implementation))),
            _data: abi.encodeWithSelector(IAdventurer.initialize.selector, _owner, _admin, _signer, _accessRegistry, "")
        });

        Adventurer newAdventurer = Adventurer(address(proxy));

        assertEq(newAdventurer.name(), "Adventurer");
        assertEq(newAdventurer.symbol(), "ADVNT");
        assertEq(newAdventurer.owner(), _owner);
        assertEq(newAdventurer.signer(), _signer);
        assertEq(address(newAdventurer.accessRegistry()), _accessRegistry);
        assertTrue(newAdventurer.hasAllRoles({user: _admin, roles: AccessRoles.ADMIN_ROLE}));
    }

    function testCannot_Initialize_Implementation() public {
        bytes32 implementation = vm.load({target: address(adventurer), slot: implementationSlot});
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
        bytes32 implementation = vm.load({target: address(adventurer), slot: implementationSlot});

        vm.expectRevert(IAdventurer.ZeroAddressInvalid.selector);
        new ERC1967Proxy({
            implementation: address(uint160(uint256(implementation))),
            _data: abi.encodeWithSelector(
                IAdventurer.initialize.selector, address(0), users.admin.addr, users.signer.addr, accessRegistry, ""
                )
        });
    }

    function testCannot_Initialize_ZeroAddressInvalid_Admin() public {
        bytes32 implementation = vm.load({target: address(adventurer), slot: implementationSlot});

        vm.expectRevert(IAdventurer.ZeroAddressInvalid.selector);
        new ERC1967Proxy({
            implementation: address(uint160(uint256(implementation))),
            _data: abi.encodeWithSelector(
                IAdventurer.initialize.selector, address(this), address(0), users.signer.addr, accessRegistry, ""
                )
        });
    }

    function testCannot_Initialize_ZeroAddressInvalid_Signer() public {
        bytes32 implementation = vm.load({target: address(adventurer), slot: implementationSlot});

        vm.expectRevert(IAdventurer.ZeroAddressInvalid.selector);
        new ERC1967Proxy({
            implementation: address(uint160(uint256(implementation))),
            _data: abi.encodeWithSelector(
                IAdventurer.initialize.selector, address(this), users.admin.addr, address(0), accessRegistry, ""
                )
        });
    }

    function testCannot_Initialize_ZeroAddressInvalid_AccessRegistry() public {
        bytes32 implementation = vm.load({target: address(adventurer), slot: implementationSlot});

        vm.expectRevert(IAdventurer.ZeroAddressInvalid.selector);
        new ERC1967Proxy({
            implementation: address(uint160(uint256(implementation))),
            _data: abi.encodeWithSelector(
                IAdventurer.initialize.selector, address(this), users.admin.addr, users.signer.addr, address(0), ""
                )
        });
    }

    /* `claimAdventurer()` Tests */

    function test_ClaimAdventurer_Fuzzed(bytes32 profileId, uint256 characterId) public initializeClaim {
        Characters character = Characters(bound(characterId, 1, 13));
        bytes memory signature = getClaimSignature(users.alice.addr, profileId, character);

        uint256 oldCharacterSupply = adventurer.charactersLeft(character);

        vm.prank(users.alice.addr);
        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true});
        emit AdventurerClaimed({account: users.alice.addr, profileId: profileId, character: character});
        adventurer.claimAdventurer(profileId, character, signature);

        assertEq(adventurer.charactersLeft(character), oldCharacterSupply - 1);
        assertTrue(adventurer.profileClaimed(profileId));
        assertEq(adventurer.characterType({tokenId: 1}), character);
        assertEq(adventurer.totalSupply(), 1);
    }

    function testCannot_ClaimAdventurer_InvalidClaimState_Fuzzed(bytes32 profileId, uint256 characterId) public {
        Characters character = Characters(bound(characterId, 1, 13));
        bytes memory signature = getClaimSignature(users.eve.addr, profileId, character);

        vm.prank(users.eve.addr);
        vm.expectRevert(IAdventurer.InvalidClaimState.selector);
        adventurer.claimAdventurer(profileId, character, signature);
    }

    function testCannot_ClaimAdventurer_InvalidAccessType_Fuzzed(bytes32 profileId, uint256 characterId)
        public
        initializeClaim
    {
        Characters character = Characters(bound(characterId, 1, 13));
        bytes memory signature = getClaimSignature(users.eve.addr, profileId, character);

        vm.prank(users.eve.addr);
        vm.expectRevert(IAdventurer.InvalidAccessType.selector);
        adventurer.claimAdventurer(profileId, character, signature);
    }

    function testCannot_ClaimAdventurer_ProfileHasClaimed_Fuzzed(bytes32 profileId, uint256 characterId)
        public
        initializeClaim
    {
        Characters character = Characters(bound(characterId, 1, 13));
        bytes memory signature = getClaimSignature(users.alice.addr, profileId, character);

        vm.startPrank(users.alice.addr);
        adventurer.claimAdventurer(profileId, character, signature);
        vm.expectRevert(IAdventurer.ProfileHasClaimed.selector);
        adventurer.claimAdventurer(profileId, character, signature);
    }

    function testCannot_ClaimAdventurer_AccountHasClaimed_Fuzzed(bytes32 profileId, uint256 characterId)
        public
        initializeClaim
    {
        Characters character = Characters(bound(characterId, 1, 13));
        bytes memory signature = getClaimSignature(users.alice.addr, profileId, character);

        vm.startPrank(users.alice.addr);
        adventurer.claimAdventurer(profileId, character, signature);

        profileId = keccak256(abi.encodePacked(profileId));
        signature = getClaimSignature(users.alice.addr, profileId, character);

        vm.expectRevert(IAdventurer.AccountHasClaimed.selector);
        adventurer.claimAdventurer(profileId, character, signature);
    }

    function testCannot_ClaimAdventurer_UndefinedCharacterType_Fuzzed(bytes32 profileId) public initializeClaim {
        bytes memory signature =
            getClaimSignature({account: users.alice.addr, profileId: profileId, character: Characters.UNDEFINED});

        vm.prank(users.alice.addr);
        vm.expectRevert(IAdventurer.UndefinedCharacterType.selector);
        adventurer.claimAdventurer(profileId, Characters.UNDEFINED, signature);
    }

    function testCannot_ClaimAdventurer_CharacterSupplyExhausted() public initializeClaim {
        Characters character = Characters.LOCKIANI;
        uint256 amount = adventurer.charactersLeft(character);

        vm.prank(users.admin.addr);
        adventurer.treasuryMint(character, amount, users.treasury.addr);

        bytes32 profileId = keccak256(abi.encodePacked("test.profile"));
        bytes memory signature = getClaimSignature(users.alice.addr, profileId, character);

        vm.prank(users.alice.addr);
        vm.expectRevert(IAdventurer.CharacterSupplyExhausted.selector);
        adventurer.claimAdventurer(profileId, character, signature);
    }

    function testCannot_ClaimAdventurer_SignerMismatch_Fuzzed(bytes32 profileId, uint256 characterId)
        public
        initializeClaim
    {
        Characters character = Characters(bound(characterId, 1, 13));
        bytes memory signature = getClaimSignature(users.bob.addr, profileId, character);

        vm.prank(users.alice.addr);
        vm.expectRevert(IAdventurer.SignerMismatch.selector);
        adventurer.claimAdventurer(profileId, character, signature);
    }

    /* `transformAdventurer()` Tests */

    function test_TransformAdventurer_Fuzzed(bytes32 profileId, uint256 characterId) public initializeClaim {
        Characters character = Characters(bound(characterId, 1, 13));

        vm.startPrank(users.alice.addr);
        adventurer.claimAdventurer({
            profileId: profileId,
            character: character,
            signature: getClaimSignature(users.alice.addr, profileId, character)
        });
        assertEq(adventurer.ownerOf({tokenId: 1}), users.alice.addr);
        assertEq(adventurer.balanceOf({owner: users.alice.addr}), 1);
        assertEq(adventurer.totalSupply(), 1);

        vm.expectEmit({checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true});
        emit AdventurerTransformed({account: users.alice.addr, burntTokenId: 1, transformedId: 2});
        adventurer.transformAdventurer({
            tokenId: 1,
            signature: getTransformSignature({account: users.alice.addr, tokenId: 1})
        });

        vm.expectRevert();
        adventurer.ownerOf({tokenId: 1});
        assertEq(adventurer.ownerOf({tokenId: 2}), users.alice.addr);
        assertEq(adventurer.balanceOf({owner: users.alice.addr}), 1);
        assertEq(adventurer.characterType({tokenId: 1}), Characters.UNDEFINED);
        assertEq(adventurer.characterType({tokenId: 2}), Characters.RISKUS);
        assertEq(adventurer.totalSupply(), 1);
    }

    function testCannot_TransformAdventurer_InvalidClaimState() public {
        vm.prank(users.alice.addr);
        vm.expectRevert(IAdventurer.InvalidClaimState.selector);
        adventurer.transformAdventurer({tokenId: 0, signature: ""});
    }

    function testCannot_TransformAdventurer_NonExistentTokenId_Fuzzed(uint256 randId) public initializeClaim {
        vm.prank(users.alice.addr);
        vm.expectRevert(IAdventurer.NonExistentTokenId.selector);
        adventurer.transformAdventurer({tokenId: randId, signature: ""});
    }

    function testCannot_TransformAdventurer_CallerNotOwner_Fuzzed(
        bytes32 profileId,
        uint256 characterId,
        address nonOwner
    ) public initializeClaim {
        Characters character = Characters(bound(characterId, 1, 13));
        vm.assume(nonOwner != users.alice.addr);

        vm.startPrank(users.alice.addr);
        adventurer.claimAdventurer({
            profileId: profileId,
            character: character,
            signature: getClaimSignature(users.alice.addr, profileId, character)
        });
        vm.stopPrank();

        vm.prank(users.eve.addr);
        vm.expectRevert(IAdventurer.CallerNotOwner.selector);
        adventurer.transformAdventurer({tokenId: 1, signature: ""});
    }

    function testCanot_TransformAdventurer_SignerMismatch(bytes32 profileId, uint256 characterId)
        public
        initializeClaim
    {
        Characters character = Characters(bound(characterId, 1, 13));

        vm.startPrank(users.alice.addr);
        adventurer.claimAdventurer({
            profileId: profileId,
            character: character,
            signature: getClaimSignature(users.alice.addr, profileId, character)
        });

        vm.expectRevert(IAdventurer.SignerMismatch.selector);
        adventurer.transformAdventurer({
            tokenId: 1,
            signature: getTransformSignature({account: users.bob.addr, tokenId: 1})
        });
    }

    /* `setCharacterSupply()` Tests */

    function test_SetCharacterSupply() public {
        (Characters[] memory characters, uint256[] memory amounts) = loadSupplyFromJSON();

        // Expect event emission for each character.
        for (uint256 i = 0; i < characters.length; i++) {
            vm.expectEmit({checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true});
            emit CharacterSupplyUpdated({character: characters[i], amount: amounts[i]});
        }

        vm.prank(users.admin.addr);
        adventurer.setCharacterSupply(characters, amounts);

        for (uint256 i = 0; i < characters.length; i++) {
            assertEq(adventurer.charactersLeft(characters[i]), amounts[i]);
        }
    }

    function testCannot_SetCharacterSupply_Unauthorized_Fuzzed(address nonAdmin) public {
        (Characters[] memory characters, uint256[] memory amounts) = loadSupplyFromJSON();
        vm.assume(nonAdmin != users.admin.addr);

        vm.prank(nonAdmin);
        vm.expectRevert(Ownable.Unauthorized.selector);
        adventurer.setCharacterSupply(characters, amounts);
    }

    function testCannot_SetCharacterSupply_ArrayLengthMismatch_Fuzzed(uint256 a, uint256 b) public {
        a = bound(a, 1, 32);
        b = bound(b, 1, 32);
        vm.assume(a != b);

        vm.prank(users.admin.addr);
        vm.expectRevert(IAdventurer.ArrayLengthMismatch.selector);
        adventurer.setCharacterSupply({characters: new Characters[](a), amounts: new uint256[](b)});
    }

    function testCannot_SetCharacterSupply_ZeroLengthArray() public {
        vm.prank(users.admin.addr);
        vm.expectRevert(IAdventurer.ZeroLengthArray.selector);
        adventurer.setCharacterSupply({characters: new Characters[](0), amounts: new uint256[](0)});
    }

    function testCannot_SetCharacterSupply_UndefinedCharacterType_Fuzzed(uint256 idx) public {
        idx = bound(idx, 0, 12);

        (Characters[] memory characters, uint256[] memory amounts) = loadSupplyFromJSON();
        characters[idx] = Characters.UNDEFINED;

        vm.prank(users.admin.addr);
        vm.expectRevert(IAdventurer.UndefinedCharacterType.selector);
        adventurer.setCharacterSupply(characters, amounts);
    }

    /* `treasuryMint()` Tests */

    function test_treasuryMint_Fuzzed(uint256 characterId, uint256 mintAmount) public initializeClaim {
        characterId = bound(characterId, 1, 13);
        mintAmount = bound(mintAmount, 1, 50);

        vm.prank(users.admin.addr);
        adventurer.treasuryMint({character: Characters(characterId), amount: mintAmount, receiver: users.treasury.addr});

        assertEq(adventurer.balanceOf({owner: users.treasury.addr}), mintAmount);
        assertEq(adventurer.totalSupply(), mintAmount);

        for (uint256 i = 1; i <= mintAmount; i++) {
            assertEq(adventurer.characterType({tokenId: i}), Characters(characterId));
        }
    }

    function testCannot_TreasuryMint_Unauthorized_Fuzzed(address nonGameMaster) public initializeClaim {
        vm.assume(nonGameMaster != users.admin.addr);

        vm.prank(nonGameMaster);
        vm.expectRevert(Ownable.Unauthorized.selector);
        adventurer.treasuryMint({character: Characters.CYPHERON, amount: 1, receiver: nonGameMaster});
    }

    function testCannot_TreasuryMint_UndefinedCharacterType() public initializeClaim {
        vm.prank(users.admin.addr);
        vm.expectRevert(IAdventurer.UndefinedCharacterType.selector);
        adventurer.treasuryMint({character: Characters.UNDEFINED, amount: 1, receiver: users.treasury.addr});
    }

    function testCannot_TreasuryMint_ZeroAddressInvalid() public initializeClaim {
        vm.prank(users.admin.addr);
        vm.expectRevert(IAdventurer.ZeroAddressInvalid.selector);
        adventurer.treasuryMint({character: Characters.CHRONOSIA, amount: 1, receiver: address(0)});
    }

    function testCannot_TreasuryMint_AmountOverSupply_Fuzzed(uint256 characterId) public initializeClaim {
        Characters character = Characters(bound(characterId, 1, 13));
        uint256 mintAmount = adventurer.charactersLeft(character) + 1;

        vm.prank(users.admin.addr);
        vm.expectRevert(IAdventurer.AmountOverSupply.selector);
        adventurer.treasuryMint({character: character, amount: mintAmount, receiver: users.treasury.addr});
    }

    /* `updateMetadata()` Tests */

    function test_UpdateMetadata() public {
        vm.prank(users.admin.addr);
        adventurer.updateMetadata();
    }

    function testCannot_UpdateMetadata_Unauthorized_Fuzzed(address nonAdmin) public {
        vm.assume(nonAdmin != users.admin.addr);

        vm.prank(nonAdmin);
        vm.expectRevert(Ownable.Unauthorized.selector);
        adventurer.updateMetadata();
    }

    /* `setSigner()` Tests */

    function test_SetSigner_Fuzzed(address newSigner) public {
        vm.assume(newSigner != address(0));
        address oldSigner = adventurer.signer();

        vm.prank(users.admin.addr);
        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true});
        emit SignerUpdated(oldSigner, newSigner);
        adventurer.setSigner(newSigner);

        assertEq(adventurer.signer(), newSigner);
    }

    function testCannot_SetSigner_Unauthorized_Fuzzed(address nonAdmin) public {
        vm.assume(nonAdmin != users.admin.addr);

        vm.prank(nonAdmin);
        vm.expectRevert(Ownable.Unauthorized.selector);
        adventurer.setSigner({newSigner: nonAdmin});
    }

    function testCannot_SetSigner_ZeroAddressInvalid() public {
        vm.prank(users.admin.addr);
        vm.expectRevert(IAdventurer.ZeroAddressInvalid.selector);
        adventurer.setSigner({newSigner: address(0)});
    }

    /* `setAccessRegistry()` Tests */

    function test_SetAccessRegistry(IAccessRegistry newAccessRegistry) public {
        vm.assume(address(newAccessRegistry) != address(0));
        IAccessRegistry oldAccessRegistry = adventurer.accessRegistry();

        vm.prank(users.admin.addr);
        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true});
        emit AccessRegistryUpdated(oldAccessRegistry, newAccessRegistry);
        adventurer.setAccessRegistry(newAccessRegistry);

        assertEq(adventurer.accessRegistry(), newAccessRegistry);
    }

    function testCannot_SetAccessRegistry_Unauthorized(address nonAdmin) public {
        vm.assume(nonAdmin != users.admin.addr);

        vm.prank(nonAdmin);
        vm.expectRevert(Ownable.Unauthorized.selector);
        adventurer.setAccessRegistry({newAccessRegistry: IAccessRegistry(nonAdmin)});
    }

    function testCannot_SetAccessRegistry_ZeroAddressInvalid() public {
        vm.prank(users.admin.addr);
        vm.expectRevert(IAdventurer.ZeroAddressInvalid.selector);
        adventurer.setAccessRegistry({newAccessRegistry: IAccessRegistry(address(0))});
    }

    /* `setBaseTokenURI()` Tests */

    function test_SetBaseTokenURI_Fuzzed(string memory newBaseTokenURI) public {
        vm.prank(users.admin.addr);
        vm.expectEmit({checkTopic1: false, checkTopic2: false, checkTopic3: false, checkData: true});
        emit BaseTokenURIUpdated({oldBaseTokenURI: baseTokenURI, newBaseTokenURI: newBaseTokenURI});
        adventurer.setBaseTokenURI(newBaseTokenURI);
    }

    function testCannot_SetBaseTokenURI_Unauthorized_Fuzzed(address nonAdmin) public {
        vm.assume(nonAdmin != users.admin.addr);

        vm.prank(nonAdmin);
        vm.expectRevert(Ownable.Unauthorized.selector);
        adventurer.setBaseTokenURI({newBaseTokenURI: ""});
    }

    /* `tokenURI()` Tests */

    function test_TokenURI() public initializeClaim {
        bytes32 profileId = bytes32(0x00);
        bytes memory signature =
            getClaimSignature({account: users.alice.addr, profileId: profileId, character: Characters.COINDRA});

        vm.prank(users.alice.addr);
        adventurer.claimAdventurer(profileId, Characters.COINDRA, signature);

        string memory uri = "https://api.segmint.io/adventurers/";

        vm.startPrank(users.admin.addr);
        adventurer.setBaseTokenURI({newBaseTokenURI: uri});
        assertEq(adventurer.tokenURI({tokenId: 1}), string.concat(uri, "1"));
    }

    /* `toggleClaimState()` Tests */

    function test_ToggleClaimState() public {
        IAdventurer.ClaimState oldClaimState = adventurer.claimState();
        IAdventurer.ClaimState newClaimState = IAdventurer.ClaimState.ACTIVE;

        vm.prank(users.admin.addr);
        vm.expectEmit({checkTopic1: false, checkTopic2: false, checkTopic3: false, checkData: true});
        emit ClaimStateUpdated(oldClaimState, newClaimState);
        adventurer.toggleClaimState();

        assertEq(adventurer.claimState(), newClaimState);
    }

    function testCannot_ToggleClaimState_Unauthorized_Fuzzed(address nonAdmin) public {
        vm.assume(nonAdmin != users.admin.addr);

        vm.prank(nonAdmin);
        vm.expectRevert(Ownable.Unauthorized.selector);
        adventurer.toggleClaimState();
    }

    /* `supportsInterface()` Tests */

    function test_SupportsInterface() public {
        assertTrue(adventurer.supportsInterface({interfaceId: 0x49064906})); // ERC4906
        assertTrue(adventurer.supportsInterface({interfaceId: 0x2a55205a})); // ERC2981
        assertTrue(adventurer.supportsInterface({interfaceId: 0x80ac58cd})); // ERC721
    }

    /* ERC2981 Tests */

    function test_SetDefaultRoyalty_Fuzzed(address randAddr, uint256 feeNumerator, uint256 salePrice) public {
        vm.assume(randAddr != address(0));
        feeNumerator = bound(feeNumerator, 0, 10_000);
        salePrice = bound(salePrice, 0 wei, 10 ether);
        uint256 expectedFee = salePrice * feeNumerator / 10_000;

        vm.prank(users.admin.addr);
        adventurer.setDefaultRoyalty({receiver: randAddr, feeNumerator: uint96(feeNumerator)});

        (address receiver, uint256 royaltyFee) = adventurer.royaltyInfo({tokenId: 1, salePrice: salePrice});
        assertEq(receiver, randAddr);
        assertEq(royaltyFee, expectedFee);
    }

    function testCannot_SetDefaultyRoyalty_Unauthorized_Fuzzed(address nonAdmin) public {
        vm.assume(nonAdmin != users.admin.addr);

        vm.prank(nonAdmin);
        vm.expectRevert(Ownable.Unauthorized.selector);
        adventurer.setDefaultRoyalty({receiver: nonAdmin, feeNumerator: 10_000});
    }

    function test_DeleteDefaultRoyalty_Fuzzed(address randAddr, uint256 feeNumerator, uint256 salePrice) public {
        vm.assume(randAddr != address(0));
        feeNumerator = bound(feeNumerator, 0, 10_000);
        salePrice = bound(salePrice, 0 wei, 10 ether);
        uint256 expectedFee = salePrice * feeNumerator / 10_000;

        vm.startPrank(users.admin.addr);
        adventurer.setDefaultRoyalty({receiver: randAddr, feeNumerator: uint96(feeNumerator)});

        (address receiver, uint256 royaltyFee) = adventurer.royaltyInfo({tokenId: 1, salePrice: salePrice});
        assertEq(receiver, randAddr);
        assertEq(royaltyFee, expectedFee);

        adventurer.deleteDefaultRoyalty();
        (receiver, royaltyFee) = adventurer.royaltyInfo({tokenId: 1, salePrice: salePrice});
        assertEq(receiver, address(0));
        assertEq(royaltyFee, 0);
    }

    function testCannot_DeleteDefaultRoyalty_Unauthorized_Fuzzed(address nonAdmin) public {
        vm.assume(nonAdmin != users.admin.addr);

        vm.prank(nonAdmin);
        vm.expectRevert(Ownable.Unauthorized.selector);
        adventurer.deleteDefaultRoyalty();
    }

    function test_SetTokenRoyalty_Fuzzed(address randAddr, uint256 feeNumerator, uint256 salePrice, uint256 tokenId)
        public
    {
        vm.assume(randAddr != address(0));
        feeNumerator = bound(feeNumerator, 0, 10_000);
        salePrice = bound(salePrice, 0 wei, 10 ether);
        uint256 expectedFee = salePrice * feeNumerator / 10_000;

        vm.prank(users.admin.addr);
        adventurer.setTokenRoyalty({tokenId: tokenId, receiver: randAddr, feeNumerator: uint96(feeNumerator)});

        (address receiver, uint256 royaltyFee) = adventurer.royaltyInfo({tokenId: tokenId, salePrice: salePrice});
        assertEq(receiver, randAddr);
        assertEq(royaltyFee, expectedFee);
    }

    function testCannot_SetTokenRoyalty_Unauthorized_Fuzzed(address nonAdmin) public {
        vm.assume(nonAdmin != users.admin.addr);

        vm.prank(nonAdmin);
        vm.expectRevert(Ownable.Unauthorized.selector);
        adventurer.setTokenRoyalty({tokenId: 1, receiver: nonAdmin, feeNumerator: uint96(5_000)});
    }

    function test_ResetTokenRoyalty_Fuzzed(address randAddr, uint256 feeNumerator, uint256 salePrice, uint256 tokenId)
        public
    {
        vm.assume(randAddr != address(0));
        feeNumerator = bound(feeNumerator, 0, 10_000);
        salePrice = bound(salePrice, 0 wei, 10 ether);
        uint256 expectedFee = salePrice * feeNumerator / 10_000;

        vm.startPrank(users.admin.addr);
        adventurer.setTokenRoyalty({tokenId: tokenId, receiver: randAddr, feeNumerator: uint96(feeNumerator)});

        (address receiver, uint256 royaltyFee) = adventurer.royaltyInfo({tokenId: tokenId, salePrice: salePrice});
        assertEq(receiver, randAddr);
        assertEq(royaltyFee, expectedFee);

        adventurer.resetTokenRoyalty(tokenId);

        (receiver, royaltyFee) = adventurer.royaltyInfo({tokenId: tokenId, salePrice: salePrice});
        assertEq(receiver, address(0));
        assertEq(royaltyFee, 0);
    }

    /* Helper Functions */

    function getClaimSignature(address account, bytes32 profileId, Characters character)
        internal
        view
        returns (bytes memory)
    {
        bytes32 digest = keccak256(abi.encodePacked(account, profileId, character)).toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign({privateKey: users.signer.privateKey, digest: digest});
        return abi.encodePacked(r, s, v);
    }

    function getTransformSignature(address account, uint256 tokenId) internal view returns (bytes memory) {
        bytes32 digest = keccak256(abi.encodePacked(account, tokenId)).toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign({privateKey: users.signer.privateKey, digest: digest});
        return abi.encodePacked(r, s, v);
    }

    function _initializeClaim() internal {
        (Characters[] memory characters, uint256[] memory amounts) = loadSupplyFromJSON();
        vm.startPrank(users.admin.addr);
        adventurer.setCharacterSupply(characters, amounts);
        adventurer.toggleClaimState();
        vm.stopPrank();
    }
}
