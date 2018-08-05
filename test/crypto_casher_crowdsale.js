var CryptoCasherCrowdsale = artifacts.require("./CryptoCasherCrowdsale.sol");
var CryptoCasherToken = artifacts.require("./CryptoCasherToken.sol");
var contractToken;

contract('CryptoCasherToken', (accounts) => {
    var ownerContact;
    it('should deployed CryptoCasherToken', async ()  => {
        assert.equal(undefined, contractToken);
        contractToken = await CryptoCasherToken.deployed();
        assert.notEqual(undefined, contractToken);
    });

    it('get address CryptoCasherToken', async ()  => {
        assert.notEqual(undefined, contractToken.address);
        ownerContact = await contractToken.owner.call();
        //console.log("ownerContact = " + ownerContact);
    });
});

contract('CryptoCasherCrowdsale', (accounts) => {
    var contract;
    var owner = accounts[0];
    var rate = 714*1.01;
    var buyWei = 1 * 10**18;
    var rateNew = 714*1.01;
    var buyWeiNew = 5 * 10**17;
    var buyWeiMin = 1 * 10**16;
    var buyWeiCap = 35000 * (10e18);

    var fundForSale = Number(525 * 10**23);
    var tokenAllocated = Number(225 * 10**23);


    it('should deployed contract', async ()  => {
        assert.equal(undefined, contract);
        contract = await CryptoCasherCrowdsale.deployed();
        assert.notEqual(undefined, contract);
    });

    it('get address contract', async ()  => {
        assert.notEqual(undefined, contract.address);
    });

    it('prepare two contracts ...', async ()  => {
        await contractToken.setContractAddress(contract.address);
        await contract.setContractErc20Token(contractToken.address);
    });


    it('verification balance owner contract', async ()  => {
        var balanceOwner = await contractToken.balanceOf(owner);
        var tokenAllocatedCurrent = await contract.tokenAllocated.call();
        assert.equal(tokenAllocated, tokenAllocatedCurrent);
        assert.equal(fundForSale, balanceOwner);
    });

    it('verification of receiving Ether', async ()  => {

        await contract.addToWhitelist(accounts[2], {from:accounts[0]});
        await contract.addToWhitelist(accounts[3], {from:accounts[0]});
        var isWhiteList = await contract.whitelist.call(accounts[2]);
        assert.equal(true, isWhiteList);

        var tokenAllocatedBefore = await contract.tokenAllocated.call();
        var balanceAccountTwoBefore = await contract.balanceOf(accounts[2]);
        var weiRaisedBefore = await contract.weiRaised.call();
        //console.log("tokenAllocatedBefore = " + tokenAllocatedBefore);

        var numberToken = await contract.validPurchaseTokens.call(Number(buyWei));
        //console.log(" numberTokens = " + JSON.stringify(numberToken));
        //console.log("numberTokens = " + Number(numberToken/10**18));

        await contract.buyTokens(accounts[2],{from:accounts[2], value:buyWei});
        var tokenAllocatedAfter = await contract.tokenAllocated.call();
        //console.log("tokenAllocatedAfter = " + tokenAllocatedAfter);

        assert.isTrue(Number(tokenAllocatedBefore) < Number(tokenAllocatedAfter));
        //assert.equal(rate*buyWei, tokenAllocatedAfter - tokenAllocatedBefore);

        var balanceAccountTwoAfter = await contract.balanceOf(accounts[2]);
        assert.isTrue(balanceAccountTwoBefore < balanceAccountTwoAfter);
        assert.equal(0, balanceAccountTwoBefore);
        assert.equal(rate*buyWei, balanceAccountTwoAfter);

        var weiRaisedAfter = await contract.weiRaised.call();
        //console.log("weiRaisedAfter = " + weiRaisedAfter);
        assert.isTrue(weiRaisedBefore < weiRaisedAfter);
        assert.equal(0, weiRaisedBefore);
        assert.equal(buyWei, weiRaisedAfter);

        var depositedAfter = await contract.deposited.call(accounts[2]);
        //console.log("DepositedAfter = " + depositedAfter);
        assert.equal(buyWei, depositedAfter);

        var balanceAccountThreeBefore = await contract.balanceOf(accounts[3]);
        await contract.buyTokens(accounts[3],{from:accounts[3], value:buyWeiNew});
        var balanceAccountThreeAfter = await contract.balanceOf(accounts[3]);
        assert.isTrue(balanceAccountThreeBefore < balanceAccountThreeAfter);
        assert.equal(0, balanceAccountThreeBefore);
        //console.log("balanceAccountThreeAfter = " + balanceAccountThreeAfter);
        assert.equal(rateNew*buyWeiNew, balanceAccountThreeAfter);

        var balanceOwnerAfter = await contract.balanceOf(owner);
        //console.log("balanceOwnerAfter = " + Number(balanceOwnerAfter));
        //assert.equal(totalSupply - balanceAccountThreeAfter - balanceAccountTwoAfter, balanceOwnerAfter);
    });

    it('verification define ICO period', async ()  => {
        currentDate = 1534766400; // Aug, 20
        period = await contract.getPeriod(currentDate);
        assert.equal(10, period);

        currentDate = 1536573600; // Mon, 10 Sep 2018 10:00:00 GMT
        period = await contract.getPeriod(currentDate);
        assert.equal(0, period);

        currentDate = 1536591600; // Mon, 10 Sep 2018 15:00:00 GMT
        period = await contract.getPeriod(currentDate);
        assert.equal(1, period);

        currentDate = 1536764400; // Wed, 12 Sep 2018 15:00:00 GMT
        period = await contract.getPeriod(currentDate);
        assert.equal(2, period);

        currentDate = 1540479600; // Thu, 25 Oct 2018 15:00:00 GMT
        period = await contract.getPeriod(currentDate);
        assert.equal(3, period);

        currentDate = 1543158000; // Sun, 25 Nov 2018 15:00:00 GMT
        period = await contract.getPeriod(currentDate);
        assert.equal(4, period);

        currentDate = 1545750000; // Tue, 25 Dec 2018 15:00:00 GMT
        period = await contract.getPeriod(currentDate);
        assert.equal(5, period);

        currentDate = 1548428400; // Fri, 25 Jan 2019 15:00:00 GMT
        period = await contract.getPeriod(currentDate);
        assert.equal(6, period);


        currentDate = 1553526000; // Mon, 25 Mar 2019 15:00:00 GMT
        period = await contract.getPeriod(currentDate);
        assert.equal(10, period);
    });

    it('check vesting period', async ()  => {
        var currentDate = 1552219200; // Mar, 10, 2019
        var vestingPeriod = await contractToken.checkVesting(buyWeiMin, currentDate);
        assert.equal(0, vestingPeriod);

        currentDate = 1568116800; // Sep, 10, 2019
        vestingPeriod = await contractToken.checkVesting(buyWeiMin, currentDate);
        assert.equal(1, vestingPeriod);

        currentDate = 1583841600; // Mar, 10, 2020
        vestingPeriod = await contractToken.checkVesting(buyWeiMin, currentDate);
        assert.equal(2, vestingPeriod);

        currentDate = 1599739200; // Sep, 10, 2020
        vestingPeriod = await contractToken.checkVesting(buyWeiMin, currentDate);
        assert.equal(3, vestingPeriod);

        currentDate = 1615377600; // Mar, 10, 2021
        vestingPeriod = await contractToken.checkVesting(buyWeiMin, currentDate);
        assert.equal(4, vestingPeriod);

        currentDate = 1631275200; // Sep, 10, 2021
        vestingPeriod = await contractToken.checkVesting(buyWeiMin, currentDate);
        assert.equal(5, vestingPeriod);

        currentDate = 1646913600; // Mar, 10, 2022
        vestingPeriod = await contractToken.checkVesting(buyWeiMin, currentDate);
        assert.equal(5, vestingPeriod);
    });

    it('verification tokens cap reached', async ()  => {
            var numberTokensNormal = await contract.validPurchaseTokens.call(buyWei);
            //console.log("numberTokensNormal = " + numberTokensNormal);
            assert.equal(rate*buyWei, numberTokensNormal);

            var numberTokensFault = await contract.validPurchaseTokens.call(buyWeiCap);
            //console.log("numberTokensFault = " + numberTokensFault);
            assert.equal(0, numberTokensFault);
    });

    it('verification non whitelist purchaise', async ()  => {
        var addressFundNonKYCBefore = "0x7AEcFB881B6Ff010E4b7fb582C562aa3FCCb2170";
        var balanceAccountSevenBefore = await contract.balanceOf(accounts[7]);
        var balanceFundNonKYCBefore = await contract.balanceOf(addressFundNonKYCBefore);
        await contract.buyTokens(accounts[7],{from:accounts[7], value:buyWei});
        var balanceAccountSevenAfter = await contract.balanceOf(accounts[7]);
        assert.equal(0, balanceAccountSevenAfter);
        assert.equal(0, balanceAccountSevenBefore);

        var balanceFundNonKYCAfter = await contract.balanceOf(addressFundNonKYCBefore);
        assert.equal(rate*buyWei, balanceFundNonKYCAfter);
    });

});



