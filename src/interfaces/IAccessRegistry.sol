// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title IAccessRegistry
 */
interface IAccessRegistry {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           ENUMS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Enum encapsulating the access type related to a specified address.
     * @custom:value BLOCKED: User does not have access.
     * @custom:value RESTRICTED: User has restricted access.
     * @custom:value UNRESTRICTED: User has unrestricted access.
     */
    enum AccessType {
        BLOCKED,
        RESTRICTED,
        UNRESTRICTED
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         FUNCTIONS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Function used to view the access type of an address.
     * @param account Account to view the access type for.
     */
    function accessType(address account) external view returns (AccessType);
}
