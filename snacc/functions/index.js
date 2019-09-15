const functions = require('firebase-functions');
const admin = require('firebase-admin');
const https = require('https');
const requestPromiseNative = require('request-promise-native')
//const request = require('request');

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });

admin.initializeApp(functions.config().firebase)

const inventoryRef = admin.firestore().collection('inventory');

exports.onInventoryAdd = functions.firestore.document('inventory/{inventoryId}').onCreate(
    (change, context) => {
        let inventoryId = change.id;
        console.log(inventoryId);
        console.log(change.data().name);

    var options = {
        uri: 'https://api.edamam.com/api/food-database/parser',
        qs: {
            app_id: "19649da1",
            app_key: "636ca13a6d644daec03cd524e0fb5a61",
            ingr: change.data().name
        },
        headers: {
            'User-Agent': 'Request-Promise-Native'
        },
        json: true
    }

    return requestPromiseNative(options)
        .then(function(parsedBody) {
            console.log(parsedBody);
            let food = parsedBody.parsed[0].food;
            return inventoryRef.doc(inventoryId).update({
                "foodId": food.foodId,
                "label": food.label,
                "calories": food.nutrients.ENERC_KCAL,
                "protein": food.nutrients.PROCNT, 
                "carbs": food.nutrients.CHOCDF,
                "fat": food.nutrients.FAT,
                "fiber": food.nutrients.FIBTG,
            });
        })
        .catch(function(err) {
            console.log(err);
        });

/*
        return https.get('https://api.edamam.com/api/food-database/parser?app_id=19649da1&app_key=636ca13a6d644daec03cd524e0fb5a61&ingr=' + change.data().name,
            (resp) => {
                resp.on('end', () => {
                    console.log(d.text);
                })
            }
        )
        .on("error", (err) => {
            console.log("Error: " + err);
        });
*/
        /*
        return request.get('https://api.edamam.com/api/food-database/parser?app_id=19649da1&app_key=636ca13a6d644daec03cd524e0fb5a61&ingr=' + change.data().name,
            (error, response, body) => {
                let food = response.parsed[0].food;
                console.log(food);
                console.log("slkadjfkdsa");
                return inventoryRef.doc(inventoryId).update({
                    "foodId": food.foodId,
                    "label": food.label,
                    "calories": food.nutrients.ENERC_KCAL,
                    "protein": food.nutrients.PROCNT, 
                    "carbs": food.nutrients.CHOCDF,
                    "fat": food.nutrients.FAT,
                    "fiber": food.nutrients.FIBTG,
                })
                .catch(console.log(error));
            }
        );
        */
    }
);
