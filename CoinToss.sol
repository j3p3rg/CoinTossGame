// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract CoinTossGame is VRFConsumerBase {
    address public owner;
    uint256 public minimumBet;
    bytes32 public requestId;
    bool public requestInProgress;

    struct Bet {
        address bettor;
        uint256 amount;
        bool choice;
    }

    Bet[] public bets;

    // Chainlink VRF related variables
    bytes32 internal keyHash;
    uint256 internal fee;

    // Events to log game activity
    event BetPlaced(address indexed player, uint256 amount, bool choice);
    event BetSettled(address indexed player, bool result, bool won);
    event RandomnessRequested(bytes32 requestId);
    event RandomnessFulfilled(bytes32 requestId, bool result);

    // Modifier to restrict function calls to the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    constructor(
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash,
        uint256 _fee,
        uint256 _minimumBet
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        owner = msg.sender;
        keyHash = _keyHash;
        fee = _fee;
        minimumBet = _minimumBet;
    }

    function placeBet(bool _choice) public payable {
        require(msg.value >= minimumBet, "Bet does not meet the minimum requirement.");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        require(!requestInProgress, "Previous request processing, please wait.");

        bets.push(Bet({
            bettor: msg.sender,
            amount: msg.value,
            choice: _choice
        }));

        emit BetPlaced(msg.sender, msg.value, _choice);
    }

    function requestRandomness() public onlyOwner {
        require(!requestInProgress, "Request already in progress.");
        require(bets.length > 0, "No bets placed.");
        requestInProgress = true;
        requestId = requestRandomness(keyHash, fee);
        emit RandomnessRequested(requestId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
        require(requestInProgress, "Randomness not requested.");
        require(_requestId == requestId, "Request ID does not match.");
        requestInProgress = false;
        bool tossResult = _randomness % 2 == 0;
        emit RandomnessFulfilled(_requestId, tossResult);
        settleBets(tossResult);
    }

    function settleBets(bool tossResult) private {
        for (uint256 i = 0; i < bets.length; i++) {
            Bet storage bet = bets[i];
            if (bet.choice == tossResult) {
                uint256 prize = bet.amount * 2;
                payable(bet.bettor).transfer(prize);
                emit BetSettled(bet.bettor, tossResult, true);
            } else {
                emit BetSettled(bet.bettor, tossResult, false);
            }
        }
        delete bets; // Clears the array for the next round
    }

    function withdrawLink() external onlyOwner {
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Failed to transfer LINK");
    }

    function withdrawEth() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract has no ether.");
        (bool sent, ) = msg.sender.call{value: balance}("");
        require(sent, "Failed to send Ether");
    }
}
