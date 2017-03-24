pragma solidity ^0.4.8;

import 'zeppelin/ownership/Ownable.sol';        // set specific function for owner only
import 'zeppelin/ownership/Contactable.sol';    // contract has contact info
import 'zeppelin/lifecycle/Killable.sol';       // contract may be killed
import 'zeppelin/SafeMath.sol';                 // safe mathematics functions
import ExampleToken;

contract HMLottery is Ownable, SafeMath, Contactable, Killable {

    // represents one bet made by a player
    struct bet {
        address player;             // the player that makes a bet
        uint tokensPlaced;             // the ammount of tokens the player placed for the bet
        uint8[4] numbers;           // the power ball numbers that the player selected
        uint16 ratioIndex;          // the index of the payout ratios list item, relevant for this bet
        uint timestamp;             // timestamp that this bet was made
    }

    // the agreed ratios in case of winning 1, 2, 3 or 4 balls
    struct ratio {
        uint16[4] numberRatios;     // multiples of payouts (based on 2 decimals)
        uint timestamp;             // timestamp that these payout ratios where set
    }

    // represents a roll
    struct roll {
        uint8[4] numbers;           // the power ball numbers generated based on the random seed
        string seed;                // the seed that was used
        uint totalWinnings;         // the grand total of all winners for this roll
        uint timestamp;             // timestamp that this roll was generated
    }

    // represents a win
    struct win {
        uint16 betIndex;            // the index of the bets list item, for the bet that won
        uint16 rollIndex;           // the index of the rolls list item
        bool paid;                  // has it been paid out yet?
    }

    public bet[] bets;                     // history of all bets done
    public uint16 nextBetIndex;            // the index for the first bet for the next roll

    public ratio[] ratios;                 // history of all set ratios

    public string[] hashedSeeds = ["list", "of", "seeds"];
    public uint16 nextHashedSeedIndex;     // index of the next hash to use to verify the seed for RND

    public roll[] rolls;                   // history of all rolls
    public win[] winners;                  // history of all wins
    private uint16 nextWinPayoutIndex;     // index of the next payout (from winners)

    public uint minBet;                    // the mimimum bet allowed
    public address token;                  // the address of the token being used for this lottery
    
    
    function HMLottery() {
        owner = msg.sender;         // set the owner of this contract to the creator of the contract
        minBet = 100;               // set the mimimum bet

        nextRatio.numberRatios = [3200, 819200, 209715200, 53687091200];    // at these payout ratios the game pays out 50% funds taken in (based on probibility)
        nextRatio.timestamp = now;  // timestamp
        ratios.push(nextRatio);     // set the payout ratio

        token = ExampleToken;       // set the token to be used for the lottery

        nextBetIndex = 0;           // initialize the list index
        nextHashedSeedIndex = 0;    // initialize the list index

        setContactInformation('Contact INFO'); // more info about this lottery
    }

    // sets the ratios that will be used to multiply winnings based on number of balls correct
    // !!! (based on 2 decimal precision [to select a multiple of 23.5 specify 2350])
    function setPayOutRatios(uint16 oneBall, uint16 twoBalls, uint16 threeBalls, uint16 fourBalls) external OnlyOwner {
        ratio nextRatio;

        nextRatio.numberRatios = [oneBall, twoBalls, threeBalls, fourBalls];
        nextRatio.timestamp = now;
        ratios.push(nextRatio);
    }

    function setMinBet(uint _minBet) external OnlyOwner {
        minBet = _minBet;
    }

    function changeToken(address _token) external OnlyOwner {
        // 1st we need to return all existing bets (because they will be in another token)
        // we need to check if there is enough tokens in reserve to pay these players back
        uint allBets = 0;
        for (var i = nextBetIndex; i < bets.length; i++) {
            allBets += bets[i].tokensPlaced;    
        }
        if (token.balances[this] < allBets) throw;
        // refund each player
        for (var i = nextBetIndex; i < bets.length; i++) {
            token.transfer(bets[i].player, bets[i].tokensPlaced)    
        }
        // remove those bets from the list
        bets.length = nextBetIndex;
        nextBetIndex--;

        // change the token
        token = _token;
    }

    function roll() external OnlyOwner {
        // 1st check if the last payout was done
    }

    function payOut external OnlyOwner {
        // 1st we need to check if there is enough tokens in reserve to pay these players back
        if (token.balances[this] < rolls[rolls.length].totalWinnings) throw;

        // payout each winner

        

    }

    //// PUBLIC interface

    function placeBet(uint16 _oneBall, uint16 _twoBall, uint16 _threeBall, uint16 _fourBall, uint _value) external {

        // 1st transfer the required tokens to this contract

        if (!token.transferFrom(msg.sender, this, _value)) throw;

        // tokens transfered so can now create a new bet
        bet newBet;
        newBet.player = msg.sender;
        newBet.tokensPlaced = _value;
        newBet.numbers = [_oneBall, _twoBall, _threeBall, _fourBall];
        newBet.ratioIndex = ratios.length - 1;
        newBet.timestamp = now;

        // place it into the bets list
        bets.push(newBet)
    }




    event PlayerWon(uint _value);

    event RollCompleted(uint8 oneBall, uint8 twoBall, uint8 threeBall, uint8 fourBall);