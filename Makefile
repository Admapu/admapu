ifneq (,$(wildcard ./.env))
    include .env
    export
endif

USER_ADDR ?=
FROM_BLOCK ?= 9981114
MINTER ?= $(TOKEN)

.PHONY: help

.DEFAULT_GOAL := help

##@ User management
whitelist-user: ## Verify a wallet as chilean-verified user. Requires USER_ADDR env variable
	@cast send "$(VERIFIER)" "verify(address)" "$(USER_ADDR)" --rpc-url "$(SEPOLIA_RPC_URL)" --private-key "$(DEPLOYER_PK)"

check-user: ## Check if a wallet is chilean-verified user. Requires USER_ADDR env variable
	@cast call "$(VERIFIER)" "isVerified(address)(bool)" "$(USER_ADDR)" --rpc-url "$(SEPOLIA_RPC_URL)"

revoke-user: ## Revoke a wallet as chilean-verified user. Requires USER_ADDR env variable
	@cast send "$(VERIFIER)" "revoke(address)" "$(USER_ADDR)" --rpc-url "$(SEPOLIA_RPC_URL)" --private-key "$(DEPLOYER_PK)"

list-added: ## List verified wallets with block number. Requires FROM_BLOCK env variable
	@cast logs --rpc-url "$(SEPOLIA_RPC_URL)" --address "$(VERIFIER)" --from-block "$(FROM_BLOCK)" --to-block latest --json "AddressVerified(address,uint256)" | jq -r '.[] | "\(.blockNumber), \(.topics[1] | sub("^0x000000000000000000000000";"0x"))"'

list-revoked: ## List revoked wallets with block number. Requires FROM_BLOCK env variable
	@cast logs --rpc-url "$(SEPOLIA_RPC_URL)" --address "$(VERIFIER)" --from-block "$(FROM_BLOCK)" --to-block latest --json "VerificationRevoked(address,uint256)" | jq -r '.[] | "\(.blockNumber), \(.topics[1] | sub("^0x000000000000000000000000";"0x"))"'

##@ Age range defintion
set-age: ## Set age for a verified user. Requires USER_ADDR env variable and age flags: over18, over65.
	@cast send "$(VERIFIER)" "setAgeFlags(address,bool,bool)" "$(USER_ADDR)" true false --rpc-url "$(SEPOLIA_RPC_URL)" --private-key "$(DEPLOYER_PK)"

check-over18: ## Check if a verified user is over 18. Requires USER_ADDR env variable
	@cast call "$(VERIFIER)" "isOver18(address)(bool)" "$(USER_ADDR)" --rpc-url "$(SEPOLIA_RPC_URL)"

check-over65: ## Check if a verified user is over 65. Requires USER_ADDR env variable
	@cast call "$(VERIFIER)" "isOver65(address)(bool)" "$(USER_ADDR)" --rpc-url "$(SEPOLIA_RPC_URL)"

##@ Mint status and token management
check-status: ## Check if minting is paused or not. Result: true = paused, false = unpaused
	@cast call "$(MINTER)" "mintingPaused()(bool)" --rpc-url "$(SEPOLIA_RPC_URL)"

mint: ## Mint more CLPc tokens. Requires AMOUNT env variable, consider 8 decimals
	@cast send "$(TOKEN)" "mint(address,uint256)" "$(USER_ADDR)" "$(AMOUNT)" --rpc-url "$(SEPOLIA_RPC_URL)" --private-key "$(DEPLOYER_PK)"

##@ Token transfer
send: ## Send CLPc tokens to a verified user. Both sender and receiver must be verified. Requires TO and AMOUNT env variables, consider 8 decimals
	@cast send "$(TOKEN)" "transfer(address,uint256)" "$(TO)" "$(AMOUNT)" --rpc-url "$(SEPOLIA_RPC_URL)" --private-key "$(FROM_PK)"

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} \
	/^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } \
	/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
