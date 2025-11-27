// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title Layer2Scaling
 * @notice A simplified Layer 2 scaling solution for handling deposits, off-chain transactions, and withdrawals.
 */
contract Layer2Scaling {

    address public admin;
    uint256 public userCount;

    struct User {
        uint256 balance;          // L2 balance
        uint256 lastDeposit;      // Timestamp of last deposit
    }

    struct Transaction {
        uint256 from;
        uint256 to;
        uint256 amount;
        uint256 timestamp;
        bool processed;
    }

    mapping(address => User) public users;
    Transaction[] public transactions;

    event Deposit(address indexed user, uint256 amount, uint256 timestamp);
    event TransactionCreated(uint256 indexed txId, address indexed from, address indexed to, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount, uint256 timestamp);
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Layer2Scaling: NOT_ADMIN");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    /// @notice Deposit funds into L2
    function deposit() external payable {
        require(msg.value > 0, "Layer2Scaling: ZERO_DEPOSIT");

        User storage u = users[msg.sender];
        u.balance += msg.value;
        u.lastDeposit = block.timestamp;

        emit Deposit(msg.sender, msg.value, block.timestamp);
    }

    /// @notice Create an off-chain transaction
    function createTransaction(address to, uint256 amount) external {
        require(to != address(0), "Layer2Scaling: INVALID_RECIPIENT");
        require(users[msg.sender].balance >= amount, "Layer2Scaling: INSUFFICIENT_BALANCE");

        // Deduct balance immediately for L2 accounting
        users[msg.sender].balance -= amount;

        transactions.push(Transaction({
            from: uint256(uint160(msg.sender)),
            to: uint256(uint160(to)),
            amount: amount,
            timestamp: block.timestamp,
            processed: false
        }));

        emit TransactionCreated(transactions.length - 1, msg.sender, to, amount);
    }

    /// @notice Process a transaction (admin can batch process L2 -> L1 settlement)
    function processTransaction(uint256 txId) external onlyAdmin {
        require(txId < transactions.length, "Layer2Scaling: TX_NOT_FOUND");
        Transaction storage txData = transactions[txId];
        require(!txData.processed, "Layer2Scaling: ALREADY_PROCESSED");

        address to = address(uint160(txData.to));
        users[to].balance += txData.amount;
        txData.processed = true;
    }

    /// @notice Withdraw funds back to L1
    function withdraw(uint256 amount) external {
        User storage u = users[msg.sender];
        require(u.balance >= amount, "Layer2Scaling: INSUFFICIENT_BALANCE");

        u.balance -= amount;
        payable(msg.sender).transfer(amount);

        emit Withdrawal(msg.sender, amount, block.timestamp);
    }

    function changeAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Layer2Scaling: ZERO_ADMIN");
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }

    function getTransaction(uint256 txId) external view returns (Transaction memory) {
        require(txId < transactions.length, "Layer2Scaling: TX_NOT_FOUND");
        return transactions[txId];
    }

    function getUserBalance(address user) external view returns (uint256) {
        return users[user].balance;
    }

    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }
}
