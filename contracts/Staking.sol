// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

error Staking__TransferFailed();
error Unstake__TransferFailed();
error Staking__NeedsMoreThanZero();

contract Staking is ReentrancyGuard {
    IERC20 public _stakingToken;
    IERC20 public _rewardToken;

    uint256 public constant REWARD_RATE = 100;
    uint256 public constant SECONDS_IN_A_DAY = 86400;
    uint256 public _totalSupply;
    uint256 public _rewardPerTokenStored;
    uint256 public _lastUpdateTime;

    /** @dev Mapping from address to the amount the user has staked */
    mapping(address => uint256) public _balances;

    /** @dev Mapping from address to the rewards claimable for user */
    mapping(address => uint256) public _rewards;

    /** @dev Mapping from address to the amount the user has been rewarded */
    mapping(address => uint256) public _userRewardPerTokenPaid;

    modifier updateReward(address account) {
        _rewardPerTokenStored = rewardPerToken();
        _lastUpdateTime = block.timestamp;
        _rewards[account] = gained(account);
        _userRewardPerTokenPaid[account] = _rewardPerTokenStored;
        _;
    }

    modifier needMoreThanZero(uint256 amount) {
        if (amount == 0) {
            revert Staking__NeedsMoreThanZero();
        }
        _;
    }

    constructor(address stakingToken, address rewardToken) {
        _stakingToken = IERC20(stakingToken);
        _rewardToken = IERC20(rewardToken);
    }

    function gained(address account) public view returns (uint256) {
        uint256 currentBalance = _balances[account];
        // how much they were paid already
        uint256 amountPaid = _userRewardPerTokenPaid[account];
        uint256 currentRewardPerToken = rewardPerToken();
        uint256 pastRewards = _rewards[account];
        uint256 _earned = ((currentBalance * (currentRewardPerToken - amountPaid)) / SECONDS_IN_A_DAY) +
            pastRewards;

        return _earned;
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return _rewardPerTokenStored;
        } else {
            return
                _rewardPerTokenStored +
                (((block.timestamp - _lastUpdateTime) * REWARD_RATE * SECONDS_IN_A_DAY) / _totalSupply);
        }
    }

    function stake(uint256 amount) external updateReward(msg.sender) needMoreThanZero(amount) {
        _balances[msg.sender] += amount;
        _totalSupply += amount;
        //emit event for stake amount
        bool success = _stakingToken.transferFrom(msg.sender, address(this), amount);
        // require(success, "Failed"); Save gas fees
        if (!success) {
            revert Staking__TransferFailed();
        }
    }

    function unstake(uint256 amount) external updateReward(msg.sender) needMoreThanZero(amount) {
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;
        // emit event for unstake withdraw amount
        bool success = _stakingToken.transfer(msg.sender, amount);
        if (!success) {
            revert Unstake__TransferFailed();
        }
    }

    function claimReward() external updateReward(msg.sender) {
        uint256 reward = _rewards[msg.sender];
        bool success = _rewardToken.transfer(msg.sender, reward);
        if (!success) {
            revert Staking__TransferFailed();
        }
    }

    function getStake(address account) public view returns (uint256) {
        return _balances[account];
    }
}