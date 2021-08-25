// contracts/Share.sol
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// Purely from the research paper (http://batog.info/papers/scalable-reward-distribution.pdf)
// Share staking with rewards distribution
// in this example, we will be having share "H2O" with "WMATIC" as rewards
// the rewards can be share (H2O) also, but this will be a non compounding staking  
contract Share is ERC20Upgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    // total stake, u may use balanceOf(this) instead of using another variable
    uint256 TotalStake; 
    // current staking counter
    uint256 S;
    // user stake
    mapping (address => uint256) public stake;
    // user staking counter
    mapping (address => uint256) private S0;

    ERC20Upgradeable public rewardToken;

    function initialize(address _rewardToken) public initializer {
        __Ownable_init();
        __ERC20_init("H2O", "H2O");
        // 1 million
        _mint(address(msg.sender), 1000000000000000000000000);
        
        TotalStake = 0;
        S = 1; // initialize, differentiate from default 0

        rewardToken = ERC20Upgradeable(_rewardToken);
    }

    function initializeSelfReward() public initializer {
        __Ownable_init();
        __ERC20_init("H2O", "H2O");
        // 1 million
        _mint(address(msg.sender), 1000000000000000000000000);
        
        TotalStake = 0;
        S = 1; // initialize, differentiate from default 0

        rewardToken = ERC20Upgradeable(this);
    }

    function stakeShare(uint256 amount) external {
        this.transferFrom(msg.sender, address(this), amount);
        if (stake[msg.sender] == 0) {
            S0[msg.sender] = S;
        } else {
            withdrawDistribution(msg.sender);
        }
        stake[msg.sender] = stake[msg.sender].add(amount);
        TotalStake = TotalStake.add(amount);
    }

    function distribute(uint256 distribution) external {
        // u might need to limit to onlyOwner or certain address to distribute rewards
        rewardToken.transferFrom(
            msg.sender, 
            address(this), 
            distribution
        );
        if (TotalStake != 0) {
            S = S.add(distribution.mul(1e18).div(TotalStake));
        } else {
            revert();
        }
    }

    function withdrawShare(uint256 amount) external {
        require(stake[msg.sender] >= amount, "Cannot withdraw more than amount staked");
        withdrawDistribution(msg.sender);
        stake[msg.sender] = stake[msg.sender].sub(amount);
        TotalStake = TotalStake.sub(amount);

        this.transfer(msg.sender, amount);
    }

    function withdrawDistribution() external {
        withdrawDistribution(msg.sender);
    }
    function withdrawDistribution(address recipient) internal {
        uint256 deposited = stake[recipient];
        uint256 distribution = deposited.mul(S.sub(S0[recipient])).div(1e18);
        S0[recipient] = S;

        rewardToken.transfer(recipient, distribution);
    }
    function rewardBalance(address recipient) external view returns(uint256) {
        uint256 deposited = stake[recipient];
        uint256 distribution = deposited.mul(S.sub(S0[recipient])).div(1e18);
        return distribution;
    }
}
