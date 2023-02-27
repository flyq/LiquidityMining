// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "src/MyToken.sol";


import {Unipool} from "src/SNX-Unipool.sol";

contract UnipoolTest is Test {
    using stdStorage for StdStorage;

    Unipool unipool;
    MyToken rewardToken;
    MyToken stakedToken;

    function setUp() external {
        rewardToken = new MyToken("Reward Test Token", "RTT", 1000_000);
        stakedToken = new MyToken("Staked Test Token", "STT", 1000_000);
        unipool = new Unipool(address(rewardToken), address(stakedToken));
        rewardToken.transfer(address(unipool), 1000_000*10**stakedToken.decimals());
    }

    // VM Cheatcodes can be found in ./lib/forge-std/src/Vm.sol
    // Or at https://github.com/foundry-rs/forge-std
    function testStake() external {
        emit log_uint(unipool.balanceOf(address(this)));
        emit log_uint(rewardToken.balanceOf(address(this)));
        emit log_uint(stakedToken.balanceOf(address(this)));

        stakedToken.approve(address(unipool), stakedToken.balanceOf(address(this)));

        unipool.stake(1000*10**stakedToken.decimals());

        emit log_uint(stakedToken.balanceOf(address(this)));

        skip(7 days);
        emit log_uint(unipool.earned(address(this)));
        unipool.withdraw(1000*10**stakedToken.decimals());

        emit log_uint(unipool.balanceOf(address(this)));
        emit log_uint(rewardToken.balanceOf(address(this)));
        emit log_uint(stakedToken.balanceOf(address(this)));
    }
}
