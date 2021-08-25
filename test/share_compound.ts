const { expect } = require("chai");
const { BigNumber } = require("ethers");

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers, upgrades } from "hardhat";

describe("Share Compound test", function() {
  // before(async function () {
  //   this.Box = await ethers.getContractFactory('Box');
  // });

  // beforeEach(async function () {
  //   this.box = await this.Box.deploy();
  //   await this.box.deployed();
  // });

  it("share compounding", async function() {
    const Contract = await ethers.getContractFactory("ShareCompound");
    // const greeter = await Greeter.deploy();
    const contract = await upgrades.deployProxy(Contract, []);
    await contract.deployed();

    let addrs: SignerWithAddress[] = await ethers.getSigners(); 

    // presend amount, and approve
    var tx = await contract.connect(addrs[0])["approve(address,uint256)"](contract.address, 10000000000);
    await tx.wait();
    var tx = await contract.connect(addrs[1])["approve(address,uint256)"](contract.address, 10000000000);
    await tx.wait();
    var tx = await contract.connect(addrs[2])["approve(address,uint256)"](contract.address, 10000000000);
    await tx.wait();
    var tx = await contract.connect(addrs[3])["approve(address,uint256)"](contract.address, 10000000000);
    await tx.wait();
    var tx = await contract.connect(addrs[0])["transfer(address,uint256)"](addrs[1].address, 10000);
    await tx.wait();
    var tx = await contract.connect(addrs[0])["transfer(address,uint256)"](addrs[2].address, 10000);
    await tx.wait();
    var tx = await contract.connect(addrs[0])["transfer(address,uint256)"](addrs[3].address, 10000);
    await tx.wait();

    // start with no staking amount
    var balance1 = await contract.connect(addrs[1])["latestBalance(address)"](addrs[1].address);
    expect(balance1).to.equal(0);

    // user1 and user2 staking 8000 and 2000 respectively
    var tx = await contract.connect(addrs[1])["stakeShare(uint256)"](8000);
    await tx.wait();
    var tx = await contract.connect(addrs[2])["stakeShare(uint256)"](2000);
    await tx.wait();

    // check balance if update
    var balance1 = await contract.connect(addrs[1])["latestBalance(address)"](addrs[1].address);
    expect(balance1).to.equal(8000);

    // distribution
    var tx = await contract.connect(addrs[0])["distribute(uint256)"](1000);
    await tx.wait();

    // check if both balance added with distribution
    var balance0 = await contract.connect(addrs[1])["latestBalance(address)"](addrs[1].address);
    expect(balance0).to.equal(8800);
    var balance1 = await contract.connect(addrs[2])["latestBalance(address)"](addrs[2].address);
    expect(balance1).to.equal(2200);
    
    // withdraw
    var tx = await contract.connect(addrs[1])["withdrawShare(uint256)"](4000);
    await tx.wait();

    // user3 stake
    var tx = await contract.connect(addrs[3])["stakeShare(uint256)"](4000);
    await tx.wait();

    // 2nd distribution
    var tx = await contract["distribute(uint256)"](1100);
    await tx.wait();

    // check all balance after distribution
    var balance0 = await contract.connect(addrs[1])["latestBalance(address)"](addrs[1].address);
    expect(balance0).to.equal(5280);
    var balance1 = await contract.connect(addrs[2])["latestBalance(address)"](addrs[2].address);
    expect(balance1).to.equal(2420);
    var balance2 = await contract.connect(addrs[3])["latestBalance(address)"](addrs[3].address);
    expect(balance2).to.equal(4400);
  });
});
