const {ethers, deployments} = require("hardhat")
const { moveBlocks } = require("../utils/move-blocks")
const { moveTime } = require("../utils/move-time")

const SECONDS_IN_DAY = 86400;
const SECONDS_IN_YEAR = 31536000;

describe("Staking Test", async function() {
    let staking, rewardToken, deployer, dai, stakeAmount

    beforeEach(async function () {
        const accounts = await ethers.getSigners()
        deployer = accounts[0]
        await deployments.fixture(["all"])
        rewardToken = await ethers.getContractAt("RewardToken", "0x5FbDB2315678afecb367f032d93F642f64180aa3")
        staking = await ethers.getContractAt("Staking", "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512")
        stakeAmount = ethers.utils.parseEther("100000")
    })

    it("Allows users to stake and claim rewards", async function () {
        await rewardToken.approve(staking.address, stakeAmount)
        await staking.stake(stakeAmount)
        const startingEarned = await staking.earned(deployer.address)
        console.log(`Earned ${startingEarned}`)

        await moveTime(SECONDS_IN_YEAR)
        await moveBlocks(1)
        const endingEarned = await staking.earned(deployer.address)
        console.log(`Earned ${endingEarned}`)
    })
})