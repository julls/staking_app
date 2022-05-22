// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Staking__TransferFailed();
error Staking__NeedsMoreThanZero();

contract Staking {

    // use IERC20 directly instead of an address 
    // to have access to all the token's standards capabilities
    IERC20 public _stakingToken;
    IERC20 public _rewardToken;

    // mapping of how much rewards each address has 
    mapping(address => uint256) public _rewards;
    // user address -> amount staked
    mapping(address => uint256) public _balances;
    // mapping of how much each address has been paid
    mapping(address => uint256) public _userRewardPerTokenPaid;

    uint256 public constant REWARD_RATE = 100;
    uint256 public _totalSupply;
    uint256 public _lastUpdateTime;
    uint256 public _rewardPerTokenStaked;

    modifier updateReward(address account) {
        // how much reward per token?
        _rewardPerTokenStaked = rewardPerToken();
        _lastUpdateTime = block.timestamp;
        _rewards[account] = earned(account);
        _userRewardPerTokenPaid[account] = _rewardPerTokenStaked;
        _; // needed by all modifiers
    }

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert Staking__NeedsMoreThanZero();
        }
        _;
    }

    constructor(address stakingToken, address rewardToken) {
        _stakingToken = IERC20(stakingToken);
        _rewardToken = IERC20(rewardToken);
    }

    function earned(address account) public view returns (uint256) {
        uint256 currentBalance = _balances[account];
        // how much they have been paid already
        uint256 amountPaid = _userRewardPerTokenPaid[account];
        uint256 currentRewardPerToken = rewardPerToken();
        uint256 pastRewards = _rewards[account];

        uint256 earnedT = ((currentBalance * (currentRewardPerToken - amountPaid)) / 1e18) + pastRewards;
        return earnedT;
    }

    // based on how long it's been staked during this most recent snapshot
    function rewardPerToken() public view returns(uint256) {
        if (_totalSupply == 0) {
            return _rewardPerTokenStaked;
        }

        uint256 deltaTime = block.timestamp - _lastUpdateTime;
        return _rewardPerTokenStaked + deltaTime * REWARD_RATE * 1e18 / _totalSupply;
    }

    // do we allow any tokens? -> add another argument address token
    //      Chainlink stuff to convert prices between tokens.
    // or just a specific token? 
    function stake(uint256 amount) external updateReward(msg.sender) moreThanZero(amount) {
        // keep track of how much a user has staked
        _balances[msg.sender] += amount;

        // keep track of how much token we have total
        _totalSupply += amount;

        // transfer the tokens to this contract
        bool success = _stakingToken.transferFrom(msg.sender, address(this), amount);
        
        //require(success, "Failed"); // not too eficient gas-wise cuz of the string
        if (!success) {
            revert Staking__TransferFailed();
        }
    }

    function unstake(uint256 amount) external updateReward(msg.sender) moreThanZero(amount) {
        _balances[msg.sender] -= amount;
        _totalSupply += amount;
        bool success = _stakingToken.transfer(msg.sender, amount);
        //bool success = _stakingToken.transferFrom(address(this), msg.sender, amount); // the same thing
        if (!success) {
            revert Staking__TransferFailed();
        }
    }

    function claimRewards() external updateReward(msg.sender) {
        // how much reward do they get?
        // Most common approach:
        // The contract is going to emit X tokens per second
        // and distribute them to all token stakers
        // that means, the more staked, the less rewards for each user
        uint256 reward = _rewards[msg.sender];
        bool success = _rewardToken.transfer(msg.sender, reward);
        if (!success) {
            revert Staking__NeedsMoreThanZero();
        }
    }
}