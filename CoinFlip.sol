// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "https://github.com/smartcontractkit/chainlink/blob/develop/evm-contracts/src/v0.6/VRFConsumerBase.sol";

contract CoinFlip is VRFConsumerBase {
    
    bytes32 internal keyHash;
    uint internal fee;
    uint public balance;
    uint public randomResult;
    string public result;
    uint public startTime;
    uint public refundWaitTime = 15; // in seconds
    
    enum Choice {Head, Tail}
    enum State {Created, Player, Casino, Reveal, Result}
    State public state;
    
    struct commitment {
        bytes32 hash_val;
        Choice choice;
        address payable addr;
    }
    
    commitment public player;
    commitment public casino;
        
    constructor() 
        VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
        ) 
        public payable
    {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (varies by network)
        contract_created(msg.sender, msg.value);
    }
    
    modifier onlyPlayer() {
        require(msg.sender != casino.addr, "Only player can call this function");
        _;
    }
    
    modifier onlyCasino() {
        require(msg.sender == casino.addr, "Only casino can call this function");
        _;
    }
    
    modifier inState(State _state) {
        require(state == _state, "Invalid state.");
        _;
    }
    
   /** 
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(uint256 userProvidedSeed) internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee, userProvidedSeed);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }
    
    function hash(uint256 _choice, address _addr, uint256 _num) internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(_choice, _addr, _num));
    }
    
    
    function contract_created(address payable addr, uint256 bal) internal {
        casino.addr = addr; 
        balance = bal; // in units of wei
        state = State.Player;
    }
    
    function player_commit(uint256 _val) 
        public payable
        onlyPlayer
        inState(State.Player)
    {
        require(balance > 0, "Casino contract ran out of money to play with right now.");
        require(msg.value == 1 wei);
        require(_val == 0 || _val == 1, "Input should be 0 or 1");
        player.addr = msg.sender;
        balance += msg.value; // how much wei the player sent to this contract
        // getRandomNumber(uint256(casino.addr));
        randomResult = uint(100);
        if(_val == 0) 
            player.choice = Choice.Head;
        else 
            player.choice = Choice.Tail;
        player.hash_val = hash(uint(player.choice), player.addr, randomResult);
        startTime = block.timestamp;
        state = State.Casino;
    }
    
    function player_refund() 
        public payable
        onlyPlayer
        inState(State.Casino)
    {
        require(block.timestamp - refundWaitTime >= startTime, "Need to wait longer before you can refund.");
        balance -= 1;
        player.addr.transfer(1);
        resetGame();
    }
    
    function casino_commit() 
        public 
        onlyCasino
        inState(State.Casino)
    {
        require(randomResult != 0, "Random number is still being generated");
        if(randomResult % 2 == 0)
            casino.choice = Choice.Head;
        else 
            casino.choice = Choice.Tail;
        casino.hash_val = hash(randomResult % 2, address(this), randomResult);
        state = State.Reveal;
    }
    
    function player_reveal() 
        public
        onlyPlayer
        inState(State.Reveal)
    {
        require(hash(uint(player.choice), player.addr, randomResult) == player.hash_val, "Player Choice has been changed illegally");
        require(hash(randomResult % 2, address(this), randomResult) == casino.hash_val, "Choice has been changed illegally");
        state = State.Result;
    }
    
    function compute_result() 
        public 
        inState(State.Result)
    {
        if(player.choice == casino.choice) {
            player.addr.transfer(2);
            balance -= 2;
            result = "Player win, the money goes to the Player!";
        } else {
            result = "Player lose, the money stays in the Casino contract!";
        }
        resetGame();
    }
    
    function return_my_money() // for testing purposes in case the contract is broken, hopefully you can get back your fake eth with this or else it gone forever, stuck in the contract
        public
        onlyCasino
    {
        balance -= address(this).balance;
        casino.addr.transfer(address(this).balance);
    }
    
    function resetGame() 
        internal
    {
        delete player;
        delete casino.choice;
        delete casino.hash_val;
        state = State.Player;
    }
    
    function get_casino() internal view returns(address payable) {
        return casino.addr;
    }
    
    function get_casino_choice() view internal returns(uint256) {
        return uint256(casino.choice);
    }
    
    function get_player() internal view returns(address payable) {
        return player.addr;
    }
    
    function get_player_choice() internal view returns(uint256) {
        return uint256(player.choice);
    }
    function get_balance() internal view returns(uint256) {
        return balance;
    }
    
}