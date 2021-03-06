pragma solidity ^0.4.18;

contract Token {
    function totalSupply() public constant returns (uint256 supply) {}

    function balanceOf(address _owner) public constant returns (uint256 balance) {}

    function transfer(address _to, uint256 _value) public returns (bool success) {}

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}

    function approve(address _spender, uint256 _value) public returns (bool success) {}

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract StandardToken is Token {
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;
    uint256 public totalSupply;
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender,_to,_value);
            return true;
        } else {
            return false;
        }
     }
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) { 
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_from] -= _value;
            balances[_to] += _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from,_to,_value);
            return true;
        } else {
            return false;
        }
     }

     function balanceOf(address _owner) public view returns (uint256 balance) { 
         return balances[_owner];
     }

     function approve(address _spender, uint256 _value) public returns (bool success) {
         allowed[msg.sender][_spender] -= _value;
         Approval(msg.sender,_spender,_value);
         return true;
      }

      function allownace(address _owner, address _spender) public view returns (uint256 remaining) {
          return allowed[_owner][_spender];
       }
}

contract AYUSToken is StandardToken {
    string public name;
    uint256 public decimals = 18;
    string public symbol;
    string public version = "B1.0.0";
    uint256 public unitsOneEthCanBuy;
    uint256 public totalEthInWei;
    address public fundsWallet; //Where should the raised token go?

    function AYUSToken() public {
        balances[msg.sender] = 1000 * (10 ** decimals);
        totalSupply = 1000 * (10 ** decimals);
        name = "AYUS";
        symbol = "AYUS";
        unitsOneEthCanBuy = 10;
        fundsWallet = msg.sender;
    }

    function() payable public {
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        if (balances[fundsWallet] < amount) {
            return;
        }

        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;

        Transfer(fundsWallet, msg.sender, amount);

        fundsWallet.transfer(msg.value); //Transfer funds to fundsWallet
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