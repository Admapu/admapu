ifneq (,$(wildcard ./.env))
    include .env
    export
endif

USER_ADDR ?=
FROM_BLOCK ?= 10320000
MINTER ?= $(TOKEN)
FORWARDER ?=
USER_PK ?=
TX_GAS_LIMIT ?=
TX_MAX_FEE ?=
TX_PRIORITY_FEE ?=

TX_FEE_OPTS := $(if $(TX_GAS_LIMIT),--gas-limit "$(TX_GAS_LIMIT)",) \
	$(if $(TX_MAX_FEE),--gas-price "$(TX_MAX_FEE)",) \
	$(if $(TX_PRIORITY_FEE),--priority-gas-price "$(TX_PRIORITY_FEE)",)

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
	@echo "BlockNumber, Address"
	@cast logs --rpc-url "$(SEPOLIA_RPC_URL)" --address "$(VERIFIER)" --from-block "$(FROM_BLOCK)" --to-block latest --json "AddressVerified(address,uint256)" | jq -r '.[] | "\(.blockNumber), \(.topics[1] | sub("^0x000000000000000000000000";"0x"))"'

list-revoked: ## List revoked wallets with block number. Requires FROM_BLOCK env variable
	@echo "BlockNumber, Address"
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
	@cast send "$(TOKEN)" "transfer(address,uint256)" "$(TO)" "$(AMOUNT)" $(TX_FEE_OPTS) --rpc-url "$(SEPOLIA_RPC_URL)" --private-key "$(FROM_PK)"

##@ Claim operations
check-claim: ## Check if USER_ADDR already claimed. Requires USER_ADDR env variable
	@cast call "$(CLAIM)" "claimed(address)(bool)" "$(USER_ADDR)" --rpc-url "$(SEPOLIA_RPC_URL)"

check-claim-amount: ## Show fixed claim amount from ClaimCLPc
	@cast call "$(CLAIM)" "CLAIM_AMOUNT()(uint256)" --rpc-url "$(SEPOLIA_RPC_URL)"

claim-direct: ## Claim as USER_PK (user pays gas). Requires USER_PK env variable
	@cast send "$(CLAIM)" "claim()" $(TX_FEE_OPTS) --rpc-url "$(SEPOLIA_RPC_URL)" --private-key "$(USER_PK)"

grant-claim-minter: ## Grant MINTER_ROLE on TOKEN to CLAIM using DEPLOYER_PK
	@MINTER_ROLE=$$(cast call "$(TOKEN)" "MINTER_ROLE()(bytes32)" --rpc-url "$(SEPOLIA_RPC_URL)"); \
	cast send "$(TOKEN)" "grantRole(bytes32,address)" "$$MINTER_ROLE" "$(CLAIM)" --rpc-url "$(SEPOLIA_RPC_URL)" --private-key "$(DEPLOYER_PK)"

check-claim-minter: ## Check if CLAIM has MINTER_ROLE on TOKEN
	@MINTER_ROLE=$$(cast call "$(TOKEN)" "MINTER_ROLE()(bytes32)" --rpc-url "$(SEPOLIA_RPC_URL)"); \
	cast call "$(TOKEN)" "hasRole(bytes32,address)(bool)" "$$MINTER_ROLE" "$(CLAIM)" --rpc-url "$(SEPOLIA_RPC_URL)"

check-claim-config: ## Show Claim wiring against Token identity registry
	@echo "CLAIM.TOKEN               = $$(cast call "$(CLAIM)" "TOKEN()(address)" --rpc-url "$(SEPOLIA_RPC_URL)")"; \
	echo "TOKEN (env)               = $(TOKEN)"; \
	echo "CLAIM.IDENTITY_REGISTRY   = $$(cast call "$(CLAIM)" "IDENTITY_REGISTRY()(address)" --rpc-url "$(SEPOLIA_RPC_URL)")"; \
	echo "TOKEN.identityRegistry    = $$(cast call "$(TOKEN)" "identityRegistry()(address)" --rpc-url "$(SEPOLIA_RPC_URL)")"; \
	echo "CLAIM_AMOUNT              = $$(cast call "$(CLAIM)" "CLAIM_AMOUNT()(uint256)" --rpc-url "$(SEPOLIA_RPC_URL)")"

##@ Transport benefit
check-transport-period: ## Show current claim period for TransportBenefit
	@cast call "$(TRANSPORT)" "currentPeriod()(uint256)" --rpc-url "$(SEPOLIA_RPC_URL)"

check-transport-claimed: ## Check if USER_ADDR already claimed in PERIOD. Requires USER_ADDR and PERIOD env variables
	@cast call "$(TRANSPORT)" "claimedByPeriod(address,uint256)(bool)" "$(USER_ADDR)" "$(PERIOD)" --rpc-url "$(SEPOLIA_RPC_URL)"

check-transport-amount: ## Show fixed monthly amount from TransportBenefit
	@cast call "$(TRANSPORT)" "BENEFIT_AMOUNT()(uint256)" --rpc-url "$(SEPOLIA_RPC_URL)"

check-transport-eligible: ## Check if USER_ADDR is eligible for school transport. Requires USER_ADDR env variable
	@cast call "$(TRANSPORT)" "eligibleSchoolTransport(address)(bool)" "$(USER_ADDR)" --rpc-url "$(SEPOLIA_RPC_URL)"

set-transport-eligible: ## Set transport eligibility for USER_ADDR. Requires USER_ADDR and ELIGIBLE env variables
	@cast send "$(TRANSPORT)" "setEligible(address,bool)" "$(USER_ADDR)" "$(ELIGIBLE)" --rpc-url "$(SEPOLIA_RPC_URL)" --private-key "$(DEPLOYER_PK)"

