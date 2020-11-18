// Copyright (C) 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: GPL-3.0-only
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.

// This program is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
// PARTICULAR PURPOSE. See the GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// Note: This component currently has dependencies that are licensed under the GNU
// GPL, version 3, and so you should treat this component as a whole as being under
// the GPL version 3. But all Cartesi-written code in this component is licensed
// under the Apache License, version 2, or a compatible permissive license, and can
// be used independently under the Apache v2 license. After this component is
// rewritten, the entire component will be released under the Apache v2 license.


/// @title Interface DescartesV2 contract
pragma solidity ^0.7.0;


// TODO: Should this be an instantiator?
contract DescartesV2 {

    State[] states; // sequence of machine states
    Input[] inputs; // hashes of all inputs, always accessible on Logger dlib
    bytes32[] logs; // how do we deal with logs?
    uint256 inputWindow; // time in seconds each epoch waits for inputs
                         // if there is a challenge/invalid state, the inputs
                         // get accumulated to the next epoch

    address logger; // address of logger contract
    address inputValidator; // if input is permissionless, == 0x00
                            // if not, this is a contract
    address quorum; // contract that manages the quorum
    uint256 challengingPeriod; // time it takes for status to go from
                               // Pending => Finalized

    // TODO: Invalid might be analogous to Finalized with different hash/claimer
    enum status {Pending, Finalized, Challenged, Invalid}

    // TODO: Input variables are looking a bit rendundant
    struct Input {
        bytes32 payload; // hash of input
        address sender; // msg.sender address
        uint256 timestamp; // timestamp of when it was added
        uint256 blockNumber; // block number of when its was added
        uint256 blockHash; // hash of the block it was added (to fight reorgs?)
    }

    struct Output {
        bytes32 outputHash; // hash of output
        address destination; // address to "aim" this output to
        bytes32 payload; // payload that will be sent to address
        uint256 highestGas; // highest quantity of gas that has been tried
        bool executed; // true if executed without reverting

        bytes32[] dependencies; // outputs that this output depends on
                                // can only be executed if all of them have been
                                // properly executed (executed == true)
    }

    // this will be a contract
    struct Quorum {
        uint256 size; // size of quorum
        address[] validators;
        // func addMember;
        // func kickMember;
        // func penalizeMember;
        // func isValidator;
    }

    struct State {
        bytes32 stateHash; // hash of cartesi machine
        uint256 maxCycle; // max number of machine cycle to run
        uint256 timestamp; // timestamp of claim submission
        address claimer; // claimed by

        //TODO: do we need a list of challengers?
        address challenger; // if !status.Challenged, challenger == 0x00

        address[] attestators; // validators that attested the validity of state

        uint256 inputCheckpoint; // index of last input this epoch.
        Output[] outputs; // outputs created by this claim
        status currentStatus; // status of claimed machine state
    }

    function addInput(bytes32 _input) {
        // if inputValidator != 0x00, require(inputValidator.validate(_input)
        // check if input is available on logger dlib if not send msg.data to it
        // add input

        // if block.timestamp < currentState.timestamp + inputWindow
        //      currentState.inputCheckpoint = input index
    }

    // TODO: Can you only claim when previous state was finalized?
    //_outputHash == meta hash of the list of outputs
    function claim(bytes32 _finalHash, uint256 _maxCycle,  bytes32 _outputHash) {
        //// dont need initial hash, since we always have states[states.length - 1]
        //// this always proccess inputs from states[states.length - 2] to states[states.length - 1]

        // check if last state is finalized / can be finalized
        // check if msg.sender is isValid
        // check if outputs is cointained of finalHash

        // if state exists
        //      if status is Pending
        //          if finalHash && maxCycle match: call attest()
        //          else: call challenge()

        // check if inputCheckpoint > lastInput
        // update last Input

        //create new State
    }

    // TODO: this will actually be more complex, because we might have
    //       n - 1 challenges
    function challenge(uint256 _stateIndex) internal {
        // deposit collateral (ether or ctsi?)
        // check if msg.sender is validator
        // check if state.status == pending
    }

    function finalizeState(uint256 _stateIndex) {
        // anyone can call
        // check if status == Pending
        // check if block.timestamp > state.timestamp + challengingPeriod
        // status Pendng => Finalized
    }
    function attest(uint256 _stateIndex) {
        // check if status of state [_stateIndex - 1] == Finalized
        //      if not, call attest on that (can this recursion blow up?)
        // check if state.status == pending
        // check if msg.sender is a validator
        // check if msg.sender already validated this state (this is ok because
        // the array is small)

        // add validator to [attestators]
        // if attestators.length == number of validators, state.status = finalized
    }

    function penalize(address _validator, uint256 _stateIndex) {
        // check if _state.status == invalid
        // check if _validator is in _state.attestators

        // punish validator (depending on the punish need to check if they
        // have been punished before.
    }
}
