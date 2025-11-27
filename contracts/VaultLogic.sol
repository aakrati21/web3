// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title VaultLogic
 * @dev Basic ETH vault using withdrawal (pull) pattern for safety
 * @notice Users deposit ETH and later withdraw their own balance
 */
contract VaultLogic {
    address public owner;

    // user => deposited balance
    mapping(address => uint256) public balances;

    uint256 public totalDeposits;
    uint256 public totalWithdrawn;

    event Deposited(address indexed user, uint256 amount, uint256 timestamp);
    event Withdrawn(address indexed user, uint256 amount, uint256 timestamp);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Deposit ETH into the vault
     */
    function deposit() external payable {
        require(msg.value > 0, "Amount = 0");

        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;

        emit Deposited(msg.sender, msg.value, block.timestamp);
    }

    /**
     * @dev Withdraw caller's available balance (full or partial)
     * @param amount Amount to withdraw
     */
    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount = 0");
        uint256 bal = balances[msg.sender];
        require(bal >= amount, "Insufficient balance");

        // effects first (withdrawal pattern)
        balances[msg.sender] = bal - amount;
        totalWithdrawn += amount;

        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        require(ok, "Transfer failed");

        emit Withdrawn(msg.sender, amount, block.timestamp);
    }

    /**
     * @dev Get contract ETH balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Transfer ownership of the vault contract
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        address prev = owner;
        owner = newOwner;
        emit OwnershipTransferred(prev, newOwner);
    }
}
