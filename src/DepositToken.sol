// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract DepositToken {
    // public state variables
    address public admin; // address of the contract admin
    string public name; // name of the token
    string public symbol; // symbol of the token
    uint8 public decimals; // numbers of decimals the token uses
    uint256 public totalSupply; // total number of tokens in circulation

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
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // event of who calls the function
    event Caller(address indexed owner);

    //CONSTRUCTOR:
    // - One-time Initialization: A special function that is executed once, when the contract is deployed.
    // - Security and Consistency: Using a constructor ensures that certain initial conditions are met before any other
    // functions can be called. This helps maintain the integrity and security of the contract.
    // - Initialized the token with a name, symbol, decimals and initial supply
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _initialSupply) {
        // set the contract deployer as the initial admin
        admin = msg.sender;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply * 10 * 1e18; // shorthand for 1 * 10^18, often used to represent 1 Ether in the smallest unit, Wei
        //allocate the initial supply to the contract creator
        balanceOf[msg.sender] = totalSupply;
    }

    // modifier for only admin function
    modifier onlyAdmin() {
        emit Caller(msg.sender);
        require(msg.sender == admin, "ERC20: caller is not the admin");
        _;
    }

    // TRANSFER FUNCTION: Allows transferring tokens from sender’s account to another account.
    // Caller: The transfer function is typically called by the owner of the tokens (the token holder).
    function transfer(address _to, uint256 _value) public returns (bool success) {
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
        // By wrapping the arithmetic operation inside an unchecked block, you tell the Solidity
        // compiler to skip these overflow and underflow checks for the enclosed operations.
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // APPROVE FUNCTION:
    // Allows an account to give permission (approve) to a spender to spend tokens on his behalf.
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), "ERC20: approve to the zero address");

        // to set an allowance: allowance[owner][spender]
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // FUNCTION TRANSFER FROM IF ENOUGH ALLOWANCE:
    // The transferFrom function is called by a third party (commonly referred to as the "spender")
    // who has been authorized by the token owner to transfer tokens on their behalf
    function transferFrom(
        address _from, // address owning the tokens
        address _to, // address receiving the tokens
        uint256 _value
    ) public returns (bool success) {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(balanceOf[_from] >= _value, "ERC20: transfer amount exceeds balance");
        require(
            allowance[_from][msg.sender] >= _value, // msg.sender is the address of the contract given the allowance
            "ERC20: transfer amount exceeds allowance"
        );

        // adjust allowance
        allowance[_from][msg.sender] -= _value; // msg.sender is the address calling the function, which in this case is the spender

        // transfer tokens
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    // FUNCTION MINT: Allows the admin to mint new tokens and assign them to a specific account (_to)
    function mint(address _to, uint256 _amount) public onlyAdmin returns (bool success) {
        require(_to != address(0), "ERC20: mint to the zero address");
        // msg.sender is calling the function and interacting with the contract
        emit Caller(msg.sender);
        // increase total supply, uses the totalSupply variable from the constructor function
        totalSupply += _amount;
        // increase balance of user(recipient)
        balanceOf[_to] += _amount;
        // emit a transfer event FROM the zero address
        emit Transfer(address(0), _to, _amount);

        return true;
    }

    // CHANGE ADMIN function has the purpose of delegating control of the contract, gives flexibility allowing to change
    // leadership on the project and helps with security in case the address of the deployer gets compromised
    function changeAdmin(address _admin) public onlyAdmin {
        admin = _admin;
    }
}
