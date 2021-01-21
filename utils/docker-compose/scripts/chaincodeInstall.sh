
. ${SCRIPT_DIR}/lib/common.sh

export CHAINCODE_NAME=${CHAINCODE_NAME:=helloworld_test}
export CHAINCODE_PATH=${CHAINCODE_PATH:=examples/echo/_build/lib}

docker exec -e "CORE_PEER_LOCALMSPID=Org1" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com env TERM=${TERM} ${PEER_CMD} chaincode install -l fpc-c -n ${CHAINCODE_NAME} -v 0 -p ${CHAINCODE_PATH} --tls --cafile /etc/hyperledger/msp/orderer/tlscacerts/tlsca.example.com-cert.pem
sleep 5
docker exec -e "CORE_PEER_LOCALMSPID=Org1" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com env TERM=${TERM} ${PEER_CMD} chaincode instantiate -C mychannel -n ${CHAINCODE_NAME} -v 0 -c '{"Args":["init"]}' -V ecc-vscc --tls --cafile /etc/hyperledger/msp/orderer/tlscacerts/tlsca.example.com-cert.pem
sleep 5

docker exec -e "CORE_PEER_LOCALMSPID=Org1" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer1.org1.example.com env TERM=${TERM} ${PEER_CMD} chaincode install -l fpc-c -n ${CHAINCODE_NAME} -v 0 -p ${CHAINCODE_PATH} --tls --cafile /etc/hyperledger/msp/orderer/tlscacerts/tlsca.example.com-cert.pem
sleep 5
docker exec -e "CORE_PEER_LOCALMSPID=Org1" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer1.org1.example.com env TERM=${TERM} ${PEER_CMD} chaincode invoke -C mychannel -n ${CHAINCODE_NAME} -c "{\"Function\":\"__init\",\"ARGS\":[\"init\"]}"  --waitForEvent --tls --cafile /etc/hyperledger/msp/orderer/tlscacerts/tlsca.example.com-cert.pem -o orderer0.example.com:7050
