# test.sh가 작동하지 않아 아래 내용을 직접 입력 
# demo(CC_ID)가 installing error code 500 발생할 경우 CC_ID를 demo1, demo2 등으로 변경하여 실행 
# 혹은 install을 update로 변경 후 -v 1 옵션으로 진행 
# 기존 helloworld에서 Kafka를 사용하던 것에서 RAFT 알고리즘으로 변경하면서 TLS 옵션이 강제로 필요

make

docker exec -it peer0.org1.example.com bash

# in docker
export CORE_PEER_MSPCONFIGPATH=../msp/users/Admin\@org1.example.com/msp
${PEER_CMD} chaincode install -l fpc-c -n oracle_cc -v 0 -p examples/oracle_cc/_build/lib --tls --cafile /etc/hyperledger/msp/orderer/tlscacerts/tlsca.example.com-cert.pem
${PEER_CMD} chaincode instantiate -C mychannel -n oracle_cc -v 0 -c '{"Args":["init"]}' -V ecc-vscc --tls --cafile /etc/hyperledger/msp/orderer/tlscacerts/tlsca.example.com-cert.pem
${PEER_CMD} chaincode invoke -o orderer0.example.com:7050 -C mychannel -n oracle_cc -c '{"Args":["storeAsset","asset1","100"]}'  --waitForEvent --tls --cafile /etc/hyperledger/msp/orderer/tlscacerts/tlsca.example.com-cert.pem
${PEER_CMD} chaincode invoke -o orderer0.example.com:7050 -C mychannel -n oracle_cc -c '{"Args":["retrieveAsset","asset1"]}'  --waitForEvent --tls --cafile /etc/hyperledger/msp/orderer/tlscacerts/tlsca.example.com-cert.pem
${PEER_CMD} chaincode query -o orderer0.example.com:7050 -C mychannel  -n oracle_cc -c '{"Args":["retrieveAsset","asset1"]}'  --tls --cafile /etc/hyperledger/msp/orderer/tlscacerts/tlsca.example.com-cert.pem

${PEER_CMD} chaincode invoke -o orderer0.example.com:7050 -C mychannel -n oracle_cc -c '{"Args":["retrieveAsset","getRandom"]}'  --waitForEvent --tls --cafile /etc/hyperledger/msp/orderer/tlscacerts/tlsca.example.com-cert.pem

${PEER_CMD} chaincode query -o orderer0.example.com:7050 -C mychannel  -n oracle_cc -c '{"Args":["retrieveAsset","getRandom"]}'  --tls --cafile /etc/hyperledger/msp/orderer/tlscacerts/tlsca.example.com-cert.pem

