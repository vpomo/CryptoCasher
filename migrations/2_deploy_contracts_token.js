const CryptoCasherToken = artifacts.require('./CryptoCasherToken.sol');

module.exports = (deployer) => {
    //http://www.onlineconversion.com/unix_time.htm
    var owner =  "0x3038BdaC92EFB4a9392396bc97db8730E18cFf03";
    deployer.deploy(CryptoCasherToken, owner);
};
