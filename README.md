# APEX Real-Time Messaging (RTM) Plug-in Suite

A small, self-hosted **real-time message bus** for Oracle APEX.

---

## 🔍 Overview

It gives you:

- A **Node.js WebSocket bridge** running on an Oracle Cloud Compute instance.
- 3 APEX plug-ins:
  - **RTM – Listener (Dynamic Action)**  
  - **RTM – Broadcast (Dynamic Action)**  
  - **RTM – Broadcast (Process)**
- A **DB-side MLE JavaScript module** + PL/SQL API (`WEBSOCKET_API`).
- A logging layer (`RTM_LOG` + `RTM_LOG_API`) to track every broadcast.

With it, you can:

- Push JSON messages from PL/SQL or the browser (DA) to any APEX page in real time.
- Decide **what the message looks like**, and based on that:
  - who should see it (user / group / room / page / app / tenant),
  - and what happens (notify, refresh, set item, run DA, etc.).

In other words, this is not “just a notification plug-in”; it is a **generic real-time messaging layer** inside APEX that you can bend any way you like.

We’re going to build a generic real-time messaging layer for APEX:

- A small Node.js WebSocket + REST server on an Oracle Linux compute instance.
- A DB-side MLE JS module + PL/SQL API to POST to that server.
- An APEX Listener DA plug-in to open a WebSocket and receive messages.
- A Broadcast Process plug-in and Broadcast DA plug-in to send messages.

You (or any developer) will be able to decide:

- What goes in the message (JSON shape),
- Which channel that message goes to (user / group / room / page / tenant),
- What happens in APEX when the message arrives (notify, refresh, set item, run DA, etc.).

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


## ⚙️ PART 1 – Oracle Cloud Compute & RTM Server

### 1. Create the compute instance (OCI console)

This is one-time infra by the admin.

In **OCI Console → Networking → Virtual Cloud Networks**:

- Create or use an existing VCN with a public subnet.

In **OCI → Compute → Instances → Create instance**:

- Name: `rtm-server` (or anything).
- Image: **Oracle Linux 9**.
- Shape: small (e.g. 1 OCPU, 1–2 GB RAM).

Networking:

- VCN: your VCN.
- Subnet: public subnet.
- Add your SSH public key for `opc`.
- Launch.

Open ports **80** and **443** in your security list / NSG:

- Allow TCP 80 from `0.0.0.0/0`.
- Allow TCP 443 from `0.0.0.0/0`.

In your DNS provider:

Create **A record**:

```text
rtm.yourdomain.com → <public IP of the instance>
```

---

### 2. Connect and prepare the OS

SSH into the instance:

```bash
ssh -i /path/to/key.pem opc@<public-ip>
```

#### 2.1 Update system & install tools

```bash
sudo dnf update -y
sudo dnf install -y git nginx
```


Node.js 18+ is recommended. On Oracle Linux 9:

```bash
sudo dnf module list nodejs
sudo dnf module enable nodejs:18 -y
sudo dnf install -y nodejs
node -v
npm -v
```

#### 2.2 Enable and test Nginx

```bash
sudo systemctl enable --now nginx
sudo systemctl status nginx
```

If `firewalld` is running:

```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

Test from your browser:

Visit:

```text
http://rtm.yourdomain.com
```

→ you should see the Nginx welcome page.

---

### 3. Install TLS certificate (Let’s Encrypt + Certbot)

Enable EPEL and install Certbot:

```bash
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --set-enabled ol9_developer_EPEL
sudo dnf install -y certbot python3-certbot-nginx
```

Obtain a certificate:

```bash
sudo certbot --nginx -d rtm.yourdomain.com
```

- Enter email.
- Accept ToS.
- Choose the option to redirect HTTP → HTTPS.

This configures HTTPS for the default Nginx vhost.

---

### 4. Create the RTM Node server

Now we manually build the Node server.

#### 4.1 Create the app directory

```bash
mkdir -p /home/opc/websocket-server
cd /home/opc/websocket-server
```

#### 4.2 Create `package.json`

Create the file:

```bash
nano package.json
```

Paste:

```json
{
  "name": "apex-rtm-websocket-server",
  "version": "1.0.0",
  "description": "Simple RTM bridge for Oracle APEX (WebSocket + REST)",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.21.0",
    "ws": "^8.17.0"
  }
}
```

Save and exit: `Ctrl+O`, `Enter`, `Ctrl+X`.

Install dependencies:

```bash
npm install
```

#### 4.3 Create `server.js`

```bash
nano server.js
```

Paste:

```js
// server.js
const http = require("http");
const WebSocket = require("ws");
const express = require("express");

