// backend-api/index.js
const express = require("express");
const { Pool } = require("pg");
const cors = require("cors"); // Make sure you have `npm install cors`

const app = express();
app.use(express.json());

// --- THIS IS THE CRITICAL CORS CONFIGURATION ---
// We will get these URLs from our Terraform output later.
// For now, you can leave them as placeholders or update them after `terraform apply`.
const S3_WEBSITE_URL =
  process.env.S3_WEBSITE_URL ||
  "http://react-sec-deploy-frontend-bucket-reactsecops2.s3-website-us-east-1.amazonaws.com";

const corsOptions = {
  origin: S3_WEBSITE_URL,
  optionsSuccessStatus: 200, // For legacy browser support
};

app.use(cors(corsOptions));
// --- END OF CORS CONFIGURATION ---

// The app will get credentials from environment variables
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

// API endpoints
app.get("/api/items", async (req, res) => {
  try {
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
