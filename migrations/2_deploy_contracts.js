const CryptoCasherCrowdsale = artifacts.require('./CryptoCasherCrowdsale.sol');

module.exports = (deployer) => {
    //http://www.onlineconversion.com/unix_time.htm
    var owner =  "0x5dEB46642Bc2CB5faaEB2241DDbe65FE894b7833";
    var wallet = "0x3c92578a0026f8301817830944Cc699d0BA5AcD7";
    deployer.deploy(CryptoCasherCrowdsale, owner, wallet);
};
