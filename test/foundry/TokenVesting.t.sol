// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/TokenVesting.sol";
import "../../src/Token.sol";

contract TokenVestingTest is Test {
    Token public token;
    TokenVesting public tokenVesting;
    address owner;
    address beneficiary;
    // here we can also use 10 month in soldity but i want to be very clear in seconds
    uint256 constant TEN_MONTH_IN_SEC = 26280000;
    uint256 constant THREE_MONTH_IN_SEC = 7884000;
    uint256 constant ONE_MONTH_IN_SEC = 2624016;
    uint256 constant amountToVest = 1000;
    uint256 startTime;

    function setUp() public {
        owner = address(this);
        beneficiary = address(0x123);
        token = new Token("Test Token", "TT", 1000000);
        tokenVesting = new TokenVesting(address(token));
        // user will be the current contract address
        token.transfer(address(tokenVesting), amountToVest);

        startTime = block.timestamp + 1;
        uint256 cliff = THREE_MONTH_IN_SEC;
        uint256 duration = TEN_MONTH_IN_SEC;
        uint256 slicePeriodSeconds = 1;
        bool revocable = true;
        uint256 amount = amountToVest;

        // tokens are being vested by the contract 
        tokenVesting.createVestingSchedule(beneficiary, startTime, cliff, duration, slicePeriodSeconds, revocable, amount);

    }

    // TODO: add tests
    function  testVestingBeforeCliff() public  {
        bytes32 vestingScheduleId = tokenVesting.computeVestingScheduleIdForAddressAndIndex(beneficiary,0);
        assertEq(tokenVesting.computeReleasableAmount(vestingScheduleId),0);
        // to check before cliff period 
        vm.warp(startTime + THREE_MONTH_IN_SEC - 1);
        assertEq(tokenVesting.computeReleasableAmount(vestingScheduleId), 0);
    }

    function  testVestingAtCliff() public  {
        bytes32 vestingScheduleId = tokenVesting.computeVestingScheduleIdForAddressAndIndex(beneficiary,0);
        // exact time of cliff
        vm.warp(startTime + THREE_MONTH_IN_SEC);
        // to check at cliff period 
        assertEq(tokenVesting.computeReleasableAmount(vestingScheduleId), 0);
    }

    function  testVestingAfterCliff() public  {
        bytes32 vestingScheduleId = tokenVesting.computeVestingScheduleIdForAddressAndIndex(beneficiary,0);
        vm.warp(startTime + THREE_MONTH_IN_SEC + 1);
        // 3.1*1000/10 = 310;
        uint256 expectedReleasedAmount = ((THREE_MONTH_IN_SEC + 1) * amountToVest ) / TEN_MONTH_IN_SEC;
        // just after the cliff period ends
        assertEq(tokenVesting.computeReleasableAmount(vestingScheduleId),expectedReleasedAmount);
        
    }

    function  testVestingAfterFourMnoths() public  {
        bytes32 vestingScheduleId = tokenVesting.computeVestingScheduleIdForAddressAndIndex(beneficiary,0);
        vm.warp(startTime + THREE_MONTH_IN_SEC + ONE_MONTH_IN_SEC);
        // (3+1)*1000/10 = 400;
        uint256 expectedReleasedAmount = ((THREE_MONTH_IN_SEC + ONE_MONTH_IN_SEC) * amountToVest) / TEN_MONTH_IN_SEC;
        // just after the cliff period ends
        assertEq(tokenVesting.computeReleasableAmount(vestingScheduleId),expectedReleasedAmount);
        
    }


}
