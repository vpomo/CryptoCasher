const CryptoCasherCrowdsale = artifacts.require('./CryptoCasherCrowdsale.sol');

module.exports = (deployer) => {
    //http://www.onlineconversion.com/unix_time.htm
    var owner =    "0x5deb46642bc2cb5faaeb2241ddbe65fe894b7833";
    var wallet = "0x3c92578a0026f8301817830944cc699d0ba5acd7";
    deployer.deploy(CryptoCasherCrowdsale, owner, ownerTwo);

};
