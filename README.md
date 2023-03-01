# LiquidityMining • [![tests](https://github.com/flyq/LiquidityMining/actions/workflows/ci.yml/badge.svg?label=tests)](https://github.com/flyq/LiquidityMining/actions/workflows/ci.yml) ![license](https://img.shields.io/github/license/flyq/LiquidityMining?label=license) ![solidity](https://img.shields.io/badge/solidity-^0.8.17-lightgrey)

Deep dive Liquidity Mining


## Usage

**Building & Testing**
```sh
forge install

forge build

forge test -vvv
```


## analysis

### SNX-Unipool
**overview**
Three tokens are involved:
- staked token, here is `uni-seth`. Users stake this token to unipool contract to get the reward.
- wrapped staked token, here is `SNX-UNP`. It is implemented through the unipool contract, and its quantity and distribution are determined entirely by `uni-seth` staked on the unipool address.
-  reward token, here is `snx`.

The reward rate is determined according to this parameter:   
`    uint256 constant public REWARD_RATE = uint256(72000e18) / 7 days;`   
This doesn't mean that the rewards only last for 7 days, in fact the rewards don't have any time limit.

`REWARD_RATE` indicates that the reward is uniform on the time scale, that is, after the reward starts (totalSupply of wrapped staked token is not 0), if any two time periods $\delta t_1 == \delta t_2$, then the total reward distribution during these periods Are the same.


We divide the time into $t_0$ to $t_N$ according to the moment when different users change the unipool contract state (calling stake, withdraw, withdrawAll, getReward) in a period of time.



$$
Reward_u = \sum_{i=0}^{N} \frac{Balance_{ui}}{TotalSupply_i} \times RATE \times t_i
$$


* $Reward_u$ is somebody(user)'s total reward
* $Balance_{ui}$ is somebody(user)'s `SNX_UNP` balance in $t_i$
* $TotalSupply_i$ is `SNX_UNP`'s TotalSupply

When the user changes his balance (stake, withdraw, withdrawAll), the contract settles his reward(executing getReward). So the $Balance_{ui}$ will not be changed between these two actions(from $t_m$ to $t_n$) by the user:

$$
Reward_u =Balance_{u} \times \sum_{i=m}^{n} \frac{RATE \times t_i}{TotalSupply_i}
$$

where $\sum_{i=m}^{n} \frac{RATE \times t_i}{TotalSupply_i}$ is how `rewardPerToken()` and `rewardPerTokenStored` works:
```solidity
    function rewardPerToken() public view returns(uint256) {
        return rewardPerTokenStored.add(
            totalSupply() == 0 ? 0 : (block.timestamp.sub(lastUpdateTime)).mul(REWARD_RATE).mul(1e18).div(totalSupply())
        );
    }

    ...

    rewardPerTokenStored = rewardPerToken();

```

But there is a problem, `rewardPerToken()` and `rewardPerTokenStored` are counted from the first user. If you only calculate the reward for the first user, you can use `rewardPerTokenStored` directly. If we need to calculate the users later, we need to use a state variable to store which are the previously accumulated `rewardPerTokenStored` when he stakes. This is where `userRewardPerTokenPaid` comes in:

```solidity
    mapping(address => uint256) public userRewardPerTokenPaid;

    userRewardPerTokenPaid[msg.sender] = rewardPerTokenStored;

```

Then, when calculating the payoff, we need to subtract this part:
```
    function earned(address account) public view returns(uint256) {
        return balanceOf(account).mul(
            rewardPerToken().sub(userRewardPerTokenPaid[account])
        ).div(1e18);
    }
```





**test process**

test code in [test/SNX-Unipool.t.sol](./test/SNX-Unipool.t.sol)

According to [foundry](https://book.getfoundry.sh/)'s settings, the address of the test contract is `0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496`

In `setUp()` function, we deployed:
- `staked token`, totalSupply is `1_000_000*e18`, and `balanceOf[test contract] = totalSupply`
- `wrapped staked token(unipool)`, totalSupply is 0, and is mintable
- `reward token`, totalSupply is `1_000_000*e18`, after transfering, `balanceOf[unipool] = totalSupply`, so that the unipool contract can distribute reward tokens directly.
  

In `testStake` function, there are 2 users, Alice and Bob. The test contract transfers 1000 `staked token` to Alice and Bob respectively.
1. Alice call `staked token`'s `approve()` to allow unipool transfer her staked tokens.
2. Alice call `unipool`'s `stake()`.
3. After 7 days, Alice earned 72000e18 `reward token`.
4. Bob call `staked token`'s `approve()` to allow unipool transfer his staked tokens.
5. Bob call `unipool`'s `stake()`.
6. After 7 days, Alice earned new 36000e18 `reward token`, and total 108000e18 token, Bob earned 36000e18 token.

**result**
```sh
forge test -m Stake -vvv   
[⠒] Compiling...
No files changed, compilation skipped

Running 1 test for test/SNX-Unipool.t.sol:UnipoolTest
[PASS] testStake() (gas: 389656)
Logs:
  alice staking......
  7 days pass......
  bob staking......
  7 days pass......
  alice and bob withdrawAll......
  alice's unipool token: 0
  alice's rewardToken: 107999999999999999437000
  alice's stakedToken: 1000000000000000000000
  bob's unipool token: 0
  bob's rewardToken: 35999999999999999812000
  bob's stakedToken: 1000000000000000000000

Test result: ok. 1 passed; 0 failed; finished in 1.08ms
```



## Notable Mentions

- [Liquidity Mining on Uniswap v3](https://www.paradigm.xyz/2021/05/liquidity-mining-on-uniswap-v3)
- [Scalable Reward Distribution on the Ethereum Blockchain](https://uploads-ssl.webflow.com/5ad71ffeb79acc67c8bcdaba/5ad8d1193a40977462982470_scalable-reward-distribution-paper.pdf)

## Disclaimer

_These smart contracts are being provided as is. No guarantee, representation or warranty is being made, express or implied, as to the safety or correctness of the user interface or the smart contracts. They have not been audited and as such there can be no assurance they will work as intended, and users may experience delays, failures, errors, omissions, loss of transmitted information or loss of funds. The creators are not liable for any of the foregoing. Users should proceed with caution and use at their own risk._

See [LICENSE](./LICENSE) for more details.
