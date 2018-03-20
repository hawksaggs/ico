pragma solidity ^0.4.18;

contract SafeMath {

    function safeAdd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        if (x < y) revert();
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        if (y == 0) return 0;
        return x * y;
    }

    function safeDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        uint256 c = x / y;
        return c;
    }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address owner) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns(uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC223 {
    function transfer(address to, uint value, bytes data) returns (bool);
}

contract ERC223Receiver {
    function tokenFallback(address from, uint value, bytes data);
}

contract BasicToken is ERC20Basic, SafeMath {

    mapping (address => uint256) balances;

    uint256 _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address owner) public view returns (uint256 balance) {
        return balances[owner];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(balanceOf(msg.sender) > value);
        balances[msg.sender] = safeSub(balanceOf(msg.sender), value);
        balances[to] = safeAdd(balanceOf(to), value);
        Transfer(msg.sender, to, value);
        return true;
    }
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping(address => uint256)) internal allowed;

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(balances[from] >= value);
        require(allowed[from][msg.sender] >= value);
        balances[from] = safeSub(balanceOf(msg.sender), value);
        balances[to] = safeAdd(balanceOf(to), value);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], value);
        Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool){
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }
}

contract ERC223Token is ERC223, StandardToken {
    function transfer(address to, uint value, bytes data) returns (bool) {
        if (isContract(to)) {
            return transferToContract(to, value, data);
        } else {
            return transferToAddress(to, value, data);
        }
    }
    function transfer(address to, uint value) returns (bool) {
        bytes memory empty;
        return transfer(to, value, empty);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public returns (bool){
     return super.approve(spender, value);   
    }

    function isContract(address addr) private returns (bool isContract) {
      uint32 size;
      assembly {
        size := extcodesize(addr)
      }
      return (size > 0);
    }

    function transferToAddress(address to, uint value, bytes data) private returns (bool success) {
        require(balanceOf(msg.sender) > value);
        balances[msg.sender] = safeSub(balanceOf(msg.sender), value);
        balances[to] = safeAdd(balanceOf(to), value);
        Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferToContract(address to, uint value, bytes data) private returns (bool success) {
        require(balanceOf(msg.sender) > value);
        balances[msg.sender] = safeSub(balanceOf(msg.sender), value);
        balances[to] = safeAdd(balanceOf(msg.sender), value);
        ERC223Receiver receiver = ERC223Receiver(to);
        receiver.tokenFallback(msg.sender, value, data);
        Transfer(msg.sender, to, value);
        return true;
    }
}

contract AYUToken is ERC223Token {
    string public name = "AYU";
    string public symbol = "AYU";
    uint256 public decimals = 18;
    uint256 public unitsOneEthCanBuy;
    address public fundsWallet;

    function AYUToken() {
        _totalSupply = 20000000 * (10 ** decimals);
        unitsOneEthCanBuy = 10;
        fundsWallet = msg.sender;
    }

    function() payable  public {
        uint256 amount = msg.value * unitsOneEthCanBuy;
        require(balanceOf(fundsWallet) > amount);
        balances[fundsWallet] = safeSub(balanceOf(fundsWallet), amount);
        balances[msg.sender] = safeAdd(balanceOf(msg.sender), amount);

        Transfer(fundsWallet, msg.sender, amount);

        fundsWallet.transfer(msg.value);
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        if (!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address, uint256, address, bytes)"))), msg.sender, _value, this, _extraData)) { 
            revert();
        }

        return true;
    }
}
