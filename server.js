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

// GET semua tempat + filter kategori
app.get("/places", async (req, res) => {
  try {
    const { category } = req.query;
    const snapshot = await db.collection("places").get();

    let places = [];
    snapshot.forEach((doc) => {
      places.push({
        id: doc.id,
        ...doc.data(),
      });
    });

    // Filter by category kalau ada query ?category=
    if (category) {
      places = places.filter(
        (p) => p.category?.toLowerCase() === category.toLowerCase()
      );
    }

    res.json(places);
  } catch (error) {
    res.status(500).json({
      error: error.message,
    });
  }
});

// GET detail satu tempat by ID
app.get("/places/:id", async (req, res) => {
  try {
    const doc = await db.collection("places").doc(req.params.id).get();

    if (!doc.exists) {
      return res.status(404).json({
        error: "Place not found",
      });
    }

    res.json({
      id: doc.id,
      ...doc.data(),
    });
  } catch (error) {
    res.status(500).json({
      error: error.message,
    });
  }
});

app.post("/places", async (req, res) => {
  try {
    const { name, address, latitude, longitude, category } = req.body;

    // Validasi input
    if (!name || !address || !latitude || !longitude || !category) {
      return res.status(400).json({
        error: "Field name, address, latitude, longitude, category wajib diisi"
      });
    }

    if (isNaN(latitude) || isNaN(longitude)) {
      return res.status(400).json({
        error: "Latitude dan longitude harus berupa angka"
      });
    }

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



// GET semua kategori
app.get("/categories", async (req, res) => {
  try {
    const snapshot = await db.collection("places").get();
    const categories = new Set();

    snapshot.forEach((doc) => {
      const data = doc.data();
      if (data.category) {
        categories.add(data.category);
      }
    });

    const result = Array.from(categories).map((cat) => ({
      name: cat,
      label: cat.charAt(0).toUpperCase() + cat.slice(1),
    }));

    res.json(result);
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