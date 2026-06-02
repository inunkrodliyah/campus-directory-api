const express = require("express");
const cors = require("cors");
const admin = require("firebase-admin");

admin.initializeApp({
  credential: admin.credential.cert({
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, "\n"),
  }),
});

const db = admin.firestore();

const app = express();

app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
  res.json({
    message: "Campus Directory API Running",
  });
});

app.get("/places", async (req, res) => {
  try {
    const snapshot = await db.collection("places").get();

    const places = [];

    snapshot.forEach((doc) => {
      places.push({
        id: doc.id,
        ...doc.data(),
      });
    });

    res.json(places);
  } catch (error) {
    res.status(500).json({
      error: error.message,
    });
  }
});

app.post("/places", async (req, res) => {
  try {
    const docRef = await db.collection("places").add(req.body);

    res.status(201).json({
      id: docRef.id,
      message: "Place added",
    });
  } catch (error) {
    res.status(500).json({
      error: error.message,
    });
  }
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
