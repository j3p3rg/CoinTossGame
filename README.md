# CoinTossGame
A solidity smart contract for coin flipping, coin tossing, or heads or tails.

Secure Randomness: Chainlink VRF is used to ensure that the source of randomness is secure and verifiable, preventing manipulation.

Efficient Payouts: The bets are settled in a loop, but now there's a check to ensure only when randomness is fulfilled. This pattern ensures no external interaction during randomness retrieval.

Managing LINK tokens: The contract checks for sufficient LINK balance before accepting bets and provides a function for the owner to withdraw LINK.

Withdrawal functions: Separate functions for withdrawing ETH and LINK to manage different assets clearly.
State management: Using a requestInProgress flag to prevent reentrancy and ensure that only one randomness  request.

###############################################
Example for Setting Parameters in a Constructor
When you are ready to deploy your smart contract, you will typically set these parameters in the constructor or as immutable variables. Here’s an example of how you might write the constructor for your contract:


