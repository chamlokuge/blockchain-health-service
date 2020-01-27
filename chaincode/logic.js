'use strict';
let Id = 0;
const shim = require('fabric-shim');
const util = require('util');
let Chaincode = class {

	async Init(stub, args) {
		try {
                 let ret = stub.getFunctionAndParameters();
                 console.info(ret);
                 let arg= ret.params;
			let adminData = {
			adminId: arg[0],
                        Type:'admin',
			AccessKey: arg[1],
			Name: arg[2]
		}
		await stub.putState(arg[0], Buffer.from(JSON.stringify(adminData)));
		console.info('===Admin Added ===');

                return shim.success();
		} catch (err) {
			console.log(err);
			return shim.error(err);
		}

     }
	async Invoke(stub) {
		let ret = stub.getFunctionAndParameters();
		console.info(ret);

		let method = this[ret.fcn];
		if (!method) {
			console.error('no function of name:' + ret.fcn + ' found');
			throw new Error('Received unknown function ' + ret.fcn + ' invocation');
		}
		try {
			let payload = await method(stub, ret.params);
			return shim.success(payload);
		} catch (err) {
			console.log(err);
			return shim.error(err);
		}
	}
	async viewRecord(stub, args) {

		let healthDetailAsBytes = await stub.getState(args[0]);
		if (!healthDetailAsBytes || healthDetailAsBytes.toString().length <= 0) {
			return Buffer.from('Error:Health Record with this Id does not exist..!');
		}
		let healthRecordCheck = JSON.parse(healthDetailAsBytes);
		if (healthRecordCheck.Type!= 'healthRecord') {

			return Buffer.from('Error:Not a HealthRecord.!');

		} else {

			let healthRecord = JSON.parse(healthDetailAsBytes.toString());
			console.log(healthRecord);
			return healthDetailAsBytes;

		}
}

// 	async queryAllHealthRecords(stub, args) {
// 		// const startKey = 'D' + args[4] + '1';
// 		// const endKey = 'D' + args[4] + '999';
// 		const startKey = 'D1';
// 		const endKey = 'D999999';
// 		const allResults = [];
// 		for await (const {key, value} of stub.getStateByRange(startKey, endKey)) {
// 		const strValue = Buffer.from(value).toString('utf8');
// 		let healthRecord;
// 		try {
// 			healthRecord = JSON.parse(strValue);
// 		} catch (err) {
// 			console.log(err);
// 			healthRecord = strValue;
// 		}
// 		allResults.push({ Key: key, Record: healthRecord });
// 	}
// 	console.info(allResults);
// 	return JSON.stringify(allResults);
// }

	
	async submitRecord(stub, args) {
		let UID = ++Id;
		 let healthRecordId = 'D' + args[4] + UID;
		 let patientId = 'P' + args[4] + UID;
		//let healthRecordId = 'D' +  UID;
		//let patientId = 'P' +  UID;

		let healthRecord = {
			patientName: args[0],
			DOB: args[1],
			Type: 'healthRecord',
			patientMobile: args[2],
			date: args[3],
			time: args[4],
			description: args[5],
			doctorName: args[6],
			diagnosis: args[7],
			testsPerformed: args[8],
			testResults: args[9],
			prescribedAction: args[10],
			healthRecordId: healthRecordId,
			patientId: patientId,
			prescribedMedication: args[11],
			doc: args[12]
		}

		let patientData = {
			patientName: args[0],
			DOB: args[1],
			Type: 'healthRecord',
			patientMobile: args[2],
			description: [5]
			//CurrentLocation: 'Not Yet Shipped'
		};

		await stub.putState(patientId, Buffer.from(JSON.stringify(patientData)));
		await stub.putState(healthRecordId, Buffer.from(JSON.stringify(healthRecord)));
		console.info("Health Details Added Succesfully.. Your Health Record Id is " + healthRecordId + " And Patient Id is " + patientId);
		return Buffer.from("Health Details Added Succesfully.. Your Health Record Id is " + healthRecordId + " And Patient Id is " + patientId);


	}

	async updateRecord(stub, args) {

		let adminAsBytes = await stub.getState(args[0]);
		let healthDetailAsBytes = await stub.getState(args[2]);

		if (!adminAsBytes || adminAsBytes.toString().length <= 0) {
			return Buffer.from('Incorrect Admin Id.!');
		}
		let admin = JSON.parse(adminAsBytes);

		if (admin.AccessKey != args[1]) {

			return Buffer.from("Incorrect AccessKey.!");
		}

		if (!healthDetailAsBytes || healthDetailAsBytes.toString().length <= 0) {
			return Buffer.from('Health Record with this ID does not exist');
		} else {
			let healthRecord = JSON.parse(healthDetailAsBytes);

			healthRecord.updatedNote = args[3];
			
			await stub.putState(args[2], Buffer.from(JSON.stringify(healthRecord)));
			console.info("Health Record Details Updated Succesfully");
                        return Buffer.from("Health Record Details Updated Succesfully");

		}
	}
}

shim.start(new Chaincode());


// 'use strict';
// let Id = 0;
// const shim = require('fabric-shim');
// const util = require('util');
// let Chaincode = class {

