// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "../test/Base.sol";

contract DeployScript is Base {
    using stdJson for string;

    uint256 internal constant ABSTRACT_CHAIN_ID = 2741;

    string public root;
    string public basePath;
    string public path;

    uint256 public deployerPrivateKey;
    address public deployer;
    uint256 public adminPrivateKey;

    function setUp() public {
        string memory chainName;
        if (block.chainid == ABSTRACT_CHAIN_ID) {
            deployerPrivateKey = vm.envUint({ name: "MAINNET_DEPLOYER_PRIVATE_KEY" });
            adminPrivateKey = vm.envUint({ name: "MAINNET_ADMIN_PRIVATE_KEY" });
            chainName = ".mainnet";
        } else {
            deployerPrivateKey = vm.envUint({ name: "TESTNET_DEPLOYER_PRIVATE_KEY" });
            adminPrivateKey = vm.envUint({ name: "TESTNET_ADMIN_PRIVATE_KEY" });
            chainName = ".testnet";
        }

        deployer = vm.rememberKey({ privateKey: deployerPrivateKey });
        admin = vm.rememberKey({ privateKey: adminPrivateKey });
        owner = deployer;

        root = vm.projectRoot();
        basePath = string.concat(root, "/script/constants/");
        path = string.concat(basePath, vm.envString("CONSTANTS_FILENAME"));
        string memory jsonConstants = vm.readFile(path);

        signer = abi.decode(vm.parseJson(jsonConstants, string.concat(chainName, ".signer")), (address));
        treasury = abi.decode(vm.parseJson(jsonConstants, string.concat(chainName, ".treasury")), (address));
        baseTokenURI = abi.decode(vm.parseJson(jsonConstants, string.concat(chainName, ".baseTokenURI")), (string));
    }

    function run() public {
        vm.startBroadcast(deployer);
        coreSetup();
        vm.stopBroadcast();

        basePath = string.concat(root, "/script/constants/output/");
        path = string.concat(basePath, string.concat("Deployment-", vm.toString({ value: block.chainid }), ".json"));

        bytes32 implementation = vm.load({ target: address(adventurer), slot: implementationSlot });
        vm.writeJson({
            json: vm.serializeAddress("", "adventurerImplementation", address(uint160(uint256(implementation)))),
            path: path
        });
        vm.writeJson(vm.serializeAddress("", "adventurerProxy", address(adventurer)), path);
        vm.writeJson(vm.serializeAddress("", "signer", signer), path);
        vm.writeJson(vm.serializeAddress("", "treasury", treasury), path);
        vm.writeJson(vm.serializeString("", "baseTokenURI", baseTokenURI), path);
    }
}
