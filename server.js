var admin = require("firebase-admin");

// Initialize Firebase Admin SDK with the service account credentials
var serviceAccount = require("config/serviceAccountkey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://sea-shop-default-rtdb.firebaseio.com"
});

// Function to send notification to a device
const sendNotification = (deviceToken, title, body) => {
  const message = {
    notification: {
      title: title,
      body: body,
    },
    token: deviceToken,  // The device token to which the notification will be sent
  };

  // Send the notification
  admin.messaging().send(message)
    .then((response) => {
      console.log('Notification sent successfully:', response);
    })
    .catch((error) => {
      console.log('Error sending notification:', error);
    });
};

// Fetch current user ID and then send the notification
const sendOrderNotification = async () => {
  try {
    // Assuming you have a collection 'users' with a field 'isCurrentUser' (you may need to adjust this to fit your structure)
    const firestore = admin.firestore();
    
    // Query to get the current logged-in user (assuming you store an "isCurrentUser" flag or something similar)
    const currentUserQuery = await firestore.collection('users').where('isCurrentUser', '==', true).get();

    if (!currentUserQuery.empty) {
      // Get the first document from the query result (assuming only one user is marked as 'current')
      const currentUserDoc = currentUserQuery.docs[0];

      // Retrieve the user ID and device token
      const currentUserId = currentUserDoc.id; // ID of the current user document
      const deviceToken = currentUserDoc.data()?.fcmToken; // Retrieve the device token from the document

      if (deviceToken) {
        // Customize your notification title and body here
        const title = 'New Order Placed';
        const body = 'Your order has been placed successfully!';
        
        // Call sendNotification to send the actual message
        sendNotification(deviceToken, title, body);
      } else {
        console.log('No device token found for the current user.');
      }
    } else {
      console.log('No current user found in Firestore.');
    }
  } catch (error) {
    console.log('Error fetching current user or device token:', error);
  }
};

// Call the function to send the notification to the current user
sendOrderNotification();
