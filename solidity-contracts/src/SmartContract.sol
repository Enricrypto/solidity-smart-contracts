// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract ERC20Token {
    // public state variables
    address public owner; // address of the contract owner
    string public name; // name of the token
    string public symbol; // symbol of the token
    uint8 public decimals; // numbers of decimals the token uses
    uint256 public totalSupply; // total number of tokens

    //MAPPING
    //each address (wallet) is mapped to its balance
    mapping(address => uint256) public balanceOf;

    //nested mapping that keeps track of allowances
    // Allowance is the permission you grant to smart contracts or decentralized applications
    // (dApps) to spend a certain amount of a specific token on your behalf
    mapping(address => mapping(address => uint256)) public allowance;

    //EVENTS
    // emitted when tokens are transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    // emitted when an allowance is set by the 'approve' function
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    //CONSTRUCTOR:
    // - One-time Initialization: A special function that is executed once, when the contract is deployed.
    // - Security and Consistency: Using a constructor ensures that certain initial conditions are met before any other functions
    // can be called. This helps maintain the integrity and security of the contract.
    // - Initialized the token with a name, symbol, decimals and initial supply
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) {
        // set the contract deployer as the initial owner
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        //allocate the initial supply to the contract creator
        totalSupply = _initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    // modifier for only owner function
    modifier onlyOwner() {
        require(msg.sender == owner, "ERC20: caller is not the owner");
        _;
    }

    // TRANSFER FUNCTION: Allows transferring tokens from sender’s account to another account.
    function transfer(
        address _to,
        uint256 _value
    ) public returns (bool success) {
        // address(0) represents the zero address in Ethereum, which is a special address
        // typically used to signify the absence of an address or to burn tokens
        require(_to != address(0), "ERC20: transfer to the zero address");

        require(
            balanceOf[msg.sender] >= _value,
            // message if the condition evaluates to false
            "ERC20: transfer amount exceeds balance"
        );

        // transfer: Moves tokens from the caller's address to another address
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // APPROVE FUNCTION:
    // Allows an account to approve (give permission) a spender to spend tokens on his behalf.
    function approve(
        address _spender,
        uint256 _value
    ) public returns (bool success) {
        require(_spender != address(0), "ERC20: approve to the zero address");

        // to set an allowance: allowance[owner][spender]
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // FUNCTION TRANSFER FROM IF ENOUGH ALLOWANCE:
    // checks if you've given someone permission to spend your money
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(
            balanceOf[_from] >= _value,
            "ERC20: transfer amount exceeds balance"
        );
        require(
            allowance[_from][msg.sender] >= _value,
            "ERC20: transfer amount exceeds allowance"
        );

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    // FUNCTION MINT: Allows the owner to mint new tokens and assign them to an account
    function mint(
        address _to,
        uint256 _amount
    ) public onlyOwner returns (bool success) {
        require(_to != address(0), "ERC20: mint to the zero address");

        // increase total supply, uses the totalSupply variable from the constructor function
        totalSupply += _amount;
        // increase balance of user(recipient)
        balanceOf[_to] += _amount;
        // emit a transfer event from the zero address
        emit Transfer(address(0), _to, _amount);

        return true;
    }
}
