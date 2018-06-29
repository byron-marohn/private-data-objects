#!/bin/bash

send() (
	target="$1"
	cmd="$2"

	echo "$target : '$cmd'"
	for i in $(seq 1 ${#cmd})
	do
		tmux send-keys -t "$target" "${cmd:i-1:1}"
		sleep 0.08
	done
	sleep 0.6
	tmux send-keys -t "$target" C-m
)

left() (
	send left "$@"
)
fastleft() (
	tmux send-keys -t left "$@"
	tmux send-keys -t left C-m
)
fast() (
	fastleft "$@"
)

right() (
	send right "$@"
)
fastright() (
	tmux send-keys -t right "$@"
	tmux send-keys -t right C-m
)


################################################################################
## Script starts here
################################################################################
PAUSE=3
sleep 3

### Setup

fast ''
fast 'source ~/envvars'
fast 'export LEDGER_URL=http://127.0.0.1:8008'
fast 'source ~/private-data-objects/__tools__/build/_dev/bin/activate'
fast 'cd ~/private-data-objects/__tools__'
fast './make-keys --keyfile $VIRTUAL_ENV/opt/pdo/keys/stock_issuer --format pem'
fast './make-keys --keyfile $VIRTUAL_ENV/opt/pdo/keys/cash_issuer --format pem'
fast './make-keys --keyfile $VIRTUAL_ENV/opt/pdo/keys/stock_vetting --format pem'
fast './make-keys --keyfile $VIRTUAL_ENV/opt/pdo/keys/cash_vetting --format pem'
fast './make-keys --keyfile $VIRTUAL_ENV/opt/pdo/keys/stock_type --format pem'
fast './make-keys --keyfile $VIRTUAL_ENV/opt/pdo/keys/cash_type --format pem'
fast './make-keys --keyfile $VIRTUAL_ENV/opt/pdo/keys/Alice --format pem'
fast './make-keys --keyfile $VIRTUAL_ENV/opt/pdo/keys/Bob --format pem'
fast 'cd ~/private-data-objects'
fast 'export PATH=$PATH:${VIRTUAL_ENV}/opt/pdo/bin'
fast '$VIRTUAL_ENV/opt/pdo/bin/es-stop.sh -c 100'
fast '$VIRTUAL_ENV/opt/pdo/bin/ps-stop.sh -c 100'
fast 'cd contracts/exchange'
fast 'clear'
##TODO NAME

sleep 6

### 1
left 'ps-start.sh --count 5 --ledger ${LEDGER_URL}'
left 'es-start.sh --count 5 --ledger ${LEDGER_URL} --clean'
sleep 30

sleep $PAUSE

### 2
left 'pdo-shell --ledger $LEDGER_URL -s demo/create_cash.psh'
sleep 30
left 'pdo-shell --ledger $LEDGER_URL -s demo/create_stock.psh'
sleep 30

sleep $PAUSE

### 3
left 'pdo-shell --ledger $LEDGER_URL -s demo/issue.psh -m type stock -m issuee Alice -m count 25'
sleep 6
left 'pdo-shell --ledger $LEDGER_URL -s demo/issue.psh -m type cash -m issuee Bob -m count 100'
sleep 6

sleep $PAUSE

## Setup for part 2
tmux split-window -h

fastright ''
fastright 'source ~/envvars'
fastright 'export LEDGER_URL=http://127.0.0.1:8008'
fastright 'source ~/private-data-objects/__tools__/build/_dev/bin/activate'
fastright 'cd ~/private-data-objects'
fastright 'export PATH=$PATH:${VIRTUAL_ENV}/opt/pdo/bin'

fastright 'clear'
fastleft 'clear'
fastleft 'pdo-shell'
fastright 'pdo-shell'
sleep 1
fastleft 'load_plugin -c asset_type'
sleep 0.1
fastleft 'load_plugin -c vetting'
sleep 0.1
fastleft 'load_plugin -c issuer'
sleep 0.1
fastleft 'load_plugin -c exchange'
sleep 0.1
fastleft 'set -s path -v /home/bmarohn/private-data-objects/contracts/exchange'
fastleft 'echo'
fastleft 'identity -n Alice'
fastleft 'clear'
sleep 0.1
fastright 'load_plugin -c asset_type'
sleep 0.1
fastright 'load_plugin -c vetting'
sleep 0.1
fastright 'load_plugin -c issuer'
sleep 0.1
fastright 'load_plugin -c exchange'
sleep 0.1
fastright 'set -s path -v /home/bmarohn/private-data-objects/contracts/exchange'
fastright 'echo'
fastright 'identity -n Bob'
fastright 'clear'
sleep 0.1


sleep $PAUSE

### 4
left 'issuer -f $path/cash_issuer.pdo get_balance'
sleep 2
left 'issuer -f $path/stock_issuer.pdo get_balance'
sleep 2
right 'issuer -f $path/cash_issuer.pdo get_balance'
sleep 2
right 'issuer -f $path/stock_issuer.pdo get_balance'
sleep 2

sleep $PAUSE

### 5
left 'create -c exchange-contract -s _exchange -f ${path}/exch.pdo'
sleep 5
left 'exchange -f ${path}/exch.pdo get_verifying_key -s exchange_vk'
sleep 3
left 'vetting -f ${path}/cash_vetting.pdo get_verifying_key -s r_vk'
sleep 3
left 'asset_type -f ${path}/cash_type.pdo get_identifier -s r_type_id'
sleep 2
left 'exchange -q -w -f ${path}/exch.pdo initialize -r ${r_vk} -t ${r_type_id} -c 100'
sleep 3
left 'issuer -q -w -f ${path}/stock_issuer.pdo escrow -a ${exchange_vk} -s escrow'
sleep 5
left 'exchange -q -w -f ${path}/exch.pdo offer -a '"'"'${escrow}'"'"
sleep 3

sleep $PAUSE

### 6
right 'exchange -f ${path}/exch.pdo get_verifying_key -s exchange_vk'
sleep 3
right 'issuer -q -w -f ${path}/cash_issuer.pdo escrow -a ${exchange_vk} -s escrow'
sleep 5
right 'exchange -q -w -f ${path}/exch.pdo exchange -a '"'"'${escrow}'"'"
sleep 2

sleep $PAUSE

### 7
left 'exchange -q -w -f ${path}/exch.pdo claim_exchange -s asset'
sleep 3
left 'issuer -q -w -f ${path}/cash_issuer.pdo claim -a '"'"'${asset}'"'"
sleep 3

right 'exchange -q -w -f ${path}/exch.pdo claim_offer -s asset'
sleep 3
right 'issuer -q -w -f ${path}/stock_issuer.pdo claim -a '"'"'${asset}'"'"
sleep 3

sleep $PAUSE

#### 8
left 'issuer -f $path/cash_issuer.pdo get_balance'
sleep 2
left 'issuer -f $path/stock_issuer.pdo get_balance'
sleep 2
right 'issuer -f $path/cash_issuer.pdo get_balance'
sleep 2
right 'issuer -f $path/stock_issuer.pdo get_balance'
sleep 2

exit 0
