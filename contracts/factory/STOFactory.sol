pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
import './CloneFactory.sol';
import '../token/KonneticToken.sol';
import '../factory/StoRegistry.sol';

/**
MIT License
Copyright (c) 2020 Openlaw
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

contract StoFactory is CloneFactory {
    struct Adapter {
        bytes32 id;
        address addr;
        uint128 flags;
    }

    // stoAddr => hashedName
    mapping(address => bytes32) public stos;
    // hashedName => stoAdrr
    mapping(bytes32 => address) public addresses;

    address public identityAddress;

    /**
     * @notice Event emitted when a new STO has been created.
     * @param _address The STO address.
     * @param _name The STO name.
     */
    event StoCreated(address _address, string _name);

    constructor(address _identityAddress) {
        require(_identityAddress != address(0x0), 'invalid addr');
        identityAddress = _identityAddress;
    }

    /**
     * @notice Creates and initializes a new StoRegistry with the sto creator and the transaction sender.
     * @notice Enters the new StoRegistry in the stoFactory state.
     * @dev The stoName must not already have been taken.
     * @param stoName The name of the sto which, after being hashed, is used to access the address.
     * @param creator The sto's creator, who will be an initial member.
     */
    function createsto(string calldata stoName, address creator) external {
        bytes32 hashedName = keccak256(abi.encode(stoName));
        require(
            addresses[hashedName] == address(0x0),
            string(abi.encodePacked('name ', stoName, ' already taken'))
        );

        KonneticToken sto = KonneticToken(_createClone(identityAddress));

        address stoAddr = address(sto);
        addresses[hashedName] = stoAddr;
        stos[stoAddr] = hashedName;

        sto.mint(creator, 10);
        //slither-disable-next-line reentrancy-events
        emit StoCreated(stoAddr, stoName);
    }

    /**
     * @notice Returns the sto address based on its name.
     * @return The address of a sto, given its name.
     * @param stoName Name of the sto to be searched.
     */
    function getstoAddress(string calldata stoName)
        external
        view
        returns (address)
    {
        return addresses[keccak256(abi.encode(stoName))];
    }

    /**
     * @notice Adds adapters and sets their ACL for StoRegistry functions.
     * @dev A new sto is instantiated with only the Core Modules enabled, to reduce the call cost. This call must be made to add adapters.
     * @dev The message sender must be an active member of the sto.
     * @dev The sto must be in `CREATION` state.
     * @param sto StoRegistry to have adapters added to.
     * @param adapters Adapter structs to be added to the sto.
     */
    function addAdapters(StoRegistry sto, Adapter[] calldata adapters)
        external
    {
        
        //Registring Adapters
        require(
            sto.state() == StoRegistry.stoState.CREATION,
                'this sto has already been setup'
        );

        for (uint256 i = 0; i < adapters.length; i++) {
            //slither-disable-next-line calls-loop
            sto.replaceAdapter(
                adapters[i].id,
                adapters[i].addr,
                adapters[i].flags,
                new bytes32[](0),
                new uint256[](0)
            );
        }
    }

    /**
     * @notice Configures extension to set the ACL for each adapter that needs to access the extension.
     * @dev The message sender must be an active member of the sto.
     * @dev The sto must be in `CREATION` state.
     * @param sto StoRegistry for which the extension is being configured.
     * @param extension The address of the extension to be configured.
     * @param adapters Adapter structs for which the ACL is being set for the extension.
     */
    function configureExtension(
        StoRegistry sto,
        address extension,
        Adapter[] calldata adapters
    ) external {
        //Registring Adapters
        require(
            sto.state() == StoRegistry.stoState.CREATION,
            'this sto has already been setup'
        );

        for (uint256 i = 0; i < adapters.length; i++) {
            //slither-disable-next-line calls-loop
            sto.setAclToExtensionForAdapter(
                extension,
                adapters[i].addr,
                adapters[i].flags
            );
        }
    }

    /**
     * @notice Removes an adapter with a given ID from a sto, and adds a new one of the same ID.
     * @dev The message sender must be an active member of the sto.
     * @dev The sto must be in `CREATION` state.
     * @param sto sto to be updated.
     * @param adapter Adapter that will be replacing the currently-existing adapter of the same ID.
     */
    function updateAdapter(StoRegistry sto, Adapter calldata adapter) external {
        require(
            sto.state() == StoRegistry.stoState.CREATION,
            'this sto has already been setup'
        );

        sto.replaceAdapter(
            adapter.id,
            adapter.addr,
            adapter.flags,
            new bytes32[](0),
            new uint256[](0)
        );
    }
}