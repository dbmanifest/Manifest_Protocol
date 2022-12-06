pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import '../factory/stoRegistry.sol';
import '../helpers/stoHelper.sol';

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
abstract contract AdapterGuard {
    /**
     * @dev Only registered adapters are allowed to execute the function call.
     */
    modifier onlyAdapter(stoRegistry sto) {
        require(
            sto.isAdapter(msg.sender) ||
                stoHelper.isInCreationModeAndHasAccess(sto),
            'onlyAdapter'
        );
        _;
    }

    modifier reentrancyGuard(stoRegistry sto) {
        require(sto.lockedAt() != block.number, 'reentrancy guard');
        sto.lockSession();
        _;
        sto.unlockSession();
    }

    modifier executorFunc(stoRegistry sto) {
        address executorAddr = sto.getExtensionAddress(
            keccak256('executor-ext')
        );
        require(address(this) == executorAddr, 'only callable by the executor');
        _;
    }

    modifier hasAccess(stoRegistry sto, stoRegistry.AclFlag flag) {
        require(
            stoHelper.isInCreationModeAndHasAccess(sto) ||
                sto.hasAdapterAccess(msg.sender, flag),
            'accessDenied'
        );
        _;
    }
}