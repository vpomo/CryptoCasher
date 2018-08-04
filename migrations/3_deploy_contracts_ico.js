const CryptoCasherCrowdsale = artifacts.require('./CryptoCasherCrowdsale.sol');

module.exports = (deployer) => {
    //http://www.onlineconversion.com/unix_time.htm
    var owner =  "0x3038BdaC92EFB4a9392396bc97db8730E18cFf03";
    var wallet = "0x3cFe0E6eD20901E01D29ab7699243be2B8B6aC54";
    deployer.deploy(CryptoCasherCrowdsale, owner, wallet);
};
