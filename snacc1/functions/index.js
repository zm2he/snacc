const functions = require('firebase-functions');
const admin = require('firebase-admin');
const https = require('https');
const requestPromiseNative = require('request-promise-native');
//const request = require('request');

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });

admin.initializeApp(functions.config().firebase);

const inventoryRef = admin.firestore().collection('inventory');

exports.onInventoryAdd = functions.firestore.document('inventory/{inventoryId}').onCreate(
    (change, context) => {
        let inventoryId = change.id;
        console.log(inventoryId);
        console.log(change.data().item);

        var options = {
            uri: 'https://api.edamam.com/api/food-database/parser',
            qs: {
                app_id: "19649da1",
                app_key: "636ca13a6d644daec03cd524e0fb5a61",
                ingr: change.data().item
            },
            headers: {
                'User-Agent': 'Request-Promise-Native'
            },
            json: true
        };

        return requestPromiseNative(options)
            .then(function (parsedBody) {
                console.log(parsedBody);
                let genericFood = parsedBody.parsed;
                if (genericFood.length > 0) {
                    return inventoryRef.doc(inventoryId).update({
                        "foodId": genericFood[0].food.foodId,
                        "label": genericFood[0].food.label,
                        "calories": genericFood[0].food.nutrients.ENERC_KCAL,
                        "protein": genericFood[0].food.nutrients.PROCNT,
                        "carbs": genericFood[0].food.nutrients.CHOCDF,
                        "fat": genericFood[0].food.nutrients.FAT,
                        "fiber": genericFood[0].food.nutrients.FIBTG
                    });
                } else {
                    return inventoryRef.doc(inventoryId).delete();
                }

            })
            .catch(function (err) {
                console.log(err);
            });
    }
);

exports.onInventoryChange = functions.firestore.document('inventory/{inventoryId}').onWrite(
    (change, context) => {
        let sentinel = false;

        inventoryRef.get()
            .then(snapshot => {
                var items = new Array();
                snapshot.forEach(doc => {
                    //if (doc.valid != null && doc.valid === true) {
                    items.push(doc._fieldsProto.label.stringValue.toString());
                    //}
                    //if (doc.item != null && doc.item === "SENTINEL") {
                        //sentinel = true;
                        //doc.delete();
                    //}
                    console.log(doc);
                    console.log(doc._fieldsProto.label.stringValue);
                    console.log(items)
                });
                snapshot.forEach(doc => {
                    if ((doc.valid === false || doc.item === "SENTINEL") && sentinel === true) {
                        doc.delete();
                    }
                });
            })
            .catch((err) => {
                console.log(err);
            });

        let itemString = items.join(", ").toString();
        console.log("Joined");
        console.log(itemString);

        var query = {
            uri: "https://api.edamam.com/search",
            qs: {
                "app_id": "1ff9eda8",
                "app_key": "97ff66091c23d2f620d8dddfad2ca8f2",
                "q": items.join(", ").toString()
            },
            headers: {
                'User-Agent': 'Request-Promise-Native'
            },
            json: true
        }

        return requestPromiseNative(query)
            .then((parsedBody) => {
                console.log(parsedBody);
                    let recipeList = parsedBody.hits;

                    for (let recipe in recipeList) {
                        let recipeDoc = recipeRef.doc();

                        recipeDoc.set({
                                "label": recipe.recipe.label,
                                "source": recipe.recipe.source,
                                "image": recipe.recipe.image,
                                "uri": recipe.recipe.uri,
                                "cautions": recipe.recipe.cautions,
                                "healthLabels": recipe.recipe.healthLabels,
                                "dietLabels": recipe.recipe.dietLabels,
                                "calories": recipe.recipe.calories
                            },
                            {"merge": false});

                        let ingredientCollection = recipeDoc.collection("ingredients");

                        let ingredientLines = recipe.recipe.ingredientLines;

                        let ingredientWords = [];

                        for (let line in ingredientLines) {
                            wordpos.getNoun(line, results => {
                                ingredientWords.push(results);
                            });
                        }

                        ingredientCollection.set({
                                "ingredientSentences": ingredientSentences,
                                "ingredientWords": ingredientWords
                            },
                            {"merge": false});
                    }
                }
            )
            .catch((err) => {
                console.log(err);
            });
    }
);
