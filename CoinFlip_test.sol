// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.6;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "remix_accounts.sol";
import "../contracts/CoinFlip.sol"; // make sure directory of this is correct!


/// #value: 2
contract CoinFlipTest is CoinFlip{
    
    // Define variables referring to different accounts
    address acc0; // casino
    address acc1; // player 1
    address acc2; // player 2
    
    function beforeAll () public returns (bool) {
        acc0 = TestsAccounts.getAccount(0); 
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
    }
    
    // Account 0 creates a new contract.
    // Tests if initialized balance is correct and the casino address.
    /// #sender: account-0
    /// #value: 5
    function testContractCreated() public payable {
        Assert.equal(msg.sender, acc0, 'acc0 should be the sender of this function check');
        Assert.equal(msg.value, 5, '2 should be the value of this function check');
        contract_created();
        Assert.equal(get_balance(), msg.value, 'balance of contract should be 5 (how much casino put in)');
        Assert.equal(get_casino(), msg.sender, 'casino should be set to acc1');
    }
    
    // Account 1 starts a game with 1 wei and submits a choice of 0.
    // Tests if player choice is commited correctly and if the balance of the contract increased.
    /// #sender: account-1
    /// #value: 1
    function testPlayer1Commit() public payable {
        Assert.equal(msg.sender, acc1, 'acc1 should be the sender of this function check');
        Assert.equal(msg.value, 1, '1 should be the value of this function check');
        uint init_balance = get_balance();
        player_commit(0);
        int gameIdx = get_game_idx(msg.sender);
        Assert.equal(gameIdx, 0, 'Account 1 should be a player in a game now');
        Assert.equal(get_balance(), init_balance + 1, 'Balance of contract should be 6 (5 initial from casino + 1 from player');
        Assert.equal(Games[uint(gameIdx)].player_choice, 0, 'Player 1 choice should be 0');
    }
    
    // Account 2 starts a game with 1 wei and submits a choice of 1.
    // Tests if player choice is commited correctly and if the balance of the contract increased.
    /// #sender: account-2
    /// #value: 1
    function testPlayer2Commit() public payable {
        Assert.equal(msg.sender, acc2, 'acc2 should be the sender of this function check');
        Assert.equal(msg.value, 1, '1 should be the value of this function check');
        uint init_balance = get_balance();
        player_commit(1);
        int gameIdx = get_game_idx(msg.sender);
        Assert.equal(gameIdx, 1, 'Account 2 should be a player in a game now');
        Assert.equal(get_balance(), init_balance + 1, 'Balance of contract should be 7 (6 current + 1 from acc2');
        Assert.equal(Games[uint(gameIdx)].player_choice, 1, 'Player 2 choice should be 1');
    }
    
    // Number of active games in the contract should be 2 now.
    function checkNumberOfActiveGames() public {
        Assert.equal(Games.length, 2, "Number of games in the contract should be 2 now.");
    }
    
    function testCasinoRandom() public {
        for(uint i = 0; i < Games.length; i ++) {
            Assert.notEqual(Games[i].randomResult, 0, "Random should not be 0");
        }
    }
    
    // Balance should be 5 (initial) + 2 (player1 and player2) = 7 total
    function checkBalance() public {
        Assert.equal(get_balance(), 7, "Balance should be 5 (initial) + 2 (player1 and player2) = 7");
    }
    
    // Casino commits to all active games.
    // Successful commit to all games means that they should now be in the Reveal state.
    /// #sender: account-0
    function testCasinoCommit() public {
        casino_commit_all_games();
        for(uint i = 0; i < Games.length; i ++) {
            Assert.equal(uint(Games[i].state), 3, "State of all the active games should now be in the Reveal state.");
        }
    }
    
    // Player 1 reveals.
    // Successful reveal means that the hashing is equal and that no illegal choices have been made and state should be Result state now.
    /// #sender: account-1
    function testPlayer1Reveal() public {
        player_reveal();
        int gameIdx = get_game_idx(msg.sender);
        Assert.equal(uint(Games[uint(gameIdx)].state), 4, 'State should be Result state after successful reveal.');
    }
    
    // Player 1 requests to compute results.
    // The game should go to the Finished state and money should go to the player. Balance should be 7-2=5. 
    /// #sender: account-1
    function testPlayer1Results() public {
        uint init_balance = get_balance();
        compute_result();
        // Assert.equal(get_balance(), init_balance - 2, 'Balance of contract should be 5 (7 - 2 from loss'); // Cannot test with working randomness
        Assert.equal(uint(FinishedGames[0].state), 5, 'State should be Finished state after successful compute result.');
    }
    
    // Player 2 reveals.
    // Successful reveal means that the hashing is equal and that no illegal choices have been made and state should be Result state now.
    /// #sender: account-2
    function testPlayer2Reveal() public {
        player_reveal();
        int gameIdx = get_game_idx(msg.sender);
        Assert.equal(uint(Games[uint(gameIdx)].state), 4, 'State should be Result state after successful reveal.');
    }
    
    // Player 2 requests to compute results.
    // The game should go to the Finished state and money should stay in the contract (player 2 loses). Balance should be 5-0=5. 
    /// #sender: account-2
    function testPlayer2Results() public {
        uint init_balance = get_balance();
        compute_result();
        // Assert.equal(get_balance(), init_balance - 0, 'Balance of contract should be 5 (5 - 0 from winning'); // Cannot test with working randomness
        Assert.equal(uint(FinishedGames[1].state), 5, 'State should be Finished state after successful compute result.');
    }
    
    /*
    function checkBalanceAfterOneWinOneLoss() public {
        Assert.equal(get_balance(), 5, "Balance should be 5 [5 (init) + 1 (player 1) + 1 (player 2) - 2 (loss) - 0 (win) = 5]");
    }
    */
    
    // Account 1 starts another game with 1 wei and submits a choice of 0.
    // Tests if player choice is commited correctly and if the balance of the contract increased.
    /// #sender: account-1
    /// #value: 1
    function testPlayer1CommitsAgain() public payable {
        Assert.equal(msg.sender, acc1, 'acc1 should be the sender of this function check');
        Assert.equal(msg.value, 1, '1 should be the value of this function check');
        uint init_balance = get_balance();
        player_commit(0);
        int gameIdx = get_game_idx(msg.sender);
        Assert.equal(gameIdx, 0, 'Account 1 should be a player in a game now');
        Assert.equal(get_balance(), init_balance + 1, 'Balance of contract should be 6 (5 + 1)');
        Assert.equal(Games[uint(gameIdx)].player_choice, 0, 'Player 1 choice should be 0');
    }
    
    // Casino commits to all active games again.
    // Successful commit to all games means that they should now be in the Reveal state.
    /// #sender: account-0
    function testCasinoCommitsAgain() public {
        casino_commit_all_games();
        for(uint i = 0; i < Games.length; i ++) {
            Assert.equal(uint(Games[i].state), 3, "State of all the active games should now be in the Reveal state.");
        }
    }
    
    // Player 1 reveals again.
    // Successful reveal means that the hashing is equal and that no illegal choices have been made and state should be Result state now.
    /// #sender: account-1
    function testPlayer1RevealsAgain() public {
        player_reveal();
        int gameIdx = get_game_idx(msg.sender);
        Assert.equal(uint(Games[uint(gameIdx)].state), 4, 'State should be Result state after successful reveal.');
    }
    
    // Player 1 requests to compute results again.
    // The game should go to the Finished state and money should go to the player. Balance should be 7-2=5. 
    /// #sender: account-1
    function testPlayer1ResultsAgain() public {
        uint init_balance = get_balance();
        compute_result();
        // Assert.equal(get_balance(), init_balance - 2, 'Balance of contract should be 3 (5 - 2 from loss'); //// Cannot test with working randomness
        Assert.equal(uint(FinishedGames[2].state), 5, 'State should be Finished state after successful compute result.');
    }
}
