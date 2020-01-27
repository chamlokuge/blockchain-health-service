echo 'Instantiating Pre-requisites for Client Application..'

npm i fabric-ca-client

npm i fabric-network

npm install express body-parser --save
npm install ejs --save
npm install

rm -rf wallet

echo 'Enrolling Admin...'

node enrollAdmin.js

echo 'Registering User..'

node registerUser.js User

echo 'All Good..'
echo 'It is also possible to use API server for querying or invoking apicalls .. Run *node server.js user * and then use localhost:8080'
exit 1
