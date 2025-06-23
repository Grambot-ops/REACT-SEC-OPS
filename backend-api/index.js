const express = require("express");
const { Pool } = require("pg");
const cors = require("cors");

const app = express();
app.use(express.json());
app.use(cors()); // Enable CORS for React app

const PORT = 8080;

// Database connection details from environment variables
// These will be injected by ECS from Secrets Manager
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT || 5432,
});

// Health check endpoint
app.get("/api/health", (req, res) => {
  res.status(200).send({ status: "UP" });
});

// A simple endpoint to get the current time from the database
app.get("/api/time", async (req, res) => {
  try {
    const result = await pool.query("SELECT NOW()");
    res.status(200).json({ db_time: result.rows[0].now });
  } catch (err) {
    console.error(err);
    res.status(500).send("Error connecting to the database");
  }
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log("--- Environment Variables ---");
  console.log("DB_USER:", process.env.DB_USER ? "SET" : "NOT SET");
  console.log("DB_HOST:", process.env.DB_HOST ? "SET" : "NOT SET");
  console.log("DB_NAME:", process.env.DB_NAME ? "SET" : "NOT SET");
  console.log("DB_PASSWORD:", process.env.DB_PASSWORD ? "SET" : "NOT SET");
  console.log("---------------------------");
});
