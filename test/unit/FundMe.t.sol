// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract FundMeTest is Test {
    FundMe public fundMe;
    HelperConfig public helperConfig;

    address USER = makeAddr("user");
    uint256 SENDVALUE = 0.1 ether;
    uint256 STARTING_BALANCE = 10 ether;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        // we dating above line from deploy script
        DeployFundMe deployFundMe = new DeployFundMe();
        (fundMe, helperConfig) = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testFeedVesion() public {
        assertEq(fundMe.getVersion(), 4);
    }

    function testFundWithoutEnoghETH() public {
        vm.expectRevert();
        fundMe.fund{value: 0}();
    }

    function testUpdatesFundedDataStructure() public {
        vm.prank(USER);
        fundMe.fund{value: SENDVALUE}();
        uint256 expectedVlaueFunded = fundMe.getAddressToAmountFunded(address(USER));
        assertEq(expectedVlaueFunded, SENDVALUE);
    }

    function testAddFundersToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SENDVALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SENDVALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawalByOwnerFromASingleFunder() public funded {
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalace = fundMe.getOwner().balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;

        assertEq(endingFundMeBalance, 0);
        assert(startingFundMeBalance + startingOwnerBalace == endingOwnerBalance);
    }

    function testWithdrawalByOwnerFromMultipleFunder() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; // 0 address ,oght give error thats why
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.deal+sm.prank = vm.hoax
            hoax(address(i), STARTING_BALANCE);
            fundMe.fund{value: SENDVALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
        assert((numberOfFunders) * SENDVALUE == fundMe.getOwner().balance - startingOwnerBalance);
    }
}
