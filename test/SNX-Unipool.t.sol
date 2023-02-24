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
        rewardToken = new MyToken("Reward Test Token", "RTT", 0);
        stakedToken = new MyToken("Staked Test Token", "STT", 1000_000);
        unipool = new Unipool(address(rewardToken), address(stakedToken));
    }

    // VM Cheatcodes can be found in ./lib/forge-std/src/Vm.sol
    // Or at https://github.com/foundry-rs/forge-std
    function testStake() external {
        stakedToken.approve(address(unipool), stakedToken.balanceOf(address(this)));

        unipool.stake(1000*10**stakedToken.decimals());

        // // We can read slots directly
        // uint256 slot = stdstore.target(address(greeter)).sig(greeter.owner.selector).find();
        // assertEq(slot, 1);
        // bytes32 owner = vm.load(address(greeter), bytes32(slot));
        // assertEq(address(this), address(uint160(uint256(owner))));
    }
}
