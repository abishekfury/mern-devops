import { useEffect, useState } from "react";

export default function App() {
  const [tasks, setTasks] = useState([]);
  const [title, setTitle] = useState("");

  const load = async () => {
    const res = await fetch("/api/tasks");
    setTasks(await res.json());
  };

  useEffect(() => { load(); }, []);

  const add = async (e) => {
    e.preventDefault();
    await fetch("/api/tasks", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ title }),
    });
    setTitle("");
    load();
  };

  return (
    <div style={{ maxWidth: 400, margin: "40px auto" }}>
      <h1>My Tasks V3</h1>
      <form onSubmit={add}>
        <input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="New task" />
        <button>Add</button>
      </form>
      <ul>{tasks.map((t) => <li key={t._id}>{t.title}</li>)}</ul>
    </div>
  );
}