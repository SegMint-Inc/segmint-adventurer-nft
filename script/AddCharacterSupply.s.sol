// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../test/Base.sol";

contract AddCharacterSupplyScript is Base {
    using stdJson for string;

    string public root;
    string public basePath;
    string public path;
    string public jsonCharacters;

    uint256 public adminPrivateKey;

    Characters[] private characters;
    uint256[] private amounts;

    function setUp() public {
        adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
        admin = vm.rememberKey(adminPrivateKey);

        root = vm.projectRoot();
        basePath = string.concat(root, "/script/constants/output/");
        path = string.concat(basePath, vm.envString("DEPLOYMENT_FILENAME"));
        string memory jsonConstants = vm.readFile(path);

        // Define state variables for character updates.
        adventurer = abi.decode(vm.parseJson(jsonConstants, ".adventurerProxy"), (Adventurer));

        basePath = string.concat(root, "/data/");
        path = string.concat(basePath, "CharacterSupply.json");
        jsonCharacters = vm.readFile(path);

        (characters, amounts) = loadSupplyFromJSON();
    }

    function run() public {
        vm.broadcast(admin);
        adventurer.setCharacterSupply(characters, amounts);
    }

    function loadSupplyFromJSON() internal view returns (Characters[] memory, uint256[] memory) {
        uint256 length = 13;
        Characters[] memory c = new Characters[](length);
        uint256[] memory a = new uint256[](length);

        for (uint256 i = 0; i < c.length; i++) {
            c[i] = Characters(i + 1);
            a[i] =
                abi.decode(vm.parseJson(jsonCharacters, string(abi.encodePacked(".", vm.toString(i + 1)))), (uint256));
        }

        return (c, a);
    }
}
