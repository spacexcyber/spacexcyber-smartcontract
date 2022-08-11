async function main() {
  // We get the contract to deploy
  const SpaceXCyberToken = await ethers.getContractFactory("SpaceXCyberToken");
  console.log("Deploying SpaceXCyberToken...");
  const spaceXCyberToken = await SpaceXCyberToken.deploy();
  await spaceXCyberToken.deployed();
  console.log("SpaceXCyberToken deployed to:", spaceXCyberToken.address);

  const SpaceXCyberTokenTimelock = await ethers.getContractFactory("SpaceXCyberTokenTimelock");
  console.log("Deploying SpaceXCyberTokenTimelock...");
  const cpaceXCyberTokenTimelock = await SpaceXCyberTokenTimelock.deploy(spaceXCyberToken.address);
  await cpaceXCyberTokenTimelock.deployed();
  console.log("cpaceXCyberTokenTimelock deployed to:", cpaceXCyberTokenTimelock.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
