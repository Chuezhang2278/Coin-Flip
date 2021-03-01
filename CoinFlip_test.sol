// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.6;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "remix_accounts.sol";
import "../contracts/CoinFlip.sol"; // make sure directory of this is correct!


/// #value: 2
contract CoinFlipTest is CoinFlip{
    
    // Define variables referring to different accounts
    address acc0; // casino
    address acc1; // player
    
    function beforeAll () public returns (bool) {
        acc0 = TestsAccounts.getAccount(0); 
        acc1 = TestsAccounts.getAccount(1);
    }
    
    /// #sender: account-0
    /// #value: 2
    function testContractCreated() public payable {
        Assert.equal(msg.sender, acc0, 'acc0 should be the sender of this function check');
        Assert.equal(msg.value, 2, '2 should be the value of this function check');
        contract_created(msg.sender, msg.value);
        Assert.equal(get_casino(), msg.sender, 'casino should be set to acc1');
        Assert.equal(get_balance(), msg.value, 'balance of contract should be 2 (how much casino put in)');
    }
    
    function checkStatePlayer() public {
        Assert.equal(uint256(state), 1, 'state should be player state now');
    }
    
    /// #sender: account-1
    /// #value: 1
    function testPlayerCommit() public payable {
        Assert.equal(msg.sender, acc1, 'acc1 should be the sender of this function check');
        Assert.equal(msg.value, 1, '1 should be the value of this function check');
        player_commit(0);
        Assert.equal(get_player(), acc1, 'player should be set to acc1');
        Assert.equal(get_balance(), 3, 'balance of contract should be 3 (2 initial from casino + 1 from player');
        Assert.equal(get_player_choice(), 0, 'player choice should be 0');
    }
    
    // Check if the user commit is successful, if it is -> go to State.Casino
    function checkStateCasino() public {
        Assert.equal(uint256(state), 2, 'state should be casino state now');
    }
    
    // Check if random number has been generated *(Note that we can't unit test with ChainLink VRF, however, it does create randomness)
    function randomNotEqualTo0() public {
        Assert.notEqual(randomResult, 0, 'Random result should be generated and it should not be 0'); // Because we can't test VRF, we have to use a placeholder randomResult when unit testing
    }
    
    // Check if the casino's commited a choice or not
    /// #sender: account-0
    function testCasinoCommit() public {
        Assert.equal(msg.sender, acc0, 'casino should be the sender of this function check');
        casino_commit();
        Assert.equal(get_casino_choice(), 0, 'casino choice should be 0');
    }
    
    // Check if the casino commit is successful, if it is -> go to State.Reveal
    function checkStateReveal() public {
        Assert.equal(uint256(state), 3, 'state should be reveal state now');
    }
    
    // Tests the reveal of the player and check if anything has been changed
    /// #sender: account-1
    function testReveal() public {
        player_reveal();
        Assert.equal(uint(state), 4, "if no illegal moves happened during the reveal, we move on to results");
    }
    
    // Check if the reveal is successful, if it is -> go to State.Result
    function checkStateResult() public {
        Assert.equal(uint256(state), 4, 'state should be result state now');
    }
    
    // Tests if the money was given to the right people
    /// #sender: account-0
    function testComputeResult() public {
        uint start_balance = balance;
        compute_result();
        if(player.choice == casino.choice) { 
            Assert.equal(balance, start_balance - 2, "the money was given to the player");
        } else {
            Assert.equal(balance, start_balance, "the money stays in the casino contract");
        }
    }
}
