// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../test/Base.sol";

contract DeployScript is Base {
    using stdJson for string;

    string public root;
    string public basePath;
    string public path;

    uint256 public deployerPrivateKey;
    address public deployer;

    function setUp() public {
        deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        deployer = vm.rememberKey(deployerPrivateKey);

        root = vm.projectRoot();
        basePath = string.concat(root, "/script/constants/");
        path = string.concat(basePath, vm.envString("CONSTANTS_FILENAME"));
        string memory jsonConstants = vm.readFile(path);

        /// Define state variables for deployment.
        owner = deployer;
        admin = abi.decode(vm.parseJson(jsonConstants, ".admin"), (address));
        signer = abi.decode(vm.parseJson(jsonConstants, ".signer"), (address));
        accessRegistry = abi.decode(vm.parseJson(jsonConstants, ".accessRegistry"), (IAccessRegistry));
        baseTokenURI = abi.decode(vm.parseJson(jsonConstants, ".baseTokenURI"), (string));
    }

    function run() public {
        /// Deploy the contracts.
        vm.startBroadcast(deployer);
        coreSetup();
        vm.stopBroadcast();

        basePath = string.concat(root, "/script/constants/output/");
        path = string.concat(basePath, vm.envString("DEPLOYMENT_FILENAME"));

        /// Write deployment addresses to file.
        bytes32 implementation = vm.load({target: address(adventurer), slot: implementationSlot});
        vm.writeJson(
            vm.serializeAddress("", "adventurerImplementation", address(uint160(uint256(implementation)))), path
        );
        vm.writeJson(vm.serializeAddress("", "adventurerProxy", address(adventurer)), path);
    }
}
