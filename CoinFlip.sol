// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "https://github.com/smartcontractkit/chainlink/blob/develop/evm-contracts/src/v0.6/VRFConsumerBase.sol";

contract CoinFlip is VRFConsumerBase {
    
    bytes32 internal keyHash;
    uint internal fee;
    uint public balance;
    uint refundWaitTime = 25;
    address payable casino_addr;

    enum State {Created, Player, Casino, Reveal, Result, Finished}
    
    struct Game {
        State state;
        
        address payable player_addr;
        uint player_choice;
        bytes32 player_hash;
        
        uint casino_choice;
        bytes32 casino_hash;
        
        uint startTime;
        uint randomResult;
        string result;
    }
    
    Game[] public Games;
    Game[] public FinishedGames; // TESTING PURPOSES
    
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
        require(msg.sender != casino_addr, "Only player can call this function");
        _;
    }
    
    modifier onlyCasino() {
        require(msg.sender == casino_addr, "Only casino can call this function");
        _;
    }
    
    modifier inState(State _state) {
        int idx = get_game_idx(msg.sender);
        require(idx != -1 && Games[uint(idx)].state == _state, "Invalid state.");
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
        // randomResult = randomness;
    }
    
    function hash(uint256 _choice, address _addr, uint256 _num) internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(_choice, _addr, _num));
    }
    
    
    function contract_created(address payable addr, uint256 bal) internal {
        casino_addr = addr; 
        balance = bal; // in units of wei
    }
    
    function player_commit(uint256 _val) 
        public payable
        onlyPlayer
    {
        require(get_game_idx(msg.sender) == -1, "You are already playing a casino game (1 game at a time)!");
        require(balance > 0, "Casino contract ran out of money to play with right now.");
        require(msg.value == 1 wei, "You must pay 1 wei to play the game!");
        require(_val == 0 || _val == 1, "Input should be 0 or 1");
        // getRandomNumber(uint256(casino.addr));
        uint randomResult = uint(100); // ***** THE RANDOM RESULT SHOULD BE DIFFERENT FOR EACH GAME BUT FOR NOW WE WILL USE 100, MEANING CASINO WILL ALWAYS CHOOSE 0 ***** 
        Game memory newGame = Game(
            State.Casino, // game State
            msg.sender, // player address
            _val, // player choice
            hash(uint(_val), msg.sender, randomResult), // player hash
            0, // casino choice
            0, // casino hash
            block.timestamp, // start time
            randomResult, // random result
            ''); // result
        Games.push(newGame);
        balance += msg.value; // how much wei the player sent to this contract
    }
    
    function player_refund() 
        public payable
        onlyPlayer
        inState(State.Casino)
    {
        int idx = get_game_idx(msg.sender);
        require(idx != -1, "You are not in any of the casino games!");
        Game storage game = Games[uint(idx)];
        require(block.timestamp - refundWaitTime >= game.startTime, "Need to wait longer before you can refund.");
        balance -= 1;
        game.player_addr.transfer(1);
        game.state = State.Finished;
        resetGame(); 
    }
    
    // Casino commits to each of the active games with a new random number for each (but we are using 100 for testing)
    function casino_commit_all_games() 
        public 
        onlyCasino
    {
        for(uint i = 0; i < Games.length; i ++) {
            Game storage game = Games[i];
            if(game.state == State.Casino && game.randomResult != 0) {
                game.casino_choice = game.randomResult % 2;
                game.casino_hash = hash(game.randomResult % 2, address(this), game.randomResult);
                game.state = State.Reveal;
            }
        }
    }
    
    function player_reveal() 
        public
        onlyPlayer
        inState(State.Reveal)
    {
        int idx = get_game_idx(msg.sender);
        require(idx != -1, "You are not in any of the casino games!");
        Game storage game = Games[uint(idx)];
        require(hash(uint(game.player_choice), game.player_addr, game.randomResult) == game.player_hash, "Player Choice has been changed illegally");
        require(hash(game.randomResult % 2, address(this), game.randomResult) == game.casino_hash, "Choice has been changed illegally");
        game.state = State.Result;
    }
    
    function compute_result() 
        public 
        onlyPlayer
        inState(State.Result)
    {
        int idx = get_game_idx(msg.sender);
        require(idx != -1, "You are not in any of the casino games!");
        Game storage game = Games[uint(idx)];
        if(game.player_choice == game.casino_choice) {
            game.player_addr.transfer(2);
            balance -= 2;
            game.result = "Player win, the money goes to the Player!";
        } else {
            game.result = "Player lose, the money stays in the Casino contract!";
        }
        game.state = State.Finished;
        resetGame(); 
    }
    
    function return_my_money() // for testing purposes in case the contract is broken, hopefully you can get back your fake eth with this or else it gone forever, stuck in the contract
        internal
        onlyCasino
    {
        balance -= address(this).balance;
        casino_addr.transfer(address(this).balance);
    }
    
    function resetGame() 
        internal
    {
        int idx = get_game_idx(msg.sender);
        require(idx != -1, "Player not in any of the casino games!");
        remove_player(uint(idx)); // ***** FOR TESTING PURPOSES, I WILL REMOVE TO THE FINISHED GAMES ARRAY ******
    }
    
    function remove_player(uint index) 
        internal 
    {
        if (index >= Games.length) return;
        
        FinishedGames.push(Games[index]);
        
        for (uint i = index; i<Games.length-1; i++){
            Games[i] = Games[i+1];
        }
        Games.pop();
    }
    
    function get_casino() internal view returns(address payable) {
        return casino_addr;
    }
    
    
    function get_balance() internal view returns(uint256) {
        return balance;
    }
    
    function get_game_idx(address addr) internal view returns(int) {
        if(Games.length == 0)
            return -1;
        for(uint i = 0; i < Games.length; i ++) {
            if(Games[i].player_addr == addr)
                return int(i);
        }
        return -1;
    }

    
}
