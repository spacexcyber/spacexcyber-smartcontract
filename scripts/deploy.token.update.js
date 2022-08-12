// scripts/deploy_upgradeable_box.js
const { ethers, upgrades } = require('hardhat');

async function main () {
  const SpaceXCyberToken = await ethers.getContractFactory('SpaceXCyberToken');
  console.log('Deploying SpaceXCyberToken...');
  const box = await upgrades.deployProxy(SpaceXCyberToken, { initializer: 'addLiquidityETH' });
  await box.deployed();
  console.log('Box deployed to:', box.address);
}

main();