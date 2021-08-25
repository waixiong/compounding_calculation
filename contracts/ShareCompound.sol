// contracts/ShareCompound.sol
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "hardhat/console.sol";

// Modify idea from the research paper (http://batog.info/papers/scalable-reward-distribution.pdf)
// Share staking with compounding distribution
// In this example, share "H2O" will be staked for receiving share (H2O) as rewards
// Rewards automatically stake with compounding effect
contract ShareCompound is ERC20Upgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    // total stake, u may use balanceOf(this) instead of using another variable
    uint256 TotalStake; 
    // current staking counter
    uint256 S;
    // user stake
    mapping (address => uint256) private stake;
    // user staking counter
    mapping (address => uint256) private S0;

    function initialize() public initializer {
        __Ownable_init();
        __ERC20_init("H2O", "H2O");
        // 1 million
        _mint(address(msg.sender), 1000000000000000000000000);
        
        TotalStake = 0;
        S = 1000000000000000000; // initialize, differentiate from default 0
    }

    function stakeShare(uint256 amount) external {
        this.transferFrom(msg.sender, address(this), amount);
        if (stake[msg.sender] == 0) {
            S0[msg.sender] = S;
        } else {
            settleDistribution(msg.sender);
        }
        stake[msg.sender] = stake[msg.sender].add(amount);
        TotalStake = TotalStake.add(amount);
    }

    function distribute(uint256 distribution) external {
        // u might need to limit to onlyOwner or certain address to distribute rewards
        this.transferFrom(msg.sender, address(this), distribution);
        if (TotalStake != 0) {
            S = S.add(
                S.mul(distribution).div(TotalStake)
            );
            TotalStake = TotalStake.add(distribution);
        } else {
            revert();
        }
    }

    function withdrawShare(uint256 amount) external {
        require(latestBalance(msg.sender) >= amount, "Cannot withdraw more than amount staked");
        settleDistribution(msg.sender);
        stake[msg.sender] = stake[msg.sender].sub(amount);
        TotalStake = TotalStake.sub(amount);

        this.transfer(msg.sender, amount);
    }

    function settleDistribution() external {
        settleDistribution(msg.sender);
    }
    function settleDistribution(address recipient) internal {
        stake[recipient] = latestBalance(recipient);
        S0[recipient] = S;
    }
    function latestBalance(address recipient) public view returns (uint256) {
        if (stake[recipient] == 0) return 0;
        return stake[recipient].mul(S).div(S0[recipient]);
    }
}