const app = express();
app.use(express.json());

// Simple health check
app.get("/", (req, res) => {
  res.send("RTM WebSocket / REST bridge is running");
});

// Broadcast API that DB/APEX calls
app.post("/api/broadcast", (req, res) => {
  const { channel, eventName, payload } = req.body || {};
  console.log("POST /api/broadcast", { channel, eventName, payload });

  if (!channel) {
    return res.status(400).json({ ok: false, message: "channel is required" });
  }

  const msg = JSON.stringify({
    channel,
    eventName,
    payload
  });

  // Send to all connected WS clients
  wss.clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(msg);
    }
  });

  res.json({ ok: true });
});

const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

// When a WebSocket client connects
wss.on("connection", (ws) => {
  console.log("WebSocket client connected");

  ws.on("message", data => {
    console.log("WS message:", data.toString());
  });

  ws.on("close", () => {
    console.log("WebSocket client disconnected");
  });
});

// Internal HTTP port (Nginx will proxy HTTPS → this)
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`RTM server listening on http://localhost:${PORT}`);
});
```

Save and exit.

#### 4.4 Test the RTM server locally

```bash
cd /home/opc/websocket-server
node server.js
# You should see:
# RTM server listening on http://localhost:3000
```

Open a second SSH session and test:

```bash
curl http://localhost:3000/
# → RTM WebSocket / REST bridge is running
```

Stop the Node process with `Ctrl+C` when done.

---

### 5. Configure Nginx to reverse proxy to Node

#### 5.1 Create a dedicated vhost config

```bash
sudo nano /etc/nginx/conf.d/rtm.conf
```

Paste:

```nginx
# Redirect HTTP → HTTPS
server {
    listen 80;
    server_name rtm.yourdomain.com;

    location /.well-known/acme-challenge/ {
        root /usr/share/nginx/html;
    }

    return 301 https://$host$request_uri;
}

