// contracts/InterestCompounding.sol
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// Ideation from research paper (http://batog.info/papers/scalable-reward-distribution.pdf)
// This can be use for Deposit or Loan, this example show loan data
// This is Scalable Compounding Interest Calculation solution
// every action on borrowing, and repayment will compound the interest
// if no action is taken, admin/owner/anyone can call interestAccumulation to compound the interest
contract InterestCompound is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    // for stake, S0 or data that link to user (address)
    // u may use struct instead of separate variables
    // example:
    // struct Vault {
    //     address assetVault; // asset address
    //     uint256 collateral; // asset amount
    //     uint256 debt; // debt amount
    //     uint256 I0; // pointer of accumulated interest per dollar
    // }
    // which consist collateral and debt

    // total loan, included interest
    uint256 TotalLoan; 
    // interest counter, accumulated interest factor
    uint256 I;
    // timestamp on recording interest
    uint64 timestamp;
    // user's loan
    mapping (address => uint256) private debt;
    // user staking counter
    mapping (address => uint256) private I0;

    // u may just put annual interest
    uint256 private hourInterest;

    function initialize() public initializer {
        __Ownable_init();
        
        // 18 decimals
        hourInterest = 570833333333; // 0.005% apr
        I = 1000000000000000000;
        timestamp = uint64(block.timestamp);
    }

    /**
    * @dev apr in 8 decimal in number, or 6 decimal in percentage 
    */
    function getAPR() external view returns (uint256) {
        return hourInterest.mul(8760);
    }
    function setAPR(uint256 apr) external onlyOwner {
        // calculate all interest before apply new rate
        interestAccumulation();
        // apply new rate
        hourInterest = apr.div(8760);
    }

    function settlement(address user) internal {
        // settlement on particular user, set latest debt and interest value
        debt[user] = latestDebtAmount(user);
        interestAccumulation();
        I0[user] = I;
    }

    function latestDebtAmount(address user) internal view returns (uint256) {
        if (debt[user] == 0) return 0;
        if (block.timestamp > timestamp) {
            uint256 rate = hourInterest.mul(block.timestamp - timestamp).div(1 hours);
            uint256 newI = I.add(
                I.mul(rate).div(1e18)
            );
            return debt[user].mul(newI).div(I0[user]);
        }
        return debt[user].mul(I).div(I0[user]);
    }

    function interestAccumulation() public {
        // compounding happen here, where interest is added to principle
        if (TotalLoan >= 0 && block.timestamp > timestamp) {
            uint256 rate = hourInterest.mul(block.timestamp - timestamp).div(1 hours);
            uint256 interest = TotalLoan.mul(rate).div(1e18);
            I = I.add(
                I.mul(rate).div(1e18)
            );
            TotalLoan = TotalLoan.add(interest);
            timestamp = uint64(block.timestamp);
        }
    }

    function borrow(uint256 amount) external { //nonContract
        // if with collateral, here u should check collateral requirement
        // compoundingInterestAction, if any debt
        settlement(msg.sender);
        // record loan
        debt[msg.sender] = debt[msg.sender].add(amount);
        TotalLoan = TotalLoan.add(amount);
        // transfer/mint token and emit event
    }
    function repay(uint256 amount) external {
        // compoundingInterestAction
        settlement(msg.sender);
        uint256 debtAmount = latestDebtAmount(msg.sender);
        if (amount > debtAmount) {
            // pay debt only
            amount = debtAmount;
        }
        // transfer token
        // record loan
        debt[msg.sender] = debt[msg.sender].sub(amount);
        TotalLoan = TotalLoan.sub(amount);
        // emit event
    }
    function repayAll() external {
        // compoundingInterestAction
        settlement(msg.sender);
        uint256 debtAmount = latestDebtAmount(msg.sender);
        // transfer token
        // record loan
        debt[msg.sender] = 0;
        TotalLoan = TotalLoan.sub(debtAmount);
        // emit event
    }
}