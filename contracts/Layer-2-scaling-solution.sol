// SPDX-License-Identifier: mit 
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title Layer2Scaling
 * @dev A simplified state channel imp]]]lementation for off-chain transactions
 enables users to open payment channels, conduct off-chain transactions, and settle on-chain
 
contract Layer2ScalingSolution is ReentrancyGuard {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    struct Channel {
        address participant1;
        address participant2; 
        uint256 balance1;
        uint256 balance2;
        uint256 nonce;
        uint256 timeout;
        bool isActive;
        bool isDisputed;
    }

    struct StateUpdate {
        bytes32 channelId;
        uint256 balance1;
        uint256 balance2;
        uint256 nonce;
        bytes signature1;
 
    }

    mapping(bytes32 => Channel) public channels;
    mapping(bytes32 => StateUpdate) public latestStates;
    
    uint256 public constant CHALLENGE_PERIOD = 1 days;
    uint256 public totalChannels;
    
    event ChannelOpened(bytes32 indexed channelId, address indexed participant1, address indexed participant2, uint256 amount1, uint256 amount2);
    event ChannelClosed(bytes32 indexed channelId, uint256 finalBalance1, uint256 finalBalance2);
    event StateUpdated(bytes32 indexed channelId, uint256 nonce, uint256 balance1, uint256 balance2);
    event DisputeRaised(bytes32 indexed channelId, address indexed challenger);

    /**
     * @dev Opens a new payment channel between two participants
     * @param _participant2 Address of the second participant
     * @return channelId The unique identifier for the created channel
     */
    function openChannel(address _participant2) external payable nonReentrant returns (bytes32) {
        require(_participant2 != address(0), "Invalid participant address");
        require(_participant2 != msg.sender, "Cannot create channel with yourself");
        require(msg.value > 0, "Must deposit some funds");

        bytes32 channelId = keccak256(abi.encodePacked(msg.sender, _participant2, block.timestamp, totalChannels));
        
        channels[channelId] = Channel({
            participant1: msg.sender,
            participant2: _participant2,
            balance1: msg.value,
            balance2: 0,
            nonce: 0,
            timeout: 0,
            isActive: true,
            isDisputed: false
        });

        totalChannels++;
        
        emit ChannelOpened(channelId, msg.sender, _participant2, msg.value, 0);
        return channel
     * @dev Updates the channel state with signed transactions from both participants
     * @param _channelId The channel identifier
     * @param _balance1 New balance for participant1
     * @param _balance2 New balance for participant2
     * @param _nonce Transaction nonce (must be greater than current)
     * @param _signature1 Signature from participant1
     * @param _signature2 Signature from participant2
     */
    function updateChannelState(
        bytes32 _channelId,
        uint256 _balance1,
        uint256 _balance2,
        uint256 _nonce,
        bytes memory _signature1,
        bytes memory _signature2
    ) external {
        Channel storage channel = channels[_channelId];
        require(channel.isActive, "Channel is not active");
        require(!channel.isDisputed, "Channel is under dispute");
        require(_nonce > channel.nonce, "Invalid nonce");
        require(_balance1 + _balance2 == channel.balance1 + channel.balance2, "Balances don't match total");

        // Verify signatures
        bytes32 messageHash = keccak256(abi.encodePacked(_channelId, _balance1, _balance2, _nonce));
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        
        address signer1 = ethSignedMessageHash.recover(_signature1);
        address signer2 = ethSignedMessageHash.recover(_signature2);
        
        require(
            (signer1 == channel.participant1 && signer2 == channel.participant2) ||
            (signer1 == channel.participant2 && signer2 == channel.participant1),
            "Invalid signatures"
        );


        // Store latest state for potential disputes
        latestStates[_channelId] = StateUpdate({
            channelId: _channelId,
            balance1: _balance1,
            balance2: _balance2,
            nonce: _nonce,
            signature1: _signature1,
            signature2: _signature2
        });

        emit StateUpdated(_channelId, _nonce, _balance1, _balance2);
    }

    /**
     * @dev Closes a channel and distributes funds according to the latest agreed state
     * @param _channelId The channel identifier
     */
    function closeChannel(bytes32 _channelId) external nonReentrant {
        Channel storage channel = channels[_channelId];
        require(channel.isActive, "Channel is not active");
        require(
            msg.sender == channel.participant1 || msg.sender == channel.participant2,
            "Only participants can close channel"
        );

        // If channel is disputed, wait for challenge period
        if (channel.isDisputed) {
            require(block.timestamp >= channel.timeout, "Challenge period not over");
        }

    
        
        channel.isActive = false;
        channel.balance1 = 0;
        channel.balance2 = 0;

        // Transfer funds
        if (balance1 > 0) {
            payable(channel.participant1).transfer(balance1);
        }
        if (balance2 > 0) {
            payable(channel.participant2).transfer(balance2);
        }

        emit ChannelClosed(_channelId, balance1, balance2);
    }

    // Additional helper functions
    function getChannelInfo(bytes32 _channelId) external view returns (Channel memory) {
        return channels[_channelId];
    }

    function getLatestState(bytes32 _channelId) external view returns (StateUpdate memory) {
        return latestStates[_channelId];
    }

    // Dispute mechanism (simplified)
    function raiseDispute(bytes32 _channelId) external {
        Channel storage channel = channels[_channelId];
        require(channel.isActive, "Channel is not active");
        require(
            msg.sender == channel.participant1 || msg.sender == channel.participant2,
            "Only participants can raise dispute"
        );

        channel.isDisputed = true;
        channel.timeout = block.timestamp + CHALLENGE_PERIOD;

        emit DisputeRaised(_channelId, msg.sender);
    }

    receive() external payable {}
}





















