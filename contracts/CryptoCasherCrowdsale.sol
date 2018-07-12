pragma solidity ^0.4.24;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}


contract ERC20Basic {
    uint256 public totalSupply;

    bool public transfersEnabled;

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 {
    uint256 public totalSupply;

    bool public transfersEnabled;

    function balanceOf(address _owner) public constant returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping (address => uint256) balances;

    /**
    * Protection against short address attack
    */
    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
        _;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public onlyPayloadSize(2) returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(transfersEnabled);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

}


contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

    address public addressFundTeam = 0x7d63d560c994f4cc29c29c85a1bc24e459786a39;
    uint256 public fundTeam = 1125 * 10**4 * (10 ** 18);

    uint256 public startTime = 1533081600; // 01 Aug 2018 00:00:00 GMT
    uint256 endTime = startTime + 35 days;
    uint256 firstRelease = endTime + 26 weeks;
    uint256 secondRelease = firstRelease + 26 weeks;
    uint256 thirdRelease = secondRelease + 26 weeks;
    uint256 fourthRelease = thirdRelease + 26 weeks;
    uint256 fifthRelease = fourthRelease + 26 weeks;

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3) returns (bool) {
        require(_to != address(0));
        if (msg.sender == addressFundTeam) {
            require(checkVesting(_value, now) > 0);
        }

        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(transfersEnabled);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public onlyPayloadSize(2) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        }
        else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function checkVesting(uint256 _value, uint256 _currentTime) public view returns(uint8 period) {
        period = 0;
        require(firstRelease <= _currentTime);
        if (firstRelease <= _currentTime && _currentTime < secondRelease) {
            period = 1;
            require(balances[addressFundTeam].sub(_value) > fundTeam.mul(95).div(100));
        }
        if (secondRelease <= _currentTime && _currentTime < thirdRelease) {
            period = 2;
            require(balances[addressFundTeam].sub(_value) > fundTeam.mul(9).div(10));
        }
        if (thirdRelease <= _currentTime && _currentTime < fourthRelease) {
            period = 3;
            require(balances[addressFundTeam].sub(_value) > fundTeam.mul(4).div(5));
        }
        if (fourthRelease <= _currentTime) {
            period = 4;
            require(balances[addressFundTeam].sub(_value) > fundTeam.mul(3).div(10));
        }
        if (fifthRelease <= _currentTime) {
            period = 5;
            require(balances[addressFundTeam].sub(_value) >= 0);
        }
    }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public ownerTwo;

    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == ownerTwo);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function changeOwnerTwo(address _newOwner) onlyOwner public {
        require(_newOwner != address(0));
        emit OwnerChanged(owner, _newOwner);
        ownerTwo = _newOwner;
    }

}


/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
    string public constant name = "CryptoCasher";
    string public constant symbol = "CRR";
    uint8 public constant decimals = 18;

    event Mint(address indexed to, uint256 amount);

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount, address _owner) internal returns (bool) {
        balances[_to] = balances[_to].add(_amount);
        balances[_owner] = balances[_owner].sub(_amount);
        emit Mint(_to, _amount);
        emit Transfer(_owner, _to, _amount);
        return true;
    }

    /**
     * Peterson's Law Protection
     * Claim tokens
     */
    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }

        MintableToken token = MintableToken(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);

        emit Transfer(_token, owner, balance);
    }
}


/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale is Ownable {
    using SafeMath for uint256;
    // address where funds are collected
    address public wallet;

    // amount of raised money in wei
    uint256 public weiRaised;

    uint256 public tokenAllocated;

    uint256 public hardCap = 35000 ether;

    constructor (address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
    }
}


