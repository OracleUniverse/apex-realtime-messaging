# APEX Real-Time Messaging (RTM)

A small, self-hosted **real-time message bus** for Oracle APEX.

---

## 🚀 Overview

**APEX RTM** provides a real-time messaging layer that allows APEX applications to communicate instantly between browser sessions and server events.  

It includes:
- A **Node.js WebSocket bridge** running on Oracle Cloud.
- **3 APEX plug-ins:**
  - `RTM – Listener (Dynamic Action)`
  - `RTM – Broadcast (Dynamic Action)`
  - `RTM – Broadcast (Process)`
- A **DB-side MLE JavaScript module** + PL/SQL API (`WEBSOCKET_API`).
- A **logging layer** (`RTM_LOG`, `RTM_LOG_API`) for message tracking.

With it, you can:
- Push JSON messages from PL/SQL or browser events.
- Define **who** receives messages and **how** they’re handled.
- Implement notifications, live dashboards, chat systems, and more — all within APEX.

---

## 🧩 Architecture

```
[ APEX Page (Browser) ]
    ▲           │ WebSocket (wss://rtm.yourdomain.com)
    │           │
    │   RTM – Listener (DA plugin)
    │           │
    │     JSON events: { channel, eventName, payload, ... }
    │
[ Node.js RTM Server ]
    ▲   HTTP POST /api/broadcast
    │
    │  WEBSOCKET_API.broadcast_item(...)
    │
[ Oracle DB (MLE JS) + PL/SQL ]
    ▲
[ APEX Plug-ins: RTM – Broadcast (Process / DA) ]
```

**Key idea:**  
You define the message contract (channel, event name, payload).  
Messages can represent per-user, per-room, or per-page communication.

---

## 📁 Repository Structure

```
apex-rtm-websocket-plugin/
├─ README.md
├─ LICENSE
│
├─ db/
│  ├─ 01_rtm_log_table.sql
│  ├─ 02_rtm_log_api.sql
│  ├─ 03_websocket_sender_module.sql
│  ├─ 04_websocket_send_broadcast.sql
│  ├─ 05_websocket_api.sql
│  └─ 90_uninstall.sql
│
├─ apex-plugins/
│  ├─ dynamic_action_plugin_rtm_listener_da.sql
│  ├─ dynamic_action_plugin_rtm_broadcast_da.sql
│  └─ process_type_plugin_rtm_broadcast_process.sql
│
├─ client-js/
│  ├─ listener.js
│  └─ broadcast_da.js
│
└─ server/
   ├─ package.json
   ├─ server.js
   └─ nginx-rtm.conf.example
```

---

## ⚙️ Requirements

### Oracle APEX / Database
- **APEX** 23.x or 24.x
- **Database** with MLE (Autonomous DB or 23c+)
- Schema owning:
  - `RTM_LOG`, `RTM_LOG_API`
  - `WEBSOCKET_SENDER_MODULE`
  - `WEBSOCKET_SEND_BROADCAST`
  - `WEBSOCKET_API`

### Infrastructure
- Oracle Cloud Infrastructure (OCI)
- 1 Compute instance (Oracle Linux 8/9)
- Public IP + DNS A record  
  Example:  
  `rtm.yourdomain.com → <public IP>`

---

## 🖥️ Setup Guide

### 1. Provision OCI Compute Instance
1. Create VCN with public subnet  
2. Launch instance (e.g., `VM.Standard.E2.1.Micro`)  
3. Open ports **80** and **443**  
4. Point DNS to the instance  

### 2. Configure the Instance
SSH into the instance:
```bash
ssh -i /path/to/key.pem opc@<public-ip>
```

Install dependencies:
```bash
sudo dnf update -y
sudo dnf install -y git nginx
sudo dnf module enable nodejs:18 -y
sudo dnf install -y nodejs
```

Enable and verify Nginx:
```bash
sudo systemctl enable --now nginx
```

Install TLS via Certbot:
```bash
sudo dnf install -y certbot python3-certbot-nginx
sudo certbot --nginx -d rtm.yourdomain.com
```

---

## 🧠 Node.js RTM Server Setup

Clone and run the RTM server:

```bash
git clone https://github.com/<your-username>/apex-rtm-websocket-plugin.git
cd apex-rtm-websocket-plugin/server
npm install
node server.js
```

The server listens on port `3000` and exposes:
- REST API: `POST /api/broadcast`
- WebSocket: `wss://rtm.yourdomain.com`

**Example:**  
Broadcast endpoint receives `{ channel, eventName, payload }` and sends JSON to all WebSocket clients.

---

## 🌐 Nginx Reverse Proxy

Example `/etc/nginx/conf.d/rtm.conf`:

```nginx
server {
    listen 443 ssl;
    server_name rtm.yourdomain.com;

    ssl_certificate     /etc/letsencrypt/live/rtm.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/rtm.yourdomain.com/privkey.pem;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

Reload:
```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🔄 Run as a Service (PM2)

```bash
sudo npm install -g pm2
pm2 start server.js --name rtm-server
pm2 save
pm2 startup systemd
```

---

## 🗃️ Database Installation

Run the scripts in order:

```sql
@db/01_rtm_log_table.sql
@db/02_rtm_log_api.sql
@db/03_websocket_sender_module.sql
@db/04_websocket_send_broadcast.sql
@db/05_websocket_api.sql
```

Ensure outbound HTTPS to your RTM host is allowed (via Network ACLs).

---

## 🧩 APEX Plug-ins Installation

In APEX → **SQL Workshop → SQL Commands**, run:

```sql
@apex-plugins/dynamic_action_plugin_rtm_listener_da.sql
@apex-plugins/dynamic_action_plugin_rtm_broadcast_da.sql
@apex-plugins/process_type_plugin_rtm_broadcast_process.sql
```

---

## 💡 How It Works

### WEBSOCKET_API.broadcast_item
Broadcasts a JSON payload via HTTPS POST to `/api/broadcast`.

### RTM – Broadcast (Process)
Runs after commits to push DB-side events.

### RTM – Broadcast (DA)
Triggers from browser events (click, change, etc.).

### RTM – Listener (DA)
Listens for messages and fires custom APEX events for reactive UI updates.

---

## 🔔 Example: “Hello” Broadcast

**Scenario:** One page broadcasts messages to others in real time.

1. Create item `P10_MESSAGE`  
2. Create button `SEND_HELLO`  
3. Add two Dynamic Actions:
   - **Listener:** Listens on `channel=test`, `event=ping`
   - **Broadcast:** Sends `P10_MESSAGE` via `https://rtm.yourdomain.com`

When you click **Send Hello**, all connected sessions instantly receive the update.

---

## 💬 Advanced Use Cases

- **Per-user notifications** (`user:&APP_USER`)
- **Group/Room chat systems**
- **Live region refresh coordination**
- **Background job updates**
- **Cross-application event triggers**

---

## 🧹 Uninstall

```sql
@db/90_uninstall.sql
```

Remove plug-ins via APEX → *Shared Components → Plug-ins*  
Stop service:
```bash
pm2 stop rtm-server && pm2 delete rtm-server
```

Remove Nginx config and reload.

---

## 📄 License

This project is open source.  
Add your chosen license (MIT / Apache-2.0) in the `LICENSE` file.

---

## 🧱 Summary

**APEX RTM** provides a minimal, self-contained infrastructure for enabling **real-time interactivity** in Oracle APEX applications — without external services.

---

**Author:** *[Your Name or Team]*  
**Contact:** *your.email@example.com*  
**GitHub:** [github.com/your-username/apex-rtm-websocket-plugin](https://github.com/your-username/apex-rtm-websocket-plugin)
