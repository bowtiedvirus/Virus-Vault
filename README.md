# Virus Vault, Composable Cross-Chain Vault

## A summary of what was done
This little Virus made an ERC4626 Compliant Vault for the 2023 jungle hackathon. The vault can be broken down into a few components.
1. ERC4626 Vault
2. YieldStrategy
3. Cross Chain Share Tokens

### ERC4626 Vault
I utilized solmate's underlying implementation of ERC4626. Their implementation was a simpler one, whereas OZ has virtual shares and other more advanced things it does to mitigate inflation attacks. In this case, I really like the existing beforeWithdraw and afterDeposit hooks. I saw this as a way to keep the primary ERC4626 functionality as is and create "plugins" to the periphery of the Vault. I had trouble with `totalAssets` initially, because I missed the part of the EIP4626 that explained that it must include all assets managed by the Vault, so I had to make sure that assets "owned" by something else was included in the Vault. I saw an opportunity to utilize delegatecall, which I've only ever seen used for upgrade patterns, never used it myself. That brings me to component 2: YieldStrategy.

### Yield Strategy
There are potentially infinite Yield Strategies a vault could utilize. N Liquidity Pools, M staking protocols, O lending protocols, and more. It was clear that utilizing delegatecall would allow me to keep the 'Yield Bearing' logic seperate from the shareholder logic. Encapsulated logic should help the Vault be re-usable should someone wish to build off of me. I did some reading about delegatecall, some phind queries, and figured out that I could just avoid any storage slot confusion by passing data to the YieldStrategy implementation as I went.* Made a YieldStrategy interface and made up a mock YieldStrategy for me to use in testing. After testing with that, I moved onto implementing the DSR/MakerDAO strategy. It was kinda hard to manage the testing for this, since there were tiny fees that I wasn't able to figure out how to calculate. Therefore, my tests checked return values with a little bit of slippage (in all cases it was a single wei).

I initially built the vault under the assumption that the asset deposited to the vault would also be the asset directly used in the YieldStrategy. This made sense for a DAI vault, with a Dai Savings Rate Yield Strategy. Though, that's not a very composable Vault protocol then, is it? So, I decided to take a crack at utilizing price oracles and uniswap to convert to/from DAI and the underlying asset, which imo is still a little limited since it requires a direct swap pair on Uniswap. Uniswap v2 is MUCH quicker to use than v3, so I went with that. It still has quite a bit of liquidity and could be swapped out later, in a new YieldStrategy. I think this part was the hardest section of the project. Managing ERC20's with different decimals() led to some confusing bugs. I had to read docs for Uniswap v3, Link price oracles, Uniswap v2, etc. Despite the struggle, I think I managed something that is sane and mostly correct.

### Cross Chain Share Tokens
For this section: I wanted to explore Cross Chain tech because I find it interesting. I decided to use CCIP because it's new and somewhat simple to use. I split this into two sections and only built the first 'MVP' of it, but don't have any e2e tests to check it's function, just unit tests.

1. Send Shares Cross Chain. Allow cross-chain vault share arbitrage.
2. Cross Chain Accounting System.

#### Cross Chain Shares
This one is pretty simple, since I can 'control' the share mint and burn. I created a VaultManager on both the Sender and Receiver side that validate messages sent and received, then call certain functions on the Vault if instructed to. A user could call `sendSharesCrossChain()`, burn their tokens, and send a `crossChainMint()` to an approved destination chain. Upon arrival, the destination chain vault would mint shares to the address sent in `sendSharesCrossChain()`. I could probably do a better job with encoding the message sent and validating that the user is able to actually send all the tokens they try to.

I mentioned that there is a `cross-chain vault share arbitrage` that could happen here. Using the share mint formula: `shares = (asset deposit * totalShareSupply) / totalAssets`...
1. Vault A, Chain A has a 1:1 `totalShareupply/totalAsset` ratio: (100 shares / 100 assets)
2. Vault B, Chain B has a 2:1 `totalShareSupply/totalAsset` ratio: (100 shares / 200 assets)
3. Alice has 100 ARB token to deposit into one of the vaults, she'd like to get the biggest bang for her capital deployment.
4. She uses the formula to calculate expected share count on both Chains.
5. Vault A: 100 Shares. Vault B: 50 shares.
6. Alice deposits to Vault A, sends her 100 shares over to Vault B, redeems her 100 shares, gets a larger portion of Vault B than she would have if she minted on Vault A in the first place.
7. This may incentivize actors to act to keep totalShareSupply and TotalAsset as close to a 1:1 ratio as possible.

This thought experiment was very 'tistic. I know. I was doing math on paper for this.

#### Cross Chain Accounting System
This one is pretty self-explanatory. There would be a single "Commander" chain that tracks the totalSupply and totalAssets on each chain. Upon mint, burn, each peripheral Vault would send a message to the Commander Vault. The commander would then update it's state, then send a message to each Periphery to update their state with the new totalSupply and totalAssets. In distributed system design, this would be a star formation or whatever those nerds call it.

This global accounting system would make it much more complex to take advantage of arbitrage between vaults. Assets still won't be able to transfer chains, as that requires the use of a bridge of some sort. This also incurs a cost from the cross chain infra. However, the value of a share is the same across all the chains, no matter where you deposit the assets.

## Usage

## Configure Environment Variables
```
# .env
MAINNET_RPC_URL=<x>
PRIVATE_KEY=<z>
```

## Install

```shell
$ forge install && yarn
```

## Build

```shell
$ forge build
```

## Test

```shell
$ forge test
```


Future notes:
    - Doesn't handle Native tokens by default, but does allows wrapped native tokens. (Maybe an idea to do later)