contract FooozCrowdsale is Ownable, Crowdsale, MintableToken {
    using SafeMath for uint256;

    enum State {Active, Closed}
    State public state;

    mapping (address => uint256) public deposited;

    uint256 public constant INITIAL_SUPPLY = 75 * 10**6 * (10 ** uint256(decimals));
    uint256 public fundForSale = 525 * 10**5 * (10 ** uint256(decimals));

    address public addressFundAdvisors = 0x443a9477bad71137e7914672831298cc514f4ce4;
    uint256 public fundAdvisors = 75 * 10**5 * (10 ** uint256(decimals));

    address public addressFundBounty = 0x32D5b0432E770838d3632bf0fca60bFDF283c299;
    uint256 public fundBounty = 75 * 10**5 * (10 ** uint256(decimals));

    uint256[] public discount  = [200, 150, 100, 75, 50, 25];

    uint256 public weiMinSalePrivate = 10 ether;

    uint256 priceToken = 0.001 ether;
    uint256 priceTokenPrivate = 0.0008 ether;

    uint256 public countInvestor;
    uint256 public currentAfterIcoPeriod;

    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    event TokenLimitReached(uint256 tokenRaised, uint256 purchasedToken);
    event HardCapReached();
    event Burn(address indexed burner, uint256 value);

    constructor (address _owner, address _ownerTwo) public
    Crowdsale(_owner)
    {
        require(_owner != address(0));
        require(_ownerTwo != address(0));
        owner = _owner;
        ownerTwo = _ownerTwo;
        //owner = msg.sender; //for test's
        transfersEnabled = true;
        state = State.Active;
        totalSupply = INITIAL_SUPPLY;
        mintForOwner(owner);
    }

    modifier inState(State _state) {
        require(state == _state);
        _;
    }

    // fallback function can be used to buy tokens
    function() payable public {
        buyTokens(msg.sender);
    }

    function setPriceToken(uint256 _newPrice) public onlyOwner {
        require(_newPrice > 0);
        priceToken = _newPrice;
    }

    // low level token purchase function
    function buyTokens(address _investor) public inState(State.Active) payable returns (uint256){
        require(_investor != address(0));
        uint256 weiAmount = msg.value;
        uint256 tokens = validPurchaseTokens(weiAmount);
        if (tokens == 0) {revert();}
        weiRaised = weiRaised.add(weiAmount);
        tokenAllocated = tokenAllocated.add(tokens);
        mint(_investor, tokens, owner);

        emit TokenPurchase(_investor, weiAmount, tokens);
        if (deposited[_investor] == 0) {
            countInvestor = countInvestor.add(1);
        }
        deposit(_investor);
        wallet.transfer(weiAmount);
        return tokens;
    }

    function getTotalAmountOfTokens(uint256 _weiAmount) internal view returns (uint256) {
        uint256 currentDate = now;
        //currentDate = 1537444800; //for test's (Tue, 20 Sep 2018 12:00:00 GMT)
        uint256 currentPeriod = getPeriod(currentDate);
        uint256 amountOfTokens = 0;
        if(currentPeriod == 0 && _weiAmount >= weiMinSalePrivate){
            amountOfTokens = _weiAmount.mul(priceTokenPrivate).mul(discount[0] + 1000).div(1000);
        }
        if(0 < currentPeriod && currentPeriod < 6){
            amountOfTokens = _weiAmount.mul(priceToken).mul(discount[currentPeriod] + 1000).div(1000);
        }
        if(currentPeriod == 10){
            amountOfTokens = 0;
        }
        return amountOfTokens;
    }

    /**
    * Pre-ICO sale starts on 01 of Jul, ends on 05 Jul 2018
    * 0 Stage starts before 15 of Sep, 2018
    * 1 Stage starts 15 of Sep, ends on 15 of Oct , 2018
    * 2 Stage starts 16 of Oct, ends on 15 of Nov , 2018
    * 3 Stage starts 16 of Nov, ends on 15 of Dec , 2018
    * 4 Stage starts 16 of Dec, ends on 15  of Jan , 2019
    * 5 Stage starts 16 of Jan, ends on 15  of Feb , 2019
    */
    function getPeriod(uint256 _currentDate) public pure returns (uint) {
        //before Sep, 15, 2018 12:00:00
        if(_currentDate <= 1537012800){
            return 0;
        }
        //1530403200 - Sep, 15, 2018 12:00:01 && 1530835199 - Oct, 15, 2018 12:00:00
        if( 1537012801 <= _currentDate && _currentDate <= 1539604800){
            return 1;
        }
        //1530835200 - Oct, 15, 2018 12:00:01 && 1531699199 - Nov, 15, 2018 12:00:00
        if( 1539604801 <= _currentDate && _currentDate <= 1542283200){
            return 2;
        }
        //1531699200 - Nov, 15, 2018 12:00:01 && 1532563199 - Dec, 15, 2018 12:00:00
        if( 1542283201 <= _currentDate && _currentDate <= 1544875200){
            return 3;
        }
        //1532563200 - Dec, 15, 2018 12:00:00 && 1533513599 - Jan,   15, 2018 12:00:00
        if( 1544875201 <= _currentDate && _currentDate <= 1547553600){
            return 4;
        }
        //1533513600 - Jan,   15, 2018 12:00:00 && 1534377599 - Feb,   15, 2018 12:00:00
        if( 1547553601 <= _currentDate && _currentDate <= 1550232000){
            return 5;
        }
        return 10;
    }

    function deposit(address investor) internal {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function mintForOwner(address _wallet) internal returns (bool result) {
        result = false;
        require(_wallet != address(0));
        balances[addressFundAdvisors] = balances[addressFundAdvisors].add(fundAdvisors);
        balances[addressFundBounty] = balances[addressFundBounty].add(fundBounty);
        tokenAllocated = tokenAllocated.add(fundAdvisors).add(fundBounty).add(fundTeam);
        balances[_wallet] = balances[_wallet].add(INITIAL_SUPPLY).sub(tokenAllocated);
        result = true;
    }

    function getDeposited(address _investor) public view returns (uint256){
        return deposited[_investor];
    }

    function validPurchaseTokens(uint256 _weiAmount) public inState(State.Active) returns (uint256) {
        uint256 addTokens = getTotalAmountOfTokens(_weiAmount);
        if (tokenAllocated.add(addTokens) > fundForSale) {
            emit TokenLimitReached(tokenAllocated, addTokens);
            return 0;
        }
        if (weiRaised.add(_weiAmount) > hardCap) {
            emit HardCapReached();
            return 0;
        }
        return addTokens;
    }

    /**
    * @dev owner burn Token.
    * @param _value amount of burnt tokens
    */
    function ownerBurnToken(uint _value) public onlyOwner {
        require(_value > 0);
        require(_value <= balances[owner]);
        require(_value <= totalSupply);
        require(_value <= fundForSale);

        balances[owner] = balances[owner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        fundForSale = fundForSale.sub(_value);
        emit Burn(msg.sender, _value);
    }
}

