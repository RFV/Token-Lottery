var HMLottery = artifacts.require("./HMLottery.sol");
var ExampleToken = artifacts.require("./ExampleToken.sol");

contract('HMLottery', accounts => {
  it("should have some variables setup from the initialization", () => {
    var lottery;
    var lotteryMin;
    var lotteryMax;
    var lotteryHashedSeed;

    return HMLottery.deployed().then(instance => {
      lottery = instance;

      return lottery.minimumBet.call();
    }).then(minBet => {
      lotteryMin = minBet.toNumber();
      return lottery.maximumBet.call();
    }).then(maxBet => {
      lotteryMax = maxBet.toNumber();
      return lottery.hashedSeeds(0);
    }).then(hashedSeed => {
      lotteryHashedSeed = hashedSeed.toString();
    }).then(() => {
      assert.equal(lotteryMin, 100, "Minimum bet should be 100");
      assert.equal(lotteryMax, 500, "Maximum bet should be 500");
      assert.equal(lotteryHashedSeed,
                   "0xd126d9ba76874eeae0e9706d1303194952377059e8d72424b4da996c0d4e0c7f", 
                   "Should be the same");
    });
  });
  it("none of these bets should go through", () => {
    var lottery;

    return HMLottery.deployed().then(instance => {
      lottery = instance;

      return lottery.placeBet(1, 2, 3, 4, 50);  // ammount too low
    }).then(() => {
      return lottery.placeBet(1, 2, 3, 4, 550); // ammount too high
    }).then(() => {
      return lottery.placeBet(1, 1, 3, 4, 150); // all balls are not unique
    }).then(() => {
      return lottery.testBetsLength.call();
    }).then(testBetsLength => {
      assert.equal(0, testBetsLength, "There should be no bets in the list");
    });
  });
  it("all of these bets should go through", () => {
    var lottery;
    var token;
    var playerTokens;
    var lotteryTokens;

    return HMLottery.deployed().then(instance => {
      lottery = instance;
      return ExampleToken.deployed();
    }).then(instance => {
      token = instance;

      // give the second user account some tokens to be able to gamble
      return token.transfer(accounts[1], 10000);
    }).then(() => {
      // give the lottery contract permission to spend second users tokens
      return token.approve(lottery.address, 10000, {from: accounts[1]});
    }).then(() => {
      return lottery.setToken(token.address);
    }).then(() => {
      return lottery.placeBet(1, 2, 3, 4, 150, {from: accounts[1]});
    }).then(() => {
      return token.balanceOf.call(accounts[1]);
    }).then(balance => {
      playerTokens = balance.toNumber();
      return token.balanceOf.call(lottery.address);
    }).then(balance => {
      lotteryTokens = balance.toNumber();
      return lottery.testBetsLength.call();
    }).then(testBetsLength => {
      assert.equal(1, testBetsLength, "There should be one bet in the list");
      assert.equal(10000 - 150, playerTokens, "Player should have 150 less tokens now")
      assert.equal(150, lotteryTokens, "Lottery should have 150 tokens now")
    }).then(() => {
      return lottery.placeBet(255, 254, 253, 252, 250, {from: accounts[1]});
    }).then(() => {
      return token.balanceOf.call(accounts[1]);
    }).then(balance => {
      playerTokens = balance.toNumber();
      return token.balanceOf.call(lottery.address);
    }).then(balance => {
      lotteryTokens = balance.toNumber();
      return lottery.testBetsLength.call();
    }).then(testBetsLength => {
      assert.equal(2, testBetsLength, "There should be two bets in the list");
      assert.equal(10000 - 150 - 250, playerTokens, "Player should have less tokens now")
      assert.equal(150 + 250, lotteryTokens, "Lottery should have 400 tokens now")
      return lottery.testReturnBet.call(0);
    }).then((bet) => {
      assert.equal(accounts[1], bet[0], "player should be account[1]");
      assert.equal(150, bet[1], "1st bet should have 150");
      assert.equal(1, bet[2], "number 1");
      assert.equal(2, bet[3], "number 2");
      assert.equal(3, bet[4], "number 3");
      assert.equal(4, bet[5], "number 4");
      assert.equal(0, bet[6], "ratioIndex should be the 1st one (0)");
      assert.equal(0, bet[8], "rollIndex should be the 1st one (0)");
      assert.equal(0, bet[9], "winAmmount should be 0");
      return lottery.testReturnBet.call(1);
    }).then((bet) => {
      assert.equal(accounts[1], bet[0], "player should be account[1]");
      assert.equal(250, bet[1], "2nd bet should have 250");
      assert.equal(255, bet[2], "number 1");
      assert.equal(254, bet[3], "number 2");
      assert.equal(253, bet[4], "number 3");
      assert.equal(252, bet[5], "number 4");
      assert.equal(0, bet[6], "ratioIndex should be the 1st one (0)");
      assert.equal(0, bet[8], "rollIndex should be the 1st one (0)");
      assert.equal(0, bet[9], "winAmmount should be 0");
      console.log("hello");
    });
  });
  it("rollNumbers twice and print out the combinations to console of 1st roll", () => {
    var lottery;
    var nextRollIndex;

    return HMLottery.deployed().then(instance => {
      lottery = instance;
      return lottery.nextRollIndex.call();
    }).then(rollI => {
      nextRollIndex = rollI;
      return lottery.nextPayoutIndex.call();
    }).then(payI => {
      assert.equal(payI.toNumber(), nextRollIndex.toNumber(), "There should both be 0");
      return lottery.rollNumbers.call("0xadb8780a5b2e5c04935b7e63fd6946432ea59fdc5fe79e52755c0a728f99b16b",
                                 0x5181c08ca7caf86f6c2fba1ce9819db67a0f6697196fe6f17a5a22bd7631a4d8);
    }).then(success => {
      assert.isTrue(success, "This call should be sucessful");
      return lottery.rollNumbers("0xadb8780a5b2e5c04935b7e63fd6946432ea59fdc5fe79e52755c0a728f99b16b",
                                 0x5181c08ca7caf86f6c2fba1ce9819db67a0f6697196fe6f17a5a22bd7631a4d8);
    }).then(tx => {
      assert.equal(tx.logs.length, 2);
      assert.equal(tx.logs[0].event, "RollCompleted");
      assert.equal(tx.logs[1].event, "PayoutDone");
    
      return lottery.rollNumbers.call("0x4d0c35e82c913bba0444cd9a43f56135f0ef74943e7e42fd3f75629efb3e95a5",
                                 0x3fdc2c7d05f01f1508cc5cf9f8a65a120a9032915cecb69a81548856481706ad);
    }).then(success => {
      assert.isFalse(success, "Should have failed this time, because there is a payout pending");
      return lottery.testLastRoll.call();
    }).then(roll => {
      console.log(roll[0] + ", " + roll[1] + ", " + roll[2] + ", " + roll[3] + ", " + roll[4]);
    });
  });
  it("placeBets then rollNumbers, check winnings", () => {
    var lottery;
    var token;

    return HMLottery.deployed().then(instance => {
      lottery = instance;

      return ExampleToken.deployed();
      }).then(instance => {
        token = instance;

        return lottery.placeBet(1, 2, 3, 4, 200, {from: accounts[1]});
      }).then(() => {
        return lottery.placeBet(5, 6, 7, 8, 200, {from: accounts[1]});
      }).then(() => {
        return lottery.placeBet(9, 10, 11, 12, 200, {from: accounts[1]});
      }).then(() => {
        return lottery.placeBet(13, 14, 15, 16, 200, {from: accounts[1]});
      }).then(() => {
        return lottery.placeBet(17, 18, 19, 20, 200, {from: accounts[1]});
      }).then(() => {
        return lottery.placeBet(21, 22, 23, 24, 200, {from: accounts[1]});
      }).then(() => {
        return lottery.testRollNumbers(1, 7, 8, 9);
      }).then(tx => {
        assert.equal(tx.logs.length, 4);
        assert.equal(tx.logs[0].event, "PlayerWon");
        console.log(tx.logs[tx.logs.length-1].args);
        return lottery.payOut.call();
      }).then(success => {
        assert.isFalse(success, "Should have failed because there is not enough funds availible");
        return token.transfer(lottery.address, 10000000); // this should be sufficient
      }).then(() => {
          return lottery.payOut.call();
      }).then(success => {
          assert.isTrue(success, "Should work now");
      }).then(() => {
          return lottery.payOut();
      }).then(tx => {
        assert.equal(tx.logs[0].event, "PayoutDone");
        console.log(tx.logs[0].args);
        return token.balanceOf.call(lottery.address);
      }).then(balance => {
        assert.equal(balance.toNumber(), 8350400);
        return lottery.placeBet(13, 14, 15, 16, 200, {from: accounts[1]});
      }).then(() => {
        return lottery.testRollNumbers(13, 14, 15, 17);
      }).then(tx => {
          // assert.equal(tx.logs.length, 2);
          assert.equal(tx.logs[0].event, "PlayerWon");
          console.log(tx.logs[0].args);
          return lottery.payOut.call();
      }).then(success => {
          assert.isFalse(success, "Should have failed because there is not enough funds availible");
        // 41943040000
      });
  });
});


