pragma solidity ^0.4.8;

import 'zeppelin/token/StandardToken.sol';


/*
 * ExampleToken
 *
 * Simple ERC20 Token example, with crowdsale token creation
 */
contract ExampleToken is StandardToken {

  string public name = "ExampleToken";
  string public symbol = "EXAT";
  uint public decimals = 18;
  uint public totalSupply = 5000000000;

  function ExampleToken() {
    balances[msg.sender] = totalSupply;
  }
  
}
