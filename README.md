# Multiplayer Cookie Clicker — ETS Version

A real-time multiplayer web application built with **Phoenix LiveView** and **Elixir ETS**, demonstrating shared in-memory state management using Erlang Term Storage.

> For a comparison using GenServer-based state management, see the [GenServer version](https://github.com/vincentping/cookieclicker-genserver).

## Technical Highlights

- **ETS (Erlang Term Storage)** for shared, concurrent in-memory state — all game rooms read and write to a single table
- **Phoenix PubSub** for real-time event broadcasting across all connected LiveView clients
- **Phoenix LiveView** for server-side rendered UI with WebSocket-driven updates, no custom JavaScript required
- Concurrent reads without locking, making ETS suitable for read-heavy workloads

## Architecture Decision

ETS was chosen for this version to explore shared global state as an alternative to per-process state. ETS tables support concurrent reads natively, offering better throughput when many clients are reading the same data simultaneously.

The trade-off is that ETS lacks the process isolation of GenServer — all sessions share the same table, so write contention and error isolation require more careful design. For a version with stronger session isolation via OTP supervision, see the [GenServer version](https://github.com/vincentping/cookieclicker-genserver).

## Tech Stack

- Elixir / OTP
- Phoenix 1.8.1
- Phoenix LiveView 1.1.13

## Prerequisites

- Elixir 1.14+
- Erlang/OTP 25+

## Getting Started
```bash
# Install dependencies
mix setup

# Start the Phoenix server
mix phx.server

# Or start inside IEx for interactive debugging
iex -S mix phx.server
```

Visit [localhost:4000](http://localhost:4000) in your browser.

Open multiple browser tabs to simulate multiplayer — each tab represents a separate player.

## License

MIT