// Copyright (C) 2020 Cartesi Pte. Ltd.

// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.

// This program is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
// PARTICULAR PURPOSE. See the GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// Note: This component currently has dependencies that are licensed under the GU
// GPL, version 3, and so you should treat this component as a whole as being under
// the GPL version 3. But all Cartesi-written code in this component is licensed
// under the Apache License, version 2, or a compatible permissive license, and can
// be used independently under the Apache v2 license. After this component is
// rewritten, the entire component will be released under the Apache v2 license.

import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { MockProvider } from "ethereum-waffle";
import { ethers } from "hardhat";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deployments } = hre;
    const { diamond } = deployments;
    const MINUTE = 60; // seconds in a minute
    const HOUR = 60 * MINUTE; // seconds in an hour
    const DAY = 24 * HOUR; // seconds in a day

    const INPUT_DURATION = 1 * DAY;
    const CHALLENGE_PERIOD = 7 * DAY;
    const INPUT_LOG2_SIZE = 7;

    let signers = await ethers.getSigners();

    const provider = new MockProvider();
    const wallets = provider.getWallets();
    var validators: string[] = [];

    // add all wallets as validators
    for (var wallet of wallets) {
        let address = await wallet.getAddress();
        validators.push(address);
    }

    // Bitmask
    const bitMaskLibrary = await deployments.deploy("Bitmask", {
        from: await signers[0].getAddress(),
    });
    const bitMaskAddress = bitMaskLibrary.address;

    // CartesiMath
    const cartesiMath = await deployments.deploy("CartesiMath", {
        from: await signers[0].getAddress(),
    });
    const cartesiMathAddress = cartesiMath.address;

    // Merkle
    const merkle = await deployments.deploy("Merkle", {
        from: await signers[0].getAddress(),
        libraries: {
            CartesiMath: cartesiMathAddress,
        },
    });
    const merkleAddress = merkle.address;

    // CartesiRollups
    const { address } = await diamond.deploy("CartesiRollupsDebug", {
        from: await signers[0].getAddress(),
        owner: await signers[0].getAddress(),
        facets: [
            'InputFacet',
            'RollupsFacet',
            'RollupsInitFacet',
            'ValidatorManagerFacet',
            'OutputFacet',
            // debug facets
            'RollupsDebugFacet',
            'OutputDebugFacet',
            'ValidatorManagerDebugFacet',
        ],
        libraries: {
            Bitmask: bitMaskAddress,
            Merkle: merkleAddress,
        },
        execute : {
            methodName: 'init',
            args: [
                INPUT_DURATION,
                CHALLENGE_PERIOD,
                INPUT_LOG2_SIZE,
                validators,
            ],
        },
    });

    console.log("Debug Diamond address: " + address);
//    let rollupsImpl = RollupsImpl__factory.connect(address, signers[0]);
//
//    let inputAddress = await rollupsImpl.getInputAddress();
//    let voucherAddress = await rollupsImpl.getVoucherAddress();
//
//    let erc20PortalImpl = await deployments.deploy("ERC20PortalImpl", {
//        from: await signers[0].getAddress(),
//        args: [inputAddress, voucherAddress],
//    });
//
//    let etherPortalImpl = await deployments.deploy("EtherPortalImpl", {
//        from: await signers[0].getAddress(),
//        args: [inputAddress, voucherAddress],
//    });
//
//    console.log("Rollups Impl address: " + rollupsImpl.address);
//    console.log(
//        "Rollups Impl getCurrentEpoch: " +
//            (await rollupsImpl.getCurrentEpoch())
//    );
//    console.log("Rollups accumulation start: " + await rollupsImpl.getInputAccumulationStart());
//    console.log("Input address " + inputAddress);
//    console.log("Voucher address " + voucherAddress);
//    console.log("Ether Portal address " + etherPortalImpl.address);
//    console.log("ERC20 Portal address " + erc20PortalImpl.address);
};

export default func;
export const tags = ["CartesiRollupsDebug"];