var ExampleToken = artifacts.require("./ExampleToken.sol");
var HMLottery = artifacts.require("./HMLottery.sol");

module.exports = function(deployer) {
  deployer.deploy(ExampleToken);
  //deployer.link(ExampleToken, HMLottery);
  deployer.deploy(HMLottery);
};