claim-transport-direct: ## Claim monthly transport benefit as USER_PK (user pays gas). Requires USER_PK env variable
	@cast send "$(TRANSPORT)" "claim()" $(TX_FEE_OPTS) --rpc-url "$(SEPOLIA_RPC_URL)" --private-key "$(USER_PK)"

grant-transport-minter: ## Grant MINTER_ROLE on TOKEN to TRANSPORT using DEPLOYER_PK
	@MINTER_ROLE=$$(cast call "$(TOKEN)" "MINTER_ROLE()(bytes32)" --rpc-url "$(SEPOLIA_RPC_URL)"); \
	cast send "$(TOKEN)" "grantRole(bytes32,address)" "$$MINTER_ROLE" "$(TRANSPORT)" --rpc-url "$(SEPOLIA_RPC_URL)" --private-key "$(DEPLOYER_PK)"

check-transport-minter: ## Check if TRANSPORT has MINTER_ROLE on TOKEN
	@MINTER_ROLE=$$(cast call "$(TOKEN)" "MINTER_ROLE()(bytes32)" --rpc-url "$(SEPOLIA_RPC_URL)"); \
	cast call "$(TOKEN)" "hasRole(bytes32,address)(bool)" "$$MINTER_ROLE" "$(TRANSPORT)" --rpc-url "$(SEPOLIA_RPC_URL)"

check-transport-config: ## Show TransportBenefit wiring against Token identity registry
	@echo "TRANSPORT.TOKEN           = $$(cast call "$(TRANSPORT)" "TOKEN()(address)" --rpc-url "$(SEPOLIA_RPC_URL)")"; \
	echo "TOKEN (env)               = $(TOKEN)"; \
	echo "TRANSPORT.IDENTITY_REGISTRY = $$(cast call "$(TRANSPORT)" "IDENTITY_REGISTRY()(address)" --rpc-url "$(SEPOLIA_RPC_URL)")"; \
	echo "TOKEN.identityRegistry    = $$(cast call "$(TOKEN)" "identityRegistry()(address)" --rpc-url "$(SEPOLIA_RPC_URL)")"; \
	echo "TRANSPORT.BENEFIT_AMOUNT  = $$(cast call "$(TRANSPORT)" "BENEFIT_AMOUNT()(uint256)" --rpc-url "$(SEPOLIA_RPC_URL)")"; \
	echo "TRANSPORT.admin           = $$(cast call "$(TRANSPORT)" "admin()(address)" --rpc-url "$(SEPOLIA_RPC_URL)")"

##@ Meta-transactions (ERC-2771)
set-forwarder: ## Set trusted forwarder in ClaimCLPc. Requires FORWARDER env variable
	@cast send "$(CLAIM)" "setTrustedForwarder(address)" "$(FORWARDER)" --rpc-url "$(SEPOLIA_RPC_URL)" --private-key "$(DEPLOYER_PK)"

check-forwarder: ## Show trusted forwarder configured in ClaimCLPc
	@cast call "$(CLAIM)" "trustedForwarder()(address)" --rpc-url "$(SEPOLIA_RPC_URL)"

check-forwarder-match: ## Check if FORWARDER is trusted in ClaimCLPc. Requires FORWARDER env variable
	@cast call "$(CLAIM)" "isTrustedForwarder(address)(bool)" "$(FORWARDER)" --rpc-url "$(SEPOLIA_RPC_URL)"

set-token-forwarder: ## Set trusted forwarder in CLPc token. Requires FORWARDER env variable
	@cast send "$(TOKEN)" "setTrustedForwarder(address)" "$(FORWARDER)" --rpc-url "$(SEPOLIA_RPC_URL)" --private-key "$(DEPLOYER_PK)"

check-token-forwarder: ## Show trusted forwarder configured in CLPc token
	@cast call "$(TOKEN)" "trustedForwarder()(address)" --rpc-url "$(SEPOLIA_RPC_URL)"

check-token-forwarder-match: ## Check if FORWARDER is trusted in CLPc token. Requires FORWARDER env variable
	@cast call "$(TOKEN)" "isTrustedForwarder(address)(bool)" "$(FORWARDER)" --rpc-url "$(SEPOLIA_RPC_URL)"

set-transport-forwarder: ## Set trusted forwarder in TransportBenefit. Requires FORWARDER env variable
	@cast send "$(TRANSPORT)" "setTrustedForwarder(address)" "$(FORWARDER)" --rpc-url "$(SEPOLIA_RPC_URL)" --private-key "$(DEPLOYER_PK)"

check-transport-forwarder: ## Show trusted forwarder configured in TransportBenefit
	@cast call "$(TRANSPORT)" "trustedForwarder()(address)" --rpc-url "$(SEPOLIA_RPC_URL)"

check-transport-forwarder-match: ## Check if FORWARDER is trusted in TransportBenefit. Requires FORWARDER env variable
	@cast call "$(TRANSPORT)" "isTrustedForwarder(address)(bool)" "$(FORWARDER)" --rpc-url "$(SEPOLIA_RPC_URL)"

send-calldata: ## Print calldata for transfer(address,uint256). Requires TO and AMOUNT env variables
	@cast calldata "transfer(address,uint256)" "$(TO)" "$(AMOUNT)"

claim-calldata: ## Print calldata for claim() (useful for relayer requests)
	@cast calldata "claim()"

claim-transport-calldata: ## Print calldata for TransportBenefit.claim() (useful for relayer requests)
	@cast calldata "claim()"

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} \
	/^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } \
	/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
