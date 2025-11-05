// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title Layer2ScalingSolution
 * @notice A conceptual smart contract simulating a Layer 2 scaling mechanism on Ethereum.
 * @dev This Layer 2 solution allows users to deposit assets on Layer 1, transact off-chain,
 *      and finalize their state securely with on-chain validation and fraud detection.
 *
 * Key Components:
 * - Deposit bridge (L1 → L2)
 * - Withdrawal requests (L2 → L1)
 * - Batch submission with verification
 * - Fraud-proof simulation for malicious batches
 * - Governance and upgrade hooks for admin
 *
 * NOTE: This is a conceptual prototype for educational and research purposes.
 */
contract Project {
    // ======================================================
    // Core Variables
    // ======================================================

    address public admin;
    uint256 public totalDeposits;
    uint256 public totalWithdrawals;
    uint256 public batchCount;
    bool public emergencyHalt;

    struct Deposit {
        uint256 id;
        address depositor;
        uint256 amount;
        uint256 timestamp;
        bool processed;
    }

    struct Withdrawal {
        uint256 id;
        address withdrawer;
        uint256 amount;
        uint256 timestamp;
        bool completed;
    }

    struct Batch {
        uint256 id;
        string stateRootHash;
        address proposer;
        uint256 timestamp;
        bool verified;
        bool challenged;
    }

    mapping(uint256 => Deposit) public deposits;
    mapping(uint256 => Withdrawal) public withdrawals;
    mapping(uint256 => Batch) public batches;

    mapping(address => uint256) public userBalances;

    uint256 private depositCounter;
    uint256 private withdrawalCounter;

    // ======================================================
    // Events
    // ======================================================

    event DepositInitiated(uint256 indexed id, address indexed depositor, uint256 amount);
    event WithdrawalRequested(uint256 indexed id, address indexed withdrawer, uint256 amount);
    event WithdrawalCompleted(uint256 indexed id, address indexed withdrawer, uint256 amount);
    event BatchSubmitted(uint256 indexed id, string stateRootHash, address indexed proposer);
    event BatchVerified(uint256 indexed id, address indexed verifier);
    event FraudDetected(uint256 indexed id, address indexed reporter);
    event EmergencyHaltActivated(address indexed by);
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);

    // ======================================================
    // Modifiers
    // ======================================================

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier notHalted() {
        require(!emergencyHalt, "System is halted");
        _;
    }

    // ======================================================
    // Constructor
    // ======================================================

    constructor() {
        admin = msg.sender;
    }

    // ======================================================
    // Layer 1 → Layer 2 Bridge (Deposits)
    // ======================================================

    /**
     * @notice Deposit funds to Layer 2 (simulated bridge).
     */
    function depositToL2() external payable notHalted {
        require(msg.value > 0, "Deposit amount must be greater than zero");

        depositCounter++;
        totalDeposits += msg.value;
        userBalances[msg.sender] += msg.value;

        deposits[depositCounter] = Deposit({
            id: depositCounter,
            depositor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            processed: false
        });

        emit DepositInitiated(depositCounter, msg.sender, msg.value);
    }

    // ======================================================
    // Layer 2 → Layer 1 Bridge (Withdrawals)
    // ======================================================

    /**
     * @notice Request withdrawal from Layer 2 back to Layer 1.
     * @param _amount The amount to withdraw.
     */
    function requestWithdrawal(uint256 _amount) external notHalted {
        require(userBalances[msg.sender] >= _amount, "Insufficient L2 balance");

        withdrawalCounter++;
        totalWithdrawals += _amount;
        userBalances[msg.sender] -= _amount;

        withdrawals[withdrawalCounter] = Withdrawal({
            id: withdrawalCounter,
            withdrawer: msg.sender,
            amount: _amount,
            timestamp: block.timestamp,
            completed: false
        });

        emit WithdrawalRequested(withdrawalCounter, msg.sender, _amount);
    }

    /**
     * @notice Finalize withdrawal after validation (simulated finality).
     * @param _withdrawalId The withdrawal request ID.
     */
    function finalizeWithdrawal(uint256 _withdrawalId) external notHalted {
        Withdrawal storage wd = withdrawals[_withdrawalId];
        require(!wd.completed, "Withdrawal already completed");

        wd.completed = true;
        payable(wd.withdrawer).transfer(wd.amount);

        emit WithdrawalCompleted(_withdrawalId, wd.withdrawer, wd.amount);
    }

    // ======================================================
    // Rollup Batch Submission & Verification
    // ======================================================

    /**
     * @notice Submit a new state batch representing aggregated Layer 2 transactions.
     * @param _stateRootHash The hash of the new L2 state root.
     */
    function submitBatch(string memory _stateRootHash) external notHalted {
        require(bytes(_stateRootHash).length > 0, "State root hash required");

        batchCount++;
        batches[batchCount] = Batch({
            id: batchCount,
            stateRootHash: _stateRootHash,
            proposer: msg.sender,
            timestamp: block.timestamp,
            verified: false,
            challenged: false
        });

        emit BatchSubmitted(batchCount, _stateRootHash, msg.sender);
    }

    /**
     * @notice Verify a batch after challenge window expires (simulated optimistic rollup).
     * @param _batchId ID of the batch to verify.
     */
    function verifyBatch(uint256 _batchId) external onlyAdmin notHalted {
        Batch storage b = batches[_batchId];
        require(!b.verified, "Batch already verified");
        require(!b.challenged, "Batch is under challenge");

        b.verified = true;
        emit BatchVerified(_batchId, msg.sender);
    }

    /**
     * @notice Report fraudulent activity in a submitted batch.
     * @param _batchId ID of the fraudulent batch.
     */
    function reportFraud(uint256 _batchId) external notHalted {
        Batch storage b = batches[_batchId];
        require(!b.verified, "Already verified batch");
        require(!b.challenged, "Batch already challenged");

        b.challenged = true;
        emergencyHalt = true;

        emit FraudDetected(_batchId, msg.sender);
        emit EmergencyHaltActivated(msg.sender);
    }

    // ======================================================
    // Governance & Admin Functions
    // ======================================================

    /**
     * @notice Change the admin address.
     * @param _newAdmin New admin address.
     */
    function changeAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Invalid admin address");
        emit AdminChanged(admin, _newAdmin);
        admin = _newAdmin;
    }

    /**
     * @notice Toggle system emergency halt manually.
     */
    function toggleEmergencyHalt(bool _state) external onlyAdmin {
        emergencyHalt = _state;
        if (_state) {
            emit EmergencyHaltActivated(msg.sender);
        }
    }

    /**
     * @notice Get system statistics summary.
     */
    function getSystemStats()
        external
        view
        returns (
            uint256 totalDeposited,
            uint256 totalWithdrawn,
            uint256 totalBatches,
            bool halted
        )
    {
        return (totalDeposits, totalWithdrawals, batchCount, emergencyHalt);
    }

    /**
     * @notice Get specific batch details.
     */
    function getBatch(uint256 _id)
        external
        view
        returns (
            string memory stateRoot,
            address proposer,
            bool verified,
            bool challenged
        )
    {
        Batch memory b = batches[_id];
        return (b.stateRootHash, b.proposer, b.verified, b.challenged);
    }
}
