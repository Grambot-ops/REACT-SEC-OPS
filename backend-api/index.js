// backend-api/index.js
const express = require("express");
const { Pool } = require("pg");
const cors = require("cors");

const app = express();
app.use(express.json());

// IMPORTANT: Configure CORS to allow requests from your future CloudFront domain
// For now, we can be permissive, but tighten this in production.
app.use(cors());

// The app will get credentials from environment variables
// provided by ECS and Secrets Manager
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

// Health check endpoint for the ALB
app.get("/health", (req, res) => {
  res.status(200).send("OK");
});

// A simple endpoint to get items
app.get("/api/items", async (req, res) => {
  try {
    // Example: create table if not exists
    await pool.query(
      "CREATE TABLE IF NOT EXISTS items (id SERIAL PRIMARY KEY, name VARCHAR(255))"
    );
    const { rows } = await pool.query("SELECT * FROM items ORDER BY id ASC");
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).send("Server Error");
  }
});

// A simple endpoint to add an item
app.post("/api/items", async (req, res) => {
  try {
    const { name } = req.body;
    if (!name) {
      return res.status(400).send("Item name is required");
    }
    const newItem = await pool.query(
      "INSERT INTO items (name) VALUES($1) RETURNING *",
      [name]
    );
    res.json(newItem.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).send("Server Error");
  }
});

const PORT = 8080;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
