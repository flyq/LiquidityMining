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
        assertEq(rewardToken.balanceOf(address(unipool)), 1_000_000e18);
        assertEq(stakedToken.balanceOf(address(this)), 1_000_000e18);
        assertEq(unipool.totalSupply(), 0);

        address alice = vm.addr(1);
        address bob = vm.addr(2);

        stakedToken.transfer(alice, 1000e18);
        stakedToken.transfer(bob, 1000e18);

        emit log_string("alice staking......");

        vm.startPrank(alice);
        stakedToken.approve(address(unipool), 1000e18);
        unipool.stake(1000e18);
        vm.stopPrank();

        skip(7 days);

        emit log_string("7 days pass......");

        emit log_string("bob staking......");

        vm.startPrank(bob);
        stakedToken.approve(address(unipool), 1000e18);
        unipool.stake(1000e18);
        vm.stopPrank();


        skip(7 days);

        emit log_string("7 days pass......");


        emit log_string("alice and bob withdrawAll......");

        vm.startPrank(alice);
        unipool.withdrawAll();
        vm.stopPrank();

        vm.startPrank(bob);
        unipool.withdrawAll();
        vm.stopPrank();

        emit log_named_uint("alice's unipool token", unipool.balanceOf(alice));
        emit log_named_uint("alice's rewardToken", rewardToken.balanceOf(alice));
        emit log_named_uint("alice's stakedToken", stakedToken.balanceOf(alice));

        emit log_named_uint("bob's unipool token", unipool.balanceOf(bob));
        emit log_named_uint("bob's rewardToken", rewardToken.balanceOf(bob));
        emit log_named_uint("bob's stakedToken", stakedToken.balanceOf(bob));
    }
}
