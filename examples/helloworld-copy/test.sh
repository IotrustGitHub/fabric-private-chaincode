#!/bin/bash

SCRIPTDIR="$(dirname $(readlink --canonicalize ${BASH_SOURCE}))"
FPC_TOP_DIR="${SCRIPTDIR}/../.."
FABRIC_CFG_PATH="${SCRIPTDIR}/../../integration/config"
FABRIC_SCRIPTDIR="${FPC_TOP_DIR}/fabric/bin/"

. ${FABRIC_SCRIPTDIR}/lib/common_utils.sh
. ${FABRIC_SCRIPTDIR}/lib/common_ledger.sh

CC_ID=helloworld_test
CHAN_ID=mychannel

#this is the path that will be used for the docker build of the chaincode enclave
ENCLAVE_SO_PATH=examples/helloworld/_build/lib/

CC_VERS=0

helloworld_test() {
    say "- do hello world"
    # install and instantiate helloworld  chaincode

    # builds the docker image; creates the docker container and enclave;
    # input:  CC_ID:chaincode name; CC_VERS:chaincode version;
    #         ENCLAVE_SO_PATH:path to build artifacts

    export CORE_PEER_MSPCONFIGPATH=../msp/users/Admin\@org1.example.com/msp

    say "- install helloworld chaincode"
    # try ${PEER_CMD} chaincode install -l fpc-c -n ${CC_ID} -v ${CC_VERS} -p ${ENCLAVE_SO_PATH}
    try ${PEER_CMD} chaincode install -l fpc-c -n ${CC_ID} -v 0 -p examples/helloworld/_build/lib --tls --cafile /etc/hyperledger/msp/orderer/tlscacerts/tlsca.example.com-cert.pem
    sleep 3

    # instantiate helloworld chaincode
    say "- instantiate helloworld chaincode"
    # try ${PEER_CMD} chaincode instantiate -o ${ORDERER_ADDR} -C ${CHAN_ID} -n ${CC_ID} -v ${CC_VERS} -c '{"args":["init"]}' -V ecc-vscc
    try ${PEER_CMD} chaincode instantiate -C ${CHAN_ID} -n ${CC_ID} -v 0 -c '{"Args":["init"]}' -V ecc-vscc --tls --cafile /etc/hyperledger/msp/orderer/tlscacerts/tlsca.example.com-cert.pem
    sleep 3

    # store the value of 100 in asset1
    say "- invoke storeAsset transaction to store value 100 in asset1"
    # try ${PEER_CMD} chaincode invoke -o ${ORDERER_ADDR} -C ${CHAN_ID} -n ${CC_ID} -c '{"Args":["storeAsset","asset1","100"]}' --waitForEvent
    try ${PEER_CMD} chaincode invoke -o orderer0.example.com:7050 -C ${CHAN_ID} -n ${CC_ID} -c '{"Args":["storeAsset","asset1","100"]}'  --waitForEvent --tls --cafile /etc/hyperledger/msp/orderer/tlscacerts/tlsca.example.com-cert.pem

    # retrieve current value for "asset1";  should be 100;
    say "- invoke retrieveAsset transaction to retrieve current value of asset1"
    # try ${PEER_CMD} chaincode invoke -o ${ORDERER_ADDR} -C ${CHAN_ID} -n ${CC_ID} -c '{"Args":["retrieveAsset","asset1"]}' --waitForEvent
    try ${PEER_CMD} chaincode invoke -o orderer0.example.com:7050 -C ${CHAN_ID} -n ${CC_ID} -c '{"Args":["retrieveAsset","asset1"]}'  --waitForEvent --tls --cafile /etc/hyperledger/msp/orderer/tlscacerts/tlsca.example.com-cert.pem

    say "- invoke query with retrieveAsset transaction to retrieve current value of asset1"
    # try ${PEER_CMD} chaincode query -o ${ORDERER_ADDR} -C ${CHAN_ID} -n ${CC_ID} -c '{"Args":["retrieveAsset","asset1"]}'
    try ${PEER_CMD} chaincode query -o orderer0.example.com:7050 -C ${CHAN_ID} -n ${CC_ID} -c '{"Args":["retrieveAsset","asset1"]}'  --waitForEvent --tls --cafile /etc/hyperledger/msp/orderer/tlscacerts/tlsca.example.com-cert.pem
}

# 1. prepare
para
say "Preparing Helloworld Test ..."
# - clean up relevant docker images
docker_clean ${ERCC_ID}
docker_clean ${CC_ID}

trap ledger_shutdown EXIT

para
say "Run helloworld  test"

say "- setup ledger"
ledger_init

say "- helloworld test"
helloworld_test

say "- shutdown ledger"
ledger_shutdown

para
yell "Helloworld test PASSED"

exit 0