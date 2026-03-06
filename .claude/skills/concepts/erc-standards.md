---
description: ERC standards — the Ethereum token and interface standards (ERC20, ERC721, ERC1155, ERC4626) that define expected behavior contracts must implement for ecosystem compatibility.
tags: [standards, solidity, tokens, defi]
links: [access-control, reentrancy, phase-05-standards]
---

# ERC Standards

ERC standards define behavioral interfaces that tokens and vaults must implement for compatibility with wallets, DEXes, lending protocols, and other DeFi infrastructure. Deviating from standard behavior causes silent integration failures.

## ERC20

The fungible token standard. Critical compliance issues:
- `transfer` and `transferFrom` must return `bool`. Some tokens (USDT) do not — protocols using `SafeERC20` handle this; those calling directly may revert or silently lose funds.
- `approve` + `transferFrom` race condition: the allowance can be front-run between an approval decrease and a new spend. ERC20 `increaseAllowance`/`decreaseAllowance` or EIP-2612 permit patterns mitigate this.
- Fee-on-transfer tokens: some ERC20 tokens take a fee on every transfer. Protocols that assume `transferred amount == amount parameter` will have accounting errors.

## ERC721

Non-fungible token standard. Key compliance issues:
- `safeTransferFrom` calls `onERC721Received` on the recipient. This is an external call — [[reentrancy]] protection is required if state is modified before this call.
- Contracts receiving ERC721 tokens must implement `IERC721Receiver` or tokens sent via `safeTransferFrom` will revert.

## ERC4626

Tokenized vault standard. Compliance matters for [[access-control]]:
- `deposit`/`mint` and `withdraw`/`redeem` must match the spec precisely; incorrect share/asset accounting creates rounding exploits.
- Inflation attacks: the first depositor can donate assets to inflate the share price and steal subsequent depositors' funds. Protocols must use virtual shares or minimum initial deposit protections.

## Skills that Check ERC Compliance

- `erc-compliance-validator.sh` — validates ERC20/721/1155/4626 interface compliance and common deviation patterns
- `event-emission-check.sh` — validates that required events (Transfer, Approval) are emitted per spec

```bash
./domains/smart-contracts/erc-compliance-validator.sh | jq .artifacts.violations
./domains/smart-contracts/event-emission-check.sh | jq .artifacts.missing_events
```

## Signals

- `"status":"fail"` from `erc-compliance-validator.sh` — interface mismatch or missing required function
- `"status":"warn"` — fee-on-transfer or rebasing token behavior without protocol awareness

## Related Concepts

- [[access-control]] — ERC20 approve/transferFrom create access delegation surfaces requiring scrutiny
- [[reentrancy]] — ERC721 safeTransferFrom makes external calls; reentrancy guards required if state is modified first
