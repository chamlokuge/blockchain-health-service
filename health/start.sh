echo "Removing key from key store..."

rm -rf ./hfc-key-store

# Remove chaincode docker image
# may be need to change mycc to health
sudo docker rmi -f dev-peer0.org1.example.com-mycc-1.0-384f11f484b9302df90b453200cfb25174305fce8f53f4e94d45ee3b6cab0ce9
sleep 2

cd ../basic-network
./start.sh

# Now launch the CLI container in order to install, instantiate chaincode
docker-compose -f ./docker-compose.yml up -d cli
docker ps -a

echo 'Installing chaincode..'
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode install -n health -v 1.0 -p "/opt/gopath/src/github.com/" -l "node"

echo 'Instantiating chaincode..'

echo 'Getting things ready for Chaincode Invocation..should take only 10 seconds..'
sleep 10
echo 'Adding HealthRecord..'

docker exec -e “CORE_PEER_LOCALMSPID=Org1MSP” -e “CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp” cli peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n health -c '{"function":"submitRecord","Args":["hl7_json","Bob001","Bob","0769023123","Alice","0786765432","-------------------sample record 1---------------------------------------","16/10/19"]}'

sleep 5
echo 'Quering health records'

docker exec -e “CORE_PEER_LOCALMSPID=Org1MSP” -e “CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp” cli peer chaincode query -o orderer.example.com:7050 -C mychannel -n health -c '{"function":"getRecord","Args":["P07867654321"]}'


docker exec -e “CORE_PEER_LOCALMSPID=Org1MSP” -e “CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp” cli peer chaincode query -o orderer.example.com:7050 -C mychannel -n health -c '{"function":"getRecord","Args":["R1Bob0011"]}'

sleep 5
# Starting docker logs of chaincode container

docker logs -f dev-peer0.org1.example.com-health-1.0