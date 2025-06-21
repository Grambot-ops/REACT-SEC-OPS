// frontend-react/src/App.js
import React, { useState, useEffect } from "react";
import axios from "axios";
import "./App.css";

function App() {
  const [items, setItems] = useState([]);
  const [newItemName, setNewItemName] = useState("");

  // The API URL is the same domain, just with the /api prefix.
  // This is because CloudFront will route the request.
  const API_URL = "/api/items";

  const fetchItems = async () => {
    try {
      const response = await axios.get(API_URL);
      setItems(response.data);
    } catch (error) {
      console.error("Error fetching items:", error);
      alert(
        "Could not fetch items. Check console for details. Is the backend API running?"
      );
    }
  };

  useEffect(() => {
    fetchItems();
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!newItemName.trim()) return;
    try {
      await axios.post(API_URL, { name: newItemName });
      setNewItemName("");
      fetchItems(); // Refresh the list
    } catch (error) {
      console.error("Error adding item:", error);
      alert("Could not add item. Check console for details.");
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>React-Sec-Deploy Items</h1>
        <form onSubmit={handleSubmit}>
          <input
            type="text"
            value={newItemName}
            onChange={(e) => setNewItemName(e.target.value)}
            placeholder="Enter new item name"
          />
          <button type="submit">Add Item</button>
        </form>
        <ul>
          {items.map((item) => (
            <li key={item.id}>
              {item.id}: {item.name}
            </li>
          ))}
        </ul>
      </header>
    </div>
  );
}

export default App;
