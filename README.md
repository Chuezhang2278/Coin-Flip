# Coin-Flip Instructions
## Dependencies
- Solidity
- RemixIDE
## Disclaimer
There are some particular bugs that we are aware about that cannot be fixed 
- At times when trying to use compute_result button, an error will be thrown saying that the called function should be payable...if such an error occurs, please refresh the webpage and redo instruction steps. The error seems to be caused by too long of a delay or if a function is run right before another function is complete. I.E you press commit_player then immediately press commit_casino.
## Instructions 
In this demo, we will **NOT** be using chainlinkVRF for compilation reason.
</br>
**Yellow/Red** buttons in the contract are functions that are used to play the game
</br> 
**Blue buttons** are for debugging, in your case, it will be used to confirm correctness in the system
</br>
Please ignore the Yellow button "RawFulfillRand..." That is chainlinkVRF and is irrelevant for the demo
1. Get a copy of the files in this repo via forking or copy and paste (Files are the coinflip.sol and coinflip_test.sol)
2. Deploy the contract on remixIDE
3. After deployment, open up the contract.. it should look like this https://i.imgur.com/qXDGiPv.png 
4. Copy your current wallet address and paste it into the contract_creat... function along with a balance https://i.imgur.com/66GmuQU.png
5. Switch to another wallet, enter 1 "wei" and commit a "0" or "1" value, 0 indicating heads and 1 indicating tales. https://i.imgur.com/GmDAhPv.png
6. Swap back to the first wallet you used and press commit_casino.
7. Afterwards, press compute_result
8. Press the result button to see outcome https://i.imgur.com/4uDwCIJ.png