// 	async Init(stub, args) {
// 		try {
//                  let ret = stub.getFunctionAndParameters();
//                  console.info(ret);
//                  let arg= ret.params;
// 			let adminData = {
// 			UserId: arg[0],
//                         Type:'admin',
// 			AccessKey: arg[1],
// 			Name: arg[2]
// 			// Mobile: arg[3]
// 		}
// 		await stub.putState(arg[0], Buffer.from(JSON.stringify(adminData)));
// 		console.info('===Admin Added ===');

//                 return shim.success();
// 		} catch (err) {
// 			console.log(err);
// 			return shim.error(err);
// 		}

//      }
// 	async Invoke(stub) {
// 		let ret = stub.getFunctionAndParameters();
// 		console.info(ret);

// 		let method = this[ret.fcn];
// 		if (!method) {
// 			console.error('no function of name:' + ret.fcn + ' found');
// 			throw new Error('Received unknown function ' + ret.fcn + ' invocation');
// 		}
// 		try {
// 			let payload = await method(stub, ret.params);
// 			return shim.success(payload);
// 		} catch (err) {
// 			console.log(err);
// 			return shim.error(err);
// 		}
// 	}
// 	// async trackConsignment(stub, args) {

// 	// 	let consignmentAsBytes = await stub.getState(args[0]);
// 	// 	if (!consignmentAsBytes || consignmentAsBytes.toString().length <= 0) {
// 	// 		return Buffer.from('Error:Item With this Id Doesnt Exist..!');
// 	// 	}
// 	// 	let consignmentCheck = JSON.parse(consignmentAsBytes);
// 	// 	if (consignmentCheck.Type!= 'consignment') {

// 	// 		return Buffer.from('Error:Not a Consignment.!');

// 	// 	} else {

// 	// 		let consignment = JSON.parse(consignmentAsBytes.toString());
// 	// 		console.log(consignment);
// 	// 		return consignmentAsBytes;

// 	// 	}


// 	// }
// 	async viewRecord(stub, args) {

// 		let healthDetailAsBytes = await stub.getState(args[0]);
// 		if (!healthDetailAsBytes || healthDetailAsBytes.toString().length <= 0) {
// 			return Buffer.from('Error:Health Record with this Id does not Exist..!');
// 		}
// 		let healthRecordCheck = JSON.parse(healthDetailAsBytes);
// 		if (healthRecordCheck.Type!= 'healthRecord') {

// 			return Buffer.from('Error:Not a HealthRecord.!');

// 		} else {

// 			let healthRecord = JSON.parse(healthDetailAsBytes.toString());
// 			console.log(healthRecord);
// 			return healthDetailAsBytes;

// 		}
// }
// 	async bookConsignment(stub, args) {
// 		let UID = ++Id;
// 		let invoiceId = 'I' + args[4] + UID;
// 		let trackingId = 'T' + args[7] + UID;

// 		let consignmentData = {
// 			From: args[0],
// 			To: args[1],
// 			Type: 'consignment',
// 			consignerName: args[2],
// 			consignerAddress: args[3],
// 			consignerMobile: args[4],
// 			consigneeName: args[5],
// 			consigneeAddress: args[6],
// 			consigneeMobile: args[7],
// 			ItemName: args[8],
// 			ItemWeight: args[9],
// 			FrieghtCharges: args[10],
// 			InvoiceId: invoiceId,
// 			TrackingId: trackingId,
// 			Date: args[11]
// 		}

// 		let trackingData = {
// 			ItemName: args[8],
// 			From: args[0],
// 			Type: 'consignment',
// 			To: args[1],
// 			ShipmentDetails: [],
// 			CurrentLocation: 'Not Yet Shipped'
// 		};

// 		await stub.putState(trackingId, Buffer.from(JSON.stringify(trackingData)));
// 		await stub.putState(invoiceId, Buffer.from(JSON.stringify(consignmentData)));
// 		console.info("Consignment Added Succesfully.. Your Invoice Id is " + invoiceId + " And Tracking Id is " + trackingId);
// 		return Buffer.from("Consignment Added Succesfully.. Your Invoice Id is " + invoiceId + " And Tracking Id is " + trackingId);


// 	}

// 	async updateShipment(stub, args) {

// 		let adminAsBytes = await stub.getState(args[0]);
// 		let consignmentAsBytes = await stub.getState(args[2]);

// 		if (!adminAsBytes || adminAsBytes.toString().length <= 0) {
// 			return Buffer.from('Incorrect Admin Id.!');
// 		}
// 		let admin = JSON.parse(adminAsBytes);

// 		if (admin.AccessKey != args[1]) {

// 			return Buffer.from("Incorrect AccessKey.!");
// 		}

// 		if (!consignmentAsBytes || consignmentAsBytes.toString().length <= 0) {
// 			return Buffer.from('Consignment With this Id Does not Exist..!');
// 		} else {
// 			let consignment = JSON.parse(consignmentAsBytes);

// 			consignment.ShipmentDetails.push(args[3]);
// 			consignment.CurrentLocation = args[3];
// 			await stub.putState(args[2], Buffer.from(JSON.stringify(consignment)));
// 			console.info("Consignment Details Updated Succesfully");
//                         return Buffer.from("Consignment Details Updated Succesfully");

// 		}
// 	}
// }

// shim.start(new Chaincode());


