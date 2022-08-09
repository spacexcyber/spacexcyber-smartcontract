// test/SpaceXCyberToken.Test.js
// Load dependencies
const { expect } = require("chai");

// Import utilities from Test Helpers
const { BN, expectEvent, expectRevert } = require("@openzeppelin/test-helpers");

// Load compiled artifacts
const SpaceXCyberToken = artifacts.require("SpaceXCyberToken");

// Start test block
contract("SpaceXCyberToken", function ([owner, other, people]) {
  beforeEach(async function () {
    this.spaceXCyberToken = await SpaceXCyberToken.new();
  });
  
  // Test case
  it("symbol returns SXC", async function () {
    expect(await this.spaceXCyberToken.symbol()).to.equal("SXC");
  });

  // Test case
  it("name returns SpaceXCyberToken", async function () {
    expect(await this.spaceXCyberToken.name()).to.equal("SpaceXCyberToken");
  });
  
  const totalSupply = new BN("100000000000000000000000000");
  // Test case
  it(`totalSupply address ${owner} returns 100_0000_000`, async function () {
    expect(await this.spaceXCyberToken.totalSupply()).to.be.bignumber.equal(
      totalSupply
    );
  });
 // Test case
 const amountOtherAddressInput = new BN("360000000000000000000000");
 it(`tranfer ${other} returns amount`, async function () {
   await this.spaceXCyberToken.transfer(other, amountOtherAddressInput);
   const amountOtherAddress = await this.spaceXCyberToken.balanceOf(other);
   expect(amountOtherAddress).to.be.bignumber.equal(amountOtherAddressInput);
 });
  // Test case
  it(`tranfer ${people} and check ${other} returns amount`, async function () {
    await this.spaceXCyberToken.transfer(people, amountOtherAddressInput);
    const amountOtherAddress = await this.spaceXCyberToken.balanceOf(other);
    expect(amountOtherAddress).to.be.bignumber.not.equal(amountOtherAddressInput);
  });
});
