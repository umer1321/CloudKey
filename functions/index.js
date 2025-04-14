const functions = require("firebase-functions");
const logger = require("firebase-functions/logger");
// Initialize Stripe with the secret key from environment variables
const stripeSecretKey = functions.config().stripe.secret_key ||
    "sk_test_51RCEsdQqRPwP8ZGQ5Nu0kDsSViKvIPDh4uzeTmQn0ickjY7dQ" +
    "ABrUk5oIPu2yQ6AIZPhlAJmGT1S228qchRGLIMs00KxLNi2VL";
const stripe = require("stripe")(stripeSecretKey);

exports.createPaymentIntent = functions.https.onCall(
    async (data, context) => {
      // Check if the user is authenticated
      if (!context.auth) {
        logger.error("Unauthenticated user tried to create Payment Intent");
        throw new functions.https.HttpsError(
            "unauthenticated",
            "You must be logged in to create a payment intent.",
        );
      }
      try {
        const {amount, currency = "usd"} = data; // Default to USD
        // Validate the amount
        if (!amount || typeof amount !== "number" || amount <= 0) {
          logger.error("Invalid amount provided", {amount});
          throw new functions.https.HttpsError(
              "invalid-argument",
              "Amount must be a positive number.",
          );
        }
        // Create the Payment Intent
        const paymentIntent = await stripe.paymentIntents.create({
          amount: Math.round(amount * 100), // Convert to cents
          currency,
          payment_method_types: ["card"],
          metadata: {
            userId: context.auth.uid,
            bookingId: data.bookingId || "unknown",
          },
        });
        logger.info("Payment Intent created successfully", {
          paymentIntentId: paymentIntent.id,
          userId: context.auth.uid,
        });
        return {
          clientSecret: paymentIntent.client_secret,
        };
      } catch (error) {
        logger.error("Error creating Payment Intent", {error: error.message});
        throw new functions.https.HttpsError(
            "invalid-argument",
            error.message || "Failed to create Payment Intent",
        );
      }
    },
);


