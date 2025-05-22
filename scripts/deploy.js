const hre = require("hardhat");

async function main() {
  console.log("🚀 Deploying Layer 2 Scaling Solution to Core Testnet 2...");

  // Get the ContractFactory and Signers
  const [deployer] = await hre.ethers.getSigners();
  
  console.log("📝 Deploying contracts with the account:", deployer.address);
  
  // Get account balance
  const balance = await hre.ethers.provider.getBalance(deployer.address);
  console.log("💰 Account balance:", hre.ethers.formatEther(balance), "CORE");

  // Deploy the Layer2ScalingSolution contract
  console.log("\n⏳ Deploying Layer2ScalingSolution contract...");
  
  const Layer2ScalingSolution = await hre.ethers.getContractFactory("Layer2ScalingSolution");
  const layer2Contract = await Layer2ScalingSolution.deploy();
  
  await layer2Contract.waitForDeployment();
  
  const contractAddress = await layer2Contract.getAddress();
  console.log("✅ Layer2ScalingSolution deployed to:", contractAddress);

  // Display deployment summary
  console.log("\n📋 Deployment Summary:");
  console.log("=".repeat(50));
  console.log("Contract Name: Layer2ScalingSolution");
  console.log("Contract Address:", contractAddress);
  console.log("Network: Core Testnet 2");
  console.log("Deployer:", deployer.address);
  console.log("Challenge Period:", "1 day");
  
  // Verify contract if not on localhost
  if (hre.network.name !== "hardhat" && hre.network.name !== "localhost") {
    console.log("\n⏳ Waiting for block confirmations...");
    await layer2Contract.deploymentTransaction().wait(5);
    
    console.log("🔍 Verifying contract on Core Testnet 2 explorer...");
    try {
      await hre.run("verify:verify", {
        address: contractAddress,
        constructorArguments: [],
      });
      console.log("✅ Contract verified successfully!");
    } catch (error) {
      console.log("❌ Contract verification failed:", error.message);
    }
  }

  // Display usage instructions
  console.log("\n🎯 Next Steps:");
  console.log("1. Fund your wallet with Core testnet tokens");
  console.log("2. Interact with the contract using the following functions:");
  console.log("   - openChannel(participant2Address) - Open a new payment channel");
  console.log("   - updateChannelState(...) - Update channel state off-chain");
  console.log("   - closeChannel(channelId) - Close and settle the channel");
  console.log("3. Monitor events for channel activities");
  
  console.log("\n🌐 Core Testnet 2 Explorer:");
  console.log(`https://scan.test2.btcs.network/address/${contractAddress}`);
}

// Error handling
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });
