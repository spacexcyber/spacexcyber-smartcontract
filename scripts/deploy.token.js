async function main() {
  // We get the contract to deploy
  const [owner, account1, account2] = await ethers.getSigners();
  const SpaceXCyberToken = await ethers.getContractFactory("SpaceXCyberToken");
  console.log("account1 address:", account1.address);
  console.log("account2 address:", account2.address);
  const spaceXCyberToken = await SpaceXCyberToken.deploy(account1.address, account2.address);
  // const spaceXCyberToken = await SpaceXCyberToken.deploy();
  await spaceXCyberToken.deployed();
  console.log("SpaceXCyberToken deployed to:", spaceXCyberToken.address);

  // const SpaceXCyberTokenTimelock = await ethers.getContractFactory("SpaceXCyberTokenTimelock");
  // console.log("Deploying SpaceXCyberTokenTimelock...");
  // const cpaceXCyberTokenTimelock = await SpaceXCyberTokenTimelock.deploy(spaceXCyberToken.address);
  // await cpaceXCyberTokenTimelock.deployed();
  // console.log("cpaceXCyberTokenTimelock deployed to:", cpaceXCyberTokenTimelock.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
