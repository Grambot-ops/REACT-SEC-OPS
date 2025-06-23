import React, { useState, useEffect } from "react";
import "./App.css";

// IMPORTANT: Replace this with your actual ALB DNS Name from OpenTofu output
const API_ENDPOINT = "http://<your-alb-dns-name>";

function App() {
  const [apiStatus, setApiStatus] = useState("Checking...");
  const [dbTime, setDbTime] = useState("N/A");

  useEffect(() => {
    // Fetch API health
    fetch(`${API_ENDPOINT}/api/health`)
      .then((response) => response.json())
      .then((data) => setApiStatus(data.status || "Error"))
      .catch(() => setApiStatus("Unreachable"));
  }, []);

  const fetchDbTime = () => {
    setDbTime("Fetching...");
    fetch(`${API_ENDPOINT}/api/time`)
      .then((response) => response.json())
      .then((data) => setDbTime(data.db_time || "Error"))
      .catch(() => setDbTime("Failed to fetch"));
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>React-Sec-Ops 3-Tier Application</h1>
        <p>This app demonstrates a secure deployment on AWS.</p>
        <div className="status-card">
          <h2>Backend API Status</h2>
          <p className={`status ${apiStatus.toLowerCase()}`}>{apiStatus}</p>
        </div>
        <div className="db-card">
          <h2>Database Connectivity</h2>
          <button onClick={fetchDbTime}>Get Time from Database</button>
          <p>
            PostgreSQL Server Time: <strong>{dbTime}</strong>
          </p>
        </div>
      </header>
    </div>
  );
}

export default App;
