const functions = require('firebase-functions');
const request = require('request');

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });

exports.onInventoryAdd = functions.firestore.document('inventory/{inventoryId}').onCreate(
    (change, context) => {
        request.get({
                url: 'https://api.edamam.com/search',
                body: JSON.stringify({
                    app_id: "07c8703c",
                    app_key: "1bfd70509f0025d40f48f786a41e4494",
                    q: "chicken, noodles"
                }),
                method: 'GET'
            }, (error, response, body) => {
                console.log(body)
                change.ref.set({data: JSON.parse(body)}, {merge: true})
            }
        )
    }
);
