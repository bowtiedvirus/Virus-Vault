## Virus Vault, Composable Cross-Chain Vault

## Usage

### Configure Environment Variables
```
# .env
MAINNET_RPC_URL=<x>
PRIVATE_KEY=<z>
```

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Slither Check ERC Results
```
# Check Vault

## Check functions
[✓] totalSupply() is present
        [✓] totalSupply() -> (uint256) (correct return type)
        [✓] totalSupply() is view
[✓] balanceOf(address) is present
        [✓] balanceOf(address) -> (uint256) (correct return type)
        [✓] balanceOf(address) is view
[✓] transfer(address,uint256) is present
        [✓] transfer(address,uint256) -> (bool) (correct return type)
        [✓] Transfer(address,address,uint256) is emitted
[✓] transferFrom(address,address,uint256) is present
        [✓] transferFrom(address,address,uint256) -> (bool) (correct return type)
        [✓] Transfer(address,address,uint256) is emitted
[✓] approve(address,uint256) is present
        [✓] approve(address,uint256) -> (bool) (correct return type)
        [✓] Approval(address,address,uint256) is emitted
[✓] allowance(address,address) is present
        [✓] allowance(address,address) -> (uint256) (correct return type)
        [✓] allowance(address,address) is view
[✓] name() is present
        [✓] name() -> (string) (correct return type)
        [✓] name() is view
[✓] symbol() is present
        [✓] symbol() -> (string) (correct return type)
        [✓] symbol() is view
[✓] decimals() is present
        [✓] decimals() -> (uint8) (correct return type)
        [✓] decimals() is view

## Check events
[✓] Transfer(address,address,uint256) is present
        [✓] parameter 0 is indexed
        [✓] parameter 1 is indexed
[✓] Approval(address,address,uint256) is present
        [✓] parameter 0 is indexed
        [✓] parameter 1 is indexed
        [ ] Vault is not protected for the ERC20 approval race condition
```

Future notes:
    - Making the underlying token cross-chain transferable would be a cool idea but requires more complexity in calculating totalAssets and only allows certain tokens at the moment (some test link burn and mint token on testnets).
    - Doesn't handle Native tokens by default, but does allows wrapped native tokens. (Maybe an idea to do later)
    - As of commit `f5cda9c`, the basic vault and MakerDao DSR strategy is a-ok. I will be attempting to make the share token cross chain now.
