// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Rollups initialization facet
pragma solidity ^0.8.0;

import {Phase} from "../interfaces/IRollups.sol";
import {IRollupsInit} from "../interfaces/IRollupsInit.sol";

import {LibRollupsInit} from "../libraries/LibRollupsInit.sol";
import {LibRollups} from "../libraries/LibRollups.sol";
import {LibInput} from "../libraries/LibInput.sol";
import {LibValidatorManager} from "../libraries/LibValidatorManager.sol";
import {LibSERC20Portal} from "../libraries/LibSERC20Portal.sol";
import {ClaimsMaskLibrary} from "../ClaimsMaskLibrary.sol";
import {LibFeeManager} from "../libraries/LibFeeManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RollupsInitFacet is IRollupsInit {
    using LibValidatorManager for LibValidatorManager.DiamondStorage;

    // @notice initialize the Rollups contract
    // @param _inputDuration duration of input accumulation phase in seconds
    // @param _challengePeriod duration of challenge period in seconds
    // @param _inputLog2Size size of the input drive in this machine
    // @param _feePerClaim fee per claim to reward the validators
    // @param _validators initial validator set
    // @param _erc20Contract specific ERC-20 contract address used by the portal
    // @param _erc20ForFee the ERC-20 used as rewards for validators
    // @dev validators have to be unique, if the same validator is added twice
    //      consensus will never be reached
    function init(
        // rollups contructor variables
        uint256 _inputDuration,
        uint256 _challengePeriod,
        // input constructor variables
        uint256 _inputLog2Size,
        // fee per claim to reward the validators
        uint256 _feePerClaim,
        // validator manager constructor variables
        address payable[] memory _validators,
        // specific ERC-20 portal constructor variables
        address _erc20Contract,
        // the ERC-20 used as rewards for validators
        address _erc20ForFee
    ) public override {
        LibRollupsInit.DiamondStorage storage rollupsInitDS =
            LibRollupsInit.diamondStorage();

        require(!rollupsInitDS.initialized, "Rollups already initialized");

        initInput(_inputLog2Size);
        initValidatorManager(_validators);
        initRollups(_inputDuration, _challengePeriod);
        initSERC20Portal(_erc20Contract);
        initFeeManager(_feePerClaim, _erc20ForFee);

        rollupsInitDS.initialized = true;

        emit RollupsInitialized(_inputDuration, _challengePeriod);
    }

    // @notice initalize the Input facet
    // @param _inputLog2Size size of the input drive in this machine
    function initInput(uint256 _inputLog2Size) private {
        LibInput.DiamondStorage storage inputDS = LibInput.diamondStorage();

        require(
            _inputLog2Size >= 3 && _inputLog2Size <= 64,
            "Log of input size: [3,64]"
        );

        inputDS.inputDriveSize = (1 << _inputLog2Size);
    }

    // @notice initialize the Validator Manager facet
    // @param _validators initial validator set
    function initValidatorManager(address payable[] memory _validators)
        private
    {
        LibValidatorManager.DiamondStorage storage vmDS =
            LibValidatorManager.diamondStorage();

        uint256 maxNumValidators = _validators.length;

        require(maxNumValidators <= 8, "up to 8 validators");

        vmDS.validators = _validators;
        vmDS.maxNumValidators = maxNumValidators;

        // create a new ClaimsMask, with only the consensus goal set,
        //      according to the number of validators
        vmDS.claimsMask = ClaimsMaskLibrary.newClaimsMaskWithConsensusGoalSet(
            maxNumValidators
        );
    }

    // @notice initialize the Rollups facet
    // @param _inputDuration duration of input accumulation phase in seconds
    // @param _challengePeriod duration of challenge period in seconds
    function initRollups(uint256 _inputDuration, uint256 _challengePeriod)
        private
    {
        LibRollups.DiamondStorage storage rollupsDS =
            LibRollups.diamondStorage();

        // Is this optimal?
        rollupsDS.inputDuration = uint32(_inputDuration);
        rollupsDS.challengePeriod = uint32(_challengePeriod);
        rollupsDS.inputAccumulationStart = uint32(block.timestamp);
        rollupsDS.currentPhase_int = uint32(Phase.InputAccumulation);
    }

    function initSERC20Portal(address _erc20Contract) private {
        LibSERC20Portal.DiamondStorage storage serc20DS =
            LibSERC20Portal.diamondStorage();

        serc20DS.erc20Contract = _erc20Contract;
    }

    // @notice initalize the Fee Manager facet
    // @param _feePerClaim fee per claim to reward the validators
    // @param _erc20ForFee the ERC-20 used as rewards for validators
    function initFeeManager(uint256 _feePerClaim, address _erc20ForFee) private {
        LibFeeManager.DiamondStorage storage feeManagerDS = LibFeeManager.diamondStorage();
        feeManagerDS.feePerClaim = _feePerClaim;
        feeManagerDS.token = IERC20(_erc20ForFee);
        emit FeeManagerInitialized(_feePerClaim, _erc20ForFee);
    }
}
