// scripts/deploy_upgradeable_box.js
const { ethers, upgrades } = require("hardhat");

async function main() {
  const SpaceXCyberToken = await ethers.getContractFactory("SpaceXCyberToken");
  console.log("Deploying SpaceXCyberToken...");
  const spaceXCyberToken = await upgrades.deployProxy(SpaceXCyberToken);
  await spaceXCyberToken.deployed();
  console.log("SpaceXCyberToken deployed to:", spaceXCyberToken.address);
}

main();
