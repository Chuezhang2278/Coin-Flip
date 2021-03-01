# Coin-Flip Instructions
## Dependencies
- Solidity
- RemixIDE
## Important Notes 
### There are some particular bugs that we are aware about
At times when trying to use compute_result button, an error will be thrown saying that the called function should be payable...if such an error occurs, please refresh the webpage and redo instruction steps. The error seems to be caused by too long of a delay or if a function is run right before another function is complete. I.E you press commit_player then immediately press casino_commit.
### ChainlinkVRF
We have run into some bugs regarding chainlinkVRF and will not be using it in this demo and have set the random result to always be 100. We are aware that we can use the keccak method to generate psuedo-randomness however, we set the casinos random result to 100 for simplicity sake and because this is a test project.
<br> ` Please disregard rawFulfillRandomness on deployment, that is related to chainlinkVRF `
## Instructions 
#### Legend
- ![#f03c15](https://via.placeholder.com/15/f03c15/000000?text=+) ![#ff9900](https://via.placeholder.com/15/ff9900/000000?text=+) `Red and Orange Buttons are for interactions!`
- ![#1589F0](https://via.placeholder.com/15/1589F0/000000?text=+) `Blue Buttons are for information!`
#### How to use
1. `Download our CoinFlip.sol file and deploy using RemixIDE.`
</br>  Make sure that you deploy with a value set to initialize the contract with I.E. 1 wei otherwise you will get an error!
2. `After deployment, swap to another wallet and commit a value "1" (tails) or "0" (heads) to the 'player_commit' button and pay 1 wei`
</br> To pay 1 wei, just make sure the "value" above the deploy button is 1 and the tab is set to wei then press player_commit 
3. `Go back to the first wallet you used to deploy the contract and press 'casino_commit'`
</br>  This is a temporary method we are using to test the game out, method will not be present in Final Project 
4. `Swap back to the second wallet and press player_reveal then compute_result`
5. `Press the blue 'result' button to see whether you win or lose`

