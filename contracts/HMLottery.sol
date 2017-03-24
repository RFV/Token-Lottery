pragma solidity ^0.4.8;

import 'zeppelin/ownership/Ownable.sol';        // set specific function for owner only
import 'zeppelin/ownership/Contactable.sol';    // contract has contact info
import 'zeppelin/lifecycle/Killable.sol';       // contract may be killed
import 'zeppelin/SafeMath.sol';                 // safe mathematics functions
import 'zeppelin/token/ERC20.sol';              // ERC20 interface
import './ExampleToken.sol';

/// @title Hadi Morrow's Lottery
/// @author Riaan F Venter~ RFVenter~ msg@rfv.io
contract HMLottery is Ownable, SafeMath, Contactable, Killable {

    // represents one bet made by a player
    struct bet {
        address player;             // the player that makes a bet
        uint tokensPlaced;          // the amount of tokens the player placed for the bet
        uint8[4] numbers;           // the selected power numbers that the player selected
        uint ratioIndex;          // the index of the payout ratios list item, relevant for this bet
        uint timestamp;             // timestamp that this bet was made
        uint rollIndex;           // the index of the roll that this bet is for
        uint winAmount;             // initialized to -1, in the event of a win this will be the amount
    }

    // the set ratios in case of winning 1, 2, 3 or 4 correct numbers
    struct ratio {
        uint[4] numberRatios;     // multiples of payouts (based on 2 decimals)
        uint timestamp;             // timestamp that these payout ratios where set
    }

    // represents a roll
    struct roll {
        uint8[4] numbers;           // the winning numbers generated based on the random seed
        string seed;                // the seed that was used
        uint totalWinnings;         // the grand total of all winners for this roll
        uint timestamp;             // timestamp that this roll was generated
    }

    bet[] public bets;                     // history of all bets done
    uint public nextRollIndex;           // the index for the first bet for the next roll

    ratio[] public ratios;                 // history of all set ratios

    bytes32[] public hashedSeeds;           // list of hashes to prove that the seeds are pre-generated
    uint public nextHashedSeedIndex;     // index of the next hash to use to verify the seed for RND

    roll[] public rolls;                   // history of all rolls
    uint public nextPayoutIndex;         // index of the next payout (for winners)

    uint public minBet;                    // the minimum bet allowed
    address public tokenAddress;           // address of the token being used for this lottery
    
    
    function HMLottery() {
        owner = msg.sender;         // set the owner of this contract to the creator of the contract
        minBet = 100;               // set the mimimum bet
        ratio memory nextRatio;

        // at these payout ratios the game pays out 50% tokens taken in (based on probibility)
        nextRatio.numberRatios[0] = 3200;
        nextRatio.numberRatios[1] = 819200;
        nextRatio.numberRatios[2] = 209715200;
        nextRatio.numberRatios[3] = 53687091200;  
        nextRatio.timestamp = now;  // timestamp
        ratios.push(nextRatio);     // set the payout ratio

        //tokenAddress = address(ExampleToken);       // set the token to be used for the lottery

        nextRollIndex = 0;          // initialize the list index
        nextPayoutIndex = 0;        // initialize the list index

        // put one hash in for the next draw ("test")
        hashedSeeds.push(sha3('test'));
        nextHashedSeedIndex = 0;    // initialize the list index

        setContactInformation('Contact INFO'); // more info about this lottery
    }

    // sets the ratios that will be used to multiply winnings based on correct numbers
    // !!! (based on 2 decimal precision [to select a multiple of 23.5 specify 2350])
    function setPayOutRatios(uint _oneNum, uint _twoNums, uint _threeNums, uint _fourNums) external onlyOwner {
        ratio memory nextRatio;

        nextRatio.numberRatios = [_oneNum, _twoNums, _threeNums, _fourNums];
        nextRatio.timestamp = now;
        ratios.push(nextRatio);
    }

    function setMinBet(uint _minBet) external onlyOwner {
        minBet = _minBet;
    }

    function changeToken(address _token) external onlyOwner returns (bool) {     
        if (tokenAddress != 0) {
            // return all existing bets (because they will be in another token)
            ERC20 token = ERC20(tokenAddress);
            // calculate all current bets total
            uint allBets = 0;
            for (var i = nextRollIndex; i < bets.length; i++) {
                allBets += bets[i].tokensPlaced;    
            }
            // check if there is enough tokens in reserve to pay these players back
            if (token.balanceOf(this) < allBets) return false;
            // refund each player
            for (var j = nextRollIndex; j < bets.length; j++) {
                token.transfer(bets[j].player, bets[j].tokensPlaced); 
            }
            // remove those bets from the list
            bets.length = nextRollIndex;
        }
    
        // change the token
        tokenAddress = _token;
        return true;
    }

    function addHashedSeed(bytes32 _hash) external onlyOwner {
        hashedSeeds.push(_hash);
    }

    function rollNumbers(string _seed) external onlyOwner returns (bool) {
        // check if the last payout was done
        if (nextRollIndex != nextPayoutIndex) return false;

        // make sure the given seed is correct for the next seedHash
        if (hashedSeeds[nextHashedSeedIndex] != sha3(_seed)) return false;

        // create the random number based on seed
        bytes20 combinedRand = ripemd160(_seed);
       
        uint8[4] memory numbers; 
        uint8 i = 0;
        while (i < 4) {
            numbers[i] = uint8(combinedRand);      // same as '= combinedRand % 256;'
            combinedRand >>= 8;                    // same as combinedRand /= 256;
            for (uint8 j = 0; j <= i; j++) {       // is newly picked val in a set?
                if (numbers[j] == numbers[i]) {    // if true then break to while loop and look for another Num[i]
                    i--;
                    break;
                }
            }
            i++;
        }
        // check all bets to see who won and how much, tally up the grand total
        uint totalWinnings = 0;

        for (uint b = nextRollIndex; b < bets.length; b++) {
            uint8 correctNumbers = 0;
            for (uint8 k = 0; k < 4; k++) {
                for (uint8 l = 0; l < 4; l++) {
                    if (bets[b].numbers[k] == numbers[l]) correctNumbers++;
                }
            }
            if (correctNumbers > 0) {
                bets[b].winAmount = bets[b].tokensPlaced * ratios[bets[b].ratioIndex].numberRatios[correctNumbers - 1];
                totalWinnings += bets[b].winAmount;
            }
            else bets[b].winAmount = 0;
        }

        // add a new roll with the numbers
        roll memory newRoll = roll(numbers, _seed, totalWinnings, now);
        rolls.push(newRoll);

        // move the nextRollIndex to end of the bets list
        nextRollIndex = bets.length;
    }

    function payOut() external onlyOwner returns (bool) {
        ERC20 token = ERC20(tokenAddress);

        // check if the last payout was done
        if (nextRollIndex == nextPayoutIndex) return false;

        // check if there is enough tokens in reserve to pay these players back
        if (token.balanceOf(this) < rolls[rolls.length].totalWinnings) return false;

        // payout each winner
        for (uint p = nextPayoutIndex; p < nextRollIndex; p++) {
            if (bets[p].winAmount > 0) {
                token.transfer(bets[p].player, bets[p].winAmount);
                nextPayoutIndex++;                                  // move the nextPayoutIndex on
            }
        }
    }

    //// PUBLIC interface

    function placeBet(uint8 _numOne, uint8 _numTwo, uint8 _numThree, uint8 _numFour, uint _value) external returns (int) {

        ERC20 token = ERC20(tokenAddress);

        // make sure that make sure that all numbers are different from each other!
        if (_numOne == _numTwo || _numOne == _numThree || _numOne == _numFour ||
            _numTwo == _numThree || _numTwo == _numFour ||
            _numThree == _numFour) return -1;

        // transfer the required tokens to this contract
        if (!token.transferFrom(msg.sender, this, _value)) return -1;

        // tokens transfered so can now create a new bet
        bet memory newBet;
        newBet.player = msg.sender;
        newBet.tokensPlaced = _value;
        newBet.numbers = [_numOne, _numTwo, _numThree, _numFour];
        newBet.ratioIndex = ratios.length - 1;
        newBet.timestamp = now;

        // place it into the bets list
        bets.push(newBet);

        return int(bets.length);
    }


    event PlayerWon(uint _value);

    event RollCompleted(uint8 _numOne, uint8 _numTwo, uint8 _numThree, uint8 _numFour);
}