# HTTPS reverse proxy for RTM server (port 3000)
server {
    listen 443 ssl;
    server_name rtm.yourdomain.com;

    ssl_certificate     /etc/letsencrypt/live/rtm.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/rtm.yourdomain.com/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Test and reload:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

#### 5.2 Run the Node server in the background (simple way)

You can later move to PM2/systemd. For now, a simple approach:

```bash
cd /home/opc/websocket-server
nohup node server.js > rtm.log 2>&1 &
```

Check:

```bash
ps aux | grep server.js
curl https://rtm.yourdomain.com/
```

You should see the health message from the Node app.

---

### 6. Run RTM server as a service (optional but recommended)

You can use PM2 or systemd. Example with PM2:

```bash
sudo npm install -g pm2
cd ~/apex-rtm-websocket-plugin/server
pm2 start server.js --name rtm-server
pm2 save
pm2 startup systemd   # follow printed command (sudo ...)
```

Check logs:

```bash
pm2 logs rtm-server --lines 50
```

---

## 🗃️ PART 2 –  Install DB Objects

Connect to your DB as the schema owner (e.g. via SQL*Plus, SQLcl, or SQL Developer):

```sql
@db/01_rtm_log_table.sql
@db/02_rtm_log_api.sql
@db/03_websocket_sender_module.sql
@db/04_websocket_send_broadcast.sql
@db/05_websocket_api.sql
```

### 1. MLE and network access

Ensure your DB supports MLE (Autonomous Database or 23c+).

Grant `EXECUTE` on `DBMS_MLE` to your schema if needed.

Allow outbound HTTPS to `rtm.yourdomain.com`:

- **On ADB**: configure Network ACLs in the ADB console for that host/port.
- **On on-prem / non-ADB**: use `DBMS_NETWORK_ACL_ADMIN` to allow HTTPS from your schema to `rtm.yourdomain.com:443`.

---

### 2. Import APEX Plug-ins

In APEX (**SQL Workshop → SQL Commands**), run:

```sql
@apex-plugins/dynamic_action_plugin_rtm_listener_da.sql
@apex-plugins/dynamic_action_plugin_rtm_broadcast_da.sql
@apex-plugins/process_type_plugin_rtm_broadcast_process.sql
```

After that, in **Shared Components → Plug-ins**, you should see:

- Real-Time Messaging – Listener (DA)
- Real-Time Messaging – Broadcast (DA)
- Real-Time Messaging – Broadcast (Process)

---

#### How the Plug-ins Work (Concept)

##### `WEBSOCKET_API.broadcast_item`

The DB API:

```plsql
websocket_api.broadcast_item(
  p_api_key    => 'optional-api-key',
  p_base_url   => 'https://rtm.yourdomain.com',
  p_channel    => 'some-channel',
  p_event_name => 'some-event',
  p_payload    => '{"itemName":"P10_MESSAGE","value":"Hello"}'
);
```

internally calls MLE JavaScript (`WEBSOCKET_SENDER_MODULE`) which:

- uses `fetch()` to POST to `https://rtm.yourdomain.com/api/broadcast`,
- the Node server then broadcasts that JSON over WebSocket to all connected clients.

`RTM_LOG_API` records the broadcast into `RTM_LOG`.

---

#### 2.1 RTM – Broadcast (Process)

- PL/SQL process plug-in.
- Typically runs after page processing/commit.
- Reads an APEX item (**Payload Item** attribute), wraps it in JSON `{ itemName, value }`.
- Calls `websocket_api.broadcast_item(...)`.
- Logs to `RTM_LOG`.

Use this when:

- You want messages only when the transaction succeeds,
- Or from jobs, background processes, etc.

---

#### 2.2 RTM – Broadcast (Dynamic Action)

- DA plug-in.
- Runs on client events (click, change, timer, etc.).
- JS (`broadcast_da.js`) reads current item value in the browser and sends it to the plug-in AJAX callback.
- AJAX callback calls `websocket_api.broadcast_item(...)` and logs the event.

Use this when:

- You want user-driven events (chat messages, typing, live controls).

---

#### 2.3 RTM – Listener (Dynamic Action)

- DA plug-in.
- JS (`listener.js`) opens a WebSocket connection to the base URL (e.g. `wss://rtm.yourdomain.com`).
- Listens for messages and filters by `channel` + `eventName`.
- If `msg.payload.itemName` and `msg.payload.value` exist, it updates that APEX item.
- Triggers a custom APEX event (e.g. `rtm-message`) so other DAs can react.

Use this when:

- You want pages to react in real time to server events.

---

## 📡 PART 3 – End-to-End Example: “Hello” Broadcast

We’ll create one page where:

- The page listens to messages on channel `test`.
- A button sends the content of `P10_MESSAGE` to everyone on that channel.
- `RTM_LOG` records the events.

### 1. Page structure

On Page 10:

- Text item: `P10_MESSAGE`.
- Region to display logs (optional).
- Button: `SEND_HELLO`.

### 2. Listener DA

Create a Dynamic Action: **RTM Listener – Test**

- Event: `Page Load`.

True Action: **Real-Time Messaging – Listener (DA)**.

Attributes:

- Base WebSocket URL: `wss://rtm.yourdomain.com`
- Channel: `test`
- Event Name: `ping`
- APEX Event Name: `rtm-message`

This will connect to the server as the page loads and listen for messages on `channel = test`, `eventName = ping`.

### 3. DA Broadcast on button

Create DA: **Broadcast Hello**

- Event: `Click`
- Selection Type: `Button`
- Button: `SEND_HELLO`.

True Action: **Real-Time Messaging – Broadcast (DA)**.

Attributes:

- API Key: (your API key, or leave empty if not enforced yet).
- Base URL: `https://rtm.yourdomain.com`
- Channel: `test`
- Event Name: `ping`
- Payload Item: `P10_MESSAGE`
- On Error: `LOG`.

Now:

- You type some text into `P10_MESSAGE`.
- Click **Send Hello**.
- The DA plug-in sends `{ itemName: "P10_MESSAGE", value: "<your text>" }` to the Node server.
- The Node server broadcasts it over WebSocket.
- The Listener DA on the same (or other) sessions receives it, updates `P10_MESSAGE` (if you keep that behavior), and fires `rtm-message`.

You can add a second DA reacting to `rtm-message`:

- Event: `Custom`.
- Custom Event: `rtm-message`.
- Selection Type: `JavaScript Expression`.
- JavaScript Expression: `document`.

True Action: **Execute JavaScript Code**:

```js
var msg = this.data;
console.log("RTM message on page:", msg);
apex.message.showPageSuccess("Received: " + (msg.payload && msg.payload.value));
```

---

## 🧩 PART 4 – Advanced Scenarios (Ideas)

Because the plug-ins are generic, you can model many patterns just by choosing `channel` / `event` and `payload`:

### Rooms / Groups

- Use channels like `chat:room:general`, `chat:room:ops`, `tenant:ACME`.
- Listener subscribes to the room; DA/Process broadcasts to it.

### Per-user messages

- Channel: `user:&APP_USER`.
- From admin page, broadcast to `user:SCOTT`.
- Only SCOTT’s sessions receive it.

### Region refresh coordination

- Channel: `app_100:entity:CUSTOMER`.
- Event: `customer-updated`.
- On P20 (edit page), Process plug-in broadcasts after successful update.
- On P10 (dashboard), Listener triggers region refresh when that event arrives.

### Background job notifications

- DB scheduler job calls `websocket_api.broadcast_item` directly.
- Channel: `job:daily_rebuild`.
- Event: `done`.
- Admin dashboard listens and shows toast + refreshes job history region.

### Full chat

- Page with `P_CHAT_TEXT` and a chat `<div>`:
  - DA Broadcast sends chat messages on channel `chat:room:general`.
  - Listener appends messages to the chat log and scrolls.

---

## 🧱 PART 5 – Generic Use & Flexibility

Why this is handy for real projects:

### Message shape is yours

You’re not locked into “notification only”. You define the JSON structure based on your domain (orders, jobs, approvals, alerts…).

### Generic routing

Channels and event names are just strings. You can:

- Map channels to apps, modules, companies, users, rooms, etc.
- Map events to domain actions (`order-updated`, `job-failed`, `new-message`, etc.)

### Any APEX behavior

Once `listener.js` fires your custom event, you can use standard APEX DAs to:

- Refresh regions,
- Set item values,
- Execute PL/SQL,
- Show dialogs,
- Trigger other JS — all without changing the plug-in.

### Small, self-contained infra

One compute instance, one Node service, one Nginx vhost, one DB schema.  
Easy to replicate into another environment or into a customer’s infrastructure.

---

## 🗑️ PART 6 – Uninstall

To uninstall DB parts:

```sql
@db/90_uninstall.sql
```

To remove plug-ins, delete them from:

- APEX → **Shared Components → Plug-ins**.

To stop RTM server:

```bash
pm2 stop rtm-server   # if using PM2
pm2 delete rtm-server
# or kill the systemd service if you created one
```

To remove Nginx config:

```bash
sudo rm /etc/nginx/conf.d/rtm.conf
sudo systemctl reload nginx
```

---

## 💖 Support the Project

If you find **Tree Select Plugin for Oracle APEX** helpful in your applications,  
you can support its continued development and future enhancements.

Your support helps keep this plugin open, documented, and frequently updated.

**Support options:**

[![Donate](https://img.shields.io/badge/☕_Donate-via_PayPal-blue?logo=paypal)](https://paypal.me/mtmnq)
[![WhatsApp](https://img.shields.io/badge/Chat_on-WhatsApp-green?logo=whatsapp)](https://wa.me/962777437216)

- ☕ **Donate via PayPal:** <https://paypal.me/mtmnq>  
- 💬 **Chat on WhatsApp:** <https://wa.me/962777437216>

Or visit the project page:  
🌐 [oracleapex.cloud](https://oracleapex.cloud)

---

## 📄 License

Released under the **MIT License**.  
Free for personal and commercial use — attribution appreciated.

---

## 👨‍💻 Author & Contact

**Mohammad Alquran**  
🌐 Website: [oracleapex.cloud](https://oracleapex.cloud)  
💌 Email: [moh.alquraan@gmail.com](mailto:moh.alquraan@gmail.com)  
💬 WhatsApp: <https://wa.me/962777437216>

