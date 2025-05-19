const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
admin.initializeApp();

// Function to send notifications when a new order is created with status "Pending"
exports.sendInitialOrderNotification = onDocumentCreated("orders/{orderId}", async (event) => {
  const orderData = event.data.data();

  if (orderData.status === "Pending") {
    const message = {
      notification: {
        title: "New Order Placed",
        body: "A new order has been placed and is pending.",
      },
    };

    // Get FCM token for the shop owner
    const shopOwnerToken = await getFCMToken(orderData.ownerId, true);
    if (shopOwnerToken) {
      message.token = shopOwnerToken;
      await admin.messaging().send(message);
      console.log("Initial notification sent to shop owner successfully");
    } else {
      console.log("No FCM token found for shop owner.");
    }
  }

  return null;
});

// Helper function to get the FCM token of a user (customer or shop owner)
const getFCMToken = async (userId, isOwner = false) => {
  const collection = isOwner ? "owners" : "users";
  const userRef = admin.firestore().collection(collection).doc(userId);
  const userDoc = await userRef.get();
  return userDoc.exists ? userDoc.data().fcmToken : null;
};

// Function to send notifications when order status changes
exports.sendOrderStatusNotification = onDocumentUpdated("orders/{orderId}", async (event) => {
  const orderData = event.data.after.data();
  const previousData = event.data.before.data();

  // Check if order status has changed
  if (orderData.status !== previousData.status) {
    let message;

    // Customize notification based on status
    if (orderData.status === "Packed") {
      message = {
        notification: {
          title: "Order Packed",
          body: "Your order is packed and ready for delivery.",
        },
      };
    } else if (orderData.status === "delivered") {
      message = {
        notification: {
          title: "Order Delivered",
          body: "Your order has been delivered successfully.",
        },
      };
    }

    // Send notification to customer if status changed
    const customerToken = await getFCMToken(orderData.customerId);
    if (customerToken) {
      message.token = customerToken;
      await admin.messaging().send(message);
      console.log("Notification sent to customer successfully");
    } else {
      console.log("No FCM token found for customer.");
    }

    // Send notification to shop owner for statuses other than "Pending"
    const shopOwnerToken = await getFCMToken(orderData.ownerId, true);
    if (shopOwnerToken) {
      message.token = shopOwnerToken;
      await admin.messaging().send(message);
      console.log("Notification sent to shop owner successfully");
    } else {
      console.log("No FCM token found for shop owner.");
    }
  }

  return null;
});
