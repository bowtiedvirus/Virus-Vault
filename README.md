## Virus Vault, Composable Cross-Chain Vault

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

Future notes:
    - Making the underlying token cross-chain transferable would be a cool idea but requires more complexity in calculating totalAssets and only allows certain tokens at the moment (some test link burn and mint token on testnets).
    - As of commit `f5cda9c`, the basic vault and MakerDao DSR strategy is a-ok. I will be attempting to make the share token cross chain now.
