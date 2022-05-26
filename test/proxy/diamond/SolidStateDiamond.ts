import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { describeBehaviorOfSolidStateDiamond } from '@solidstate/spec';
import {
  SolidStateDiamond,
  SolidStateDiamondMock__factory,
} from '@solidstate/typechain-types';
import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('SolidStateDiamond', function () {
  let owner: SignerWithAddress;
  let getNomineeOwner: SignerWithAddress;
  let getNonOwner: SignerWithAddress;

  let instance: SolidStateDiamond;

  let facetCuts: any[] = [];

  before(async function () {
    [owner, getNomineeOwner, getNonOwner] = await ethers.getSigners();
  });

  beforeEach(async function () {
    const [deployer] = await ethers.getSigners();
    instance = await new SolidStateDiamondMock__factory(deployer).deploy();

    const facets = await instance.callStatic['facets()']();

    expect(facets).to.have.lengthOf(1);

    facetCuts[0] = {
      target: instance.address,
      action: 0,
      selectors: facets[0].selectors,
    };
  });

  describeBehaviorOfSolidStateDiamond({
    deploy: async () => instance as any,
    getOwner: async () => owner,
    getNomineeOwner: async () => getNomineeOwner,
    getNonOwner: async () => getNonOwner,
    facetCuts,
    fallbackAddress: ethers.constants.AddressZero,
  });
});
