const express = require("express");
const mongoose = require("mongoose");

const app = express();
app.use(express.json());

const Task = mongoose.model("Task", new mongoose.Schema({ title: String }));

app.get("/api/health", (req, res) => res.json({ status: "ok" }));
app.get("/api/tasks", async (req, res) => res.json(await Task.find()));
app.post("/api/tasks", async (req, res) => {
  res.status(201).json(await Task.create({ title: req.body.title }));
});

mongoose
  .connect(process.env.MONGO_URL)
  .then(() => {
    console.log("Mongo connected");
    app.listen(5000, () => console.log("Server on port 5000"));
  })
  .catch((err) => {
    console.error("Mongo connection failed:", err.message);
    process.exit(1);
  });