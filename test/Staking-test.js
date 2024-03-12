const { ethers, deployments } = require("hardhat")

describe("Staking Test", async function () {
    let staking, rewardToken, deployer, stakeAmount

    beforeEach(async function () {
        const accounts = await ethers.getSigners()
        deployer = await accounts[0]

        await deployments.fixture(["rewardToken", "staking"]) 
        staking = await ethers.getContractFactory("Staking")
        rewardToken = await ethers.getContractFactory("RewardToken")
        stakeAmount = ethers.utils.parseEther("100000")

    })

    it("Should allow users to stake and claim rewards", async function () {
        await rewardToken.approve(staking.address, stakeAmount)
        await staking.stake(stakeAmount) // 100000 tokens
        const startingGained = await staking.gained(deployer.address)
        console.log(`Starting Earned ${startingGained} tokens`)

        const endingGained = await staking.gained(deployer.address)
        console.log(`Ending Earned ${endingGained} tokens`)
    })
})