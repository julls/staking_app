const { ethers } = require("hardhat")

module.exports = async({getNamedAccounts, deployments}) => {
    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()
    // ethers.getContract did not work at all (wrong version?)
    const rewardToken = await ethers.getContractAt("RewardToken", "0x5FbDB2315678afecb367f032d93F642f64180aa3")

    const stakingDeployment = await deploy("Staking", {
        from: deployer,
        args: [rewardToken.address, rewardToken.address],
        log:true,
    })
}

module.exports.tags = ["all", "staking"]