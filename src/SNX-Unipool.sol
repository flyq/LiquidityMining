// src code: https://github.com/k06a/Unipool/commit/e4bdb0a978fd498a1480e3d1bc4b4c1682c74c12#diff-0d1e350796b5338e3c326be95f9a9ad147d4695746306a50a9fdccf8dbbfd708

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


contract Unipool is ERC20, ERC20Detailed("Unipool", "SNX-UNP", 18) {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 constant public REWARD_RATE = uint256(72000e18) / 7 days;
    IERC20 public snx = IERC20(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F);
    IERC20 public uni = IERC20(0xe9Cf7887b93150D4F2Da7dFc6D502B216438F244);

    // 
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;

    event Staked(address indexed user, uint256 amount);
    event Withdrawed(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    modifier updateRewardPerToken {
        getReward();
        _;
    }

    function rewardPerToken() public view returns(uint256) {
        return rewardPerTokenStored.add(
            totalSupply() == 0 ? 0 : (now.sub(lastUpdateTime)).mul(REWARD_RATE).mul(1e18).div(totalSupply())
        );
    }

    function earned(address account) public view returns(uint256) {
        return balanceOf(account).mul(
            rewardPerToken().sub(userRewardPerTokenPaid[account])
        ).div(1e18);
    }

    function stake(uint256 amount) public updateRewardPerToken {
        _mint(msg.sender, amount);
        uni.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public updateRewardPerToken {
        _burn(msg.sender, amount);
        uni.safeTransfer(msg.sender, amount);
        emit Withdrawed(msg.sender, amount);
    }

    function withdrawAll() public {
        withdraw(balanceOf(msg.sender));
    }

    function getReward() public {
        uint256 reward = earned(msg.sender);

        rewardPerTokenStored = rewardPerToken();
        userRewardPerTokenPaid[msg.sender] = rewardPerTokenStored;
        lastUpdateTime = now;

        if (reward > 0) {
            snx.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }
}