echo "Removing key from key store..."

rm -rf ./hfc-key-store

# Remove chaincode docker image
docker rmi -f dev-peer0.org1.example.com-mycc-1.0-384f11f484b9302df90b453200cfb25174305fce8f53f4e94d45ee3b6cab0ce9
sleep 2

cd ../basic-network
./start.sh

# Now launch the CLI container in order to install, instantiate chaincode
docker-compose -f ./docker-compose.yml up -d cli
docker ps -a

echo 'Installing chaincode..'
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode install -n mycc -v 1.0 -p "/opt/gopath/src/github.com/" -l "node"

echo 'Instantiating chaincode..'
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode instantiate -o orderer.example.com:7050 -C mychannel -n mycc -l "node" -v 1.0 -c '{"Args":["Init","bob123","123","bob"]}'
echo 'Getting things ready for Chaincode Invocation..should take only 10 seconds..'
sleep 10
echo 'Adding health details..'

docker exec -e “CORE_PEER_LOCALMSPID=Org1MSP” -e “CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp” cli peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n mycc -c '{"function":"submitRecord","Args":["patient5","01/12/1987","0785245256","01/01/2020","1010","Medical check up 2","Physician5","Tuberculosis","RBC count","Test Result 1","Prescribed action 1","Prescribed medication 1","Document1 of patient5"]}'

sleep 5
echo 'Querying Health Record Details.. and Retrieving Details..'

docker exec -e “CORE_PEER_LOCALMSPID=Org1MSP” -e “CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp” cli peer chaincode query -o orderer.example.com:7050 -C mychannel -n mycc -c '{"function":"viewRecord","Args":["D10101"]}'


docker exec -e “CORE_PEER_LOCALMSPID=Org1MSP” -e “CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp” cli peer chaincode query -o orderer.example.com:7050 -C mychannel -n mycc -c '{"function":"viewRecord","Args":["P10101"]}'
sleep 5 

echo 'Updating Health Details'

docker exec -e “CORE_PEER_LOCALMSPID=Org1MSP” -e “CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp” cli peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n mycc -c '{"function":"updateRecord","Args":["bob123","123","D10101","Updated Record 1"]}'
sleep 3
#sudo docker exec -e “CORE_PEER_LOCALMSPID=Org1MSP” -e “CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp” cli peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n mycc -c '{"function":"updateShipment","Args":["alice123","123","P10101","Reached Destination Port"]}'

sleep 5
echo "Querying Health Details to check.."
docker exec -e “CORE_PEER_LOCALMSPID=Org1MSP” -e “CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp” cli peer chaincode query -o orderer.example.com:7050 -C mychannel -n mycc -c '{"function":"viewRecord","Args":["D10101"]}'
sleep 5
# Starting docker logs of chaincode container

#sudo docker logs -f dev-peer0.org1.example.com-mycc-1.0

# docker exec -e “CORE_PEER_LOCALMSPID=Org1MSP” -e “CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp” cli peer chaincode query -o orderer.example.com:7050 -C mychannel -n mycc -c '{"function":"queryAllHealthRecords","Args":["D1"]}'
