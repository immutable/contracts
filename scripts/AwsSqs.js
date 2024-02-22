const fs = require('fs');

// Load the AWS SDK for Node.js
var AWS = require("aws-sdk");

function readJsonFromFile(filePath) {
  try {
    // Read the file synchronously
    const data = fs.readFileSync(filePath, "utf8");
    // Parse the JSON data
    const jsonData = JSON.parse(data);
    // Return the parsed JSON
    return jsonData;
  } catch (err) {
    console.error("Error reading JSON file:", err);
    return null;
  }
}

// Create an SQS service object
const sqs = new AWS.SQS({
  region: "us-east-2", // specify the region where your SQS queue is located
});

// Define the SQS queue URL
const queueUrl = "https://sqs.us-east-2.amazonaws.com/783421985614/load-test-queue-dev";

// Function to upload items to SQS
async function uploadToSQS() {
  console.log('Uploading items to SQS...')
  // Read the JSON data from the file
  const fileName = process.argv[2];
  const jsonData = readJsonFromFile(fileName);
  console.log(`Uploading orders from ${fileName} to SQS`);
  try {
    if (jsonData) {
      // Map each item to a sendMessage promise
      const sendMessagePromises = jsonData.map(item => {
        const params = {
          MessageBody: JSON.stringify(item),
          QueueUrl: queueUrl,
        };
        return sqs.sendMessage(params).promise();
      });

      // Use Promise.all() to send all messages concurrently
      await Promise.all(sendMessagePromises);

      console.log('All items uploaded to SQS');
    } else {
      console.log('Failed to read JSON data from file.');
    }
  } catch (err) {
    console.error('Error uploading items to SQS:', err);
  }
}

// Call the function to upload items to SQS
uploadToSQS();
