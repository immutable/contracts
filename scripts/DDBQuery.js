const fs = require('fs');

// Load the AWS SDK for Node.js
var AWS = require("aws-sdk");
// Set the region
AWS.config.update({ region: "us-east-2" });

// Create DynamoDB service object
var ddb = new AWS.DynamoDB({ apiVersion: "2012-08-10" });

const params = {
  TableName: "wallets-dev",
  Limit: 1500,
};

ddb.scan(params, function (err, data) {
  if (err) {
    console.log("Error", err);
  } else {
    
    const l1Keys = data.Items.map(item => item.l1_key.S); // Extract l1_key from each item

    // Write l1Keys to a JSON file
    fs.writeFile('l1_keys.json', JSON.stringify(l1Keys, null, 2), (err) => {
      if (err) {
        console.error('Error writing JSON file:', err);
      } else {
        console.log('L1 Keys written to l1_keys.json');
      }
    });
  }
});