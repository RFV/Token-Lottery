# HMLottery
An Ethereum 4 Ball Lottery Smart Contract, written with Truffle, and that works with any ERC20 token.

This is a lottery smart contract that allows player to make a bet with a predetermined token, and player selects a set of 4 numbers (0-255). The draw will automatically detect all winners and if there are enough funds in the lottery contract it will pay out automatically. If not, the owner of the lottery must add more tokens and then run the `payOut` function.

Steps to deploy this Smart contract and setup:

 1. Upload the bytecode to create a new smart contract.
 2. Set the token that will be used for this lottery with `setToken`
 3. Make sure the payout ratios are correct by setting `setPayoutRatios`

The random generation mechanism is based a predetermined seed/hash. What this means is that the owner can not influence the random number generator, since the hash of the seed is uploaded onto the lottery before bets are made, and before the roll and random number generator can proceed, the actual seed of the hash must be given, which is then used for the random number generator to determine the 4 lucky numbers.

For the owner to generate a list of seed/hashes, run the code inside the `seed_gen.js` file.

Players may see the last roll results, which includes the seed that was used inside the `lastRoll` public struct variable.

The smart contract makes use of the following libraries: Safemath, Ownable, Contactable, Killable and ERC20 (for token protocols).

##Owner Only Functions

    setPayoutRatios(uint _number1, uint _number2, uint _number3, uint _number4)
    
    setMinimumBet(uint _minimumBet)

    setMaximumBet(uint _maximumBet)

    setToken(address _token)

    rollNumbers(string _seed, bytes32 _nextHashedSeed)

    payOut()
    
    drain()
    
    transferOwnership()
    
    setContactInformation()
    
    kill()
    

##Public Functions

    placeBet(uint8 _number1, uint8 _number2, uint8 _number3, uint8 _number4, uint _value) external returns (bool)


I hope you like.

![enter image description here](https://rfventer.github.io/images/RFV_grey_101.png)
