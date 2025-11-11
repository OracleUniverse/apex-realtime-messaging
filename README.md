# APEX Real-Time Messaging (RTM) Plug-in Suite

# APEX Real-Time Messaging (RTM) Plug-in Suite

A small, self-hosted **real-time message bus** for Oracle APEX.

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

---

## 1. Architecture

High-level flow:

```text
[ APEX Page (browser) ]
    ▲          │ WebSocket (wss://rtm.yourdomain.com)
    │          │
    │   RTM – Listener (DA plugin)
    │          │
    │     JSON events: { channel, eventName, payload, ... }
    │
[ Node.js RTM server ]
    ▲  HTTP POST /api/broadcast
    │
    │  WEBSOCKET_API.broadcast_item(...)
    │
[ Oracle DB (MLE JS) + PL/SQL ]
    ▲
[ APEX plug-ins: RTM – Broadcast (Process / DA) ]
Key ideas:

You (the developer) decide the message contract:

{
  "channel": "app_100_sales",
  "eventName": "refresh_sales",
  "payload": {
    "itemName": "P10_MESSAGE",
    "value": "Sales were updated"
  },
  "meta": {
    "user": "ORACLEVERSE",
    "appId": 100,
    "pageId": 10
  }
}
Channel and eventName are just strings. You can treat them as:

rooms, groups, tenants, apps, pages, per-user channels, etc.

On the browser side, the Listener:

filters by channel/event,

optionally updates an APEX item from payload,

fires a custom APEX event so any DA can react.

Infrastructure is deliberately small:

one Node.js app,

behind Nginx,

with Let’s Encrypt TLS,

running on an Oracle Linux compute instance.

2. Repository layout
Recommended structure:

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
You already have these SQL and plug-in export files; simply place them in this structure.

3. Requirements
APEX / Database
Oracle APEX 23.x or 24.x.

Database with MLE enabled (Autonomous DB or 23c+).

A schema to own:

RTM_LOG, RTM_LOG_API,

WEBSOCKET_SENDER_MODULE,

WEBSOCKET_SEND_BROADCAST,

WEBSOCKET_API.

Infrastructure
Oracle Cloud Infrastructure (OCI) tenancy.

1 compute instance:

Oracle Linux 8/9 image.

Small shape is enough (e.g. VM.Standard.E2.1.Micro or similar).

Public IP.

DNS A record:

rtm.yourdomain.com → <compute public IP>.

4. Step–by–step: Provision the Compute instance (OCI Console)
Create a VCN (if you don’t already have one)

Networking → Virtual Cloud Networks → Create VCN.

Include a public subnet.

Create the compute instance

Compute → Instances → Create instance.

Shape: small (e.g. 1 OCPU).

Image: Oracle Linux 9.

Network:

VCN: your VCN.

Subnet: public subnet.

Add SSH public key (for opc user).

Launch.

Open ports 80 and 443

Go to your VCN → Security Lists (or Network Security Groups).

Edit Ingress Rules for the security list attached to the instance’s subnet:

Allow TCP port 80 from 0.0.0.0/0.

Allow TCP port 443 from 0.0.0.0/0.

Point DNS to the instance

On your DNS provider:

Create an A record:
rtm.yourdomain.com → <public IP of the instance>.

5. Step–by–step: Configure the compute instance (Linux)
SSH to the instance:

ssh -i /path/to/key.pem opc@<public-ip>
5.1 System updates and base packages
sudo dnf update -y
sudo dnf install -y git nginx
Optional (but recommended): install Node.js 18+ from NodeSource or dnf module:

# Example: Node 18 via dnf module (if available)
sudo dnf module list nodejs
sudo dnf module enable nodejs:18 -y
sudo dnf install -y nodejs
node -v
npm -v
5.2 Enable and test Nginx
sudo systemctl enable --now nginx
sudo systemctl status nginx
If needed, open firewall (firewalld):

sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
From your browser, open http://rtm.yourdomain.com and confirm you see the Nginx welcome page.

5.3 Install Certbot and get TLS certificate
Enable EPEL (if not already):

sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --set-enabled ol9_developer_EPEL
sudo dnf install -y certbot python3-certbot-nginx
Run Certbot:

sudo certbot --nginx -d rtm.yourdomain.com
Enter email.

Accept Terms.

Choose the option that redirects HTTP → HTTPS.

That will:

Obtain a certificate under /etc/letsencrypt/live/rtm.yourdomain.com/.

Update Nginx config to serve HTTPS.

6. Install the RTM Node server
On the compute instance, as opc:

cd ~
git clone https://github.com/<your-github-user>/apex-rtm-websocket-plugin.git
cd apex-rtm-websocket-plugin/server
npm install
Check server/server.js – a typical implementation:

const http = require("http");
const WebSocket = require("ws");
const express = require("express");

const app = express();
app.use(express.json());

// Simple health check
app.get("/", (req, res) => {
  res.send("RTM WebSocket / REST bridge is running");
});

// Broadcast API that APEX / MLE calls
app.post("/api/broadcast", (req, res) => {
  const { channel, eventName, payload } = req.body || {};
  console.log("POST /api/broadcast", { channel, eventName, payload });

  if (!channel) {
    return res.status(400).json({ ok: false, message: "channel is required" });
  }

  const msg = JSON.stringify({ channel, eventName, payload });

  wss.clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(msg);
    }
  });

  res.json({ ok: true });
});

const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

wss.on("connection", (ws) => {
  console.log("WebSocket client connected");
  ws.on("message", data => console.log("WS message:", data.toString()));
  ws.on("close", () => console.log("WebSocket client disconnected"));
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`RTM server listening on http://localhost:${PORT}`);
});
Run it in the foreground to test:

node server.js
# You should see:
# RTM server listening on http://localhost:3000
Test from the VM:

curl http://localhost:3000/
# → "RTM WebSocket / REST bridge is running"
Stop it with Ctrl+C after testing; we’ll run it as a service or via PM2 later.

7. Configure Nginx as reverse proxy for RTM
Create /etc/nginx/conf.d/rtm.conf:

sudo nano /etc/nginx/conf.d/rtm.conf
Example content:

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
Test and reload:

sudo nginx -t
sudo systemctl reload nginx
Now your RTM server will be reachable at:

https://rtm.yourdomain.com/ (health endpoint),

WebSocket: wss://rtm.yourdomain.com/.

8. Run RTM server as a service (optional but recommended)
You can use PM2 or systemd. Example with PM2:

sudo npm install -g pm2
cd ~/apex-rtm-websocket-plugin/server
pm2 start server.js --name rtm-server
pm2 save
pm2 startup systemd   # follow printed command (sudo ...)
Check logs:

pm2 logs rtm-server --lines 50
9. Install DB objects
Connect to your DB as the schema owner (e.g. via SQL*Plus, SQLcl, or SQL Developer):

@db/01_rtm_log_table.sql
@db/02_rtm_log_api.sql
@db/03_websocket_sender_module.sql
@db/04_websocket_send_broadcast.sql
@db/05_websocket_api.sql
9.1 MLE and network access
Ensure your DB supports MLE (Autonomous Database or 23c+).

Grant EXECUTE on DBMS_MLE to your schema if needed.

Allow outbound HTTPS to rtm.yourdomain.com:

On ADB: configure Network ACLs in the ADB console for that host/port.

On on-prem / non-ADB: use DBMS_NETWORK_ACL_ADMIN to allow HTTPS from your schema to rtm.yourdomain.com:443.

10. Import APEX plug-ins
In APEX (SQL Workshop → SQL Commands), run:

@apex-plugins/dynamic_action_plugin_rtm_listener_da.sql
@apex-plugins/dynamic_action_plugin_rtm_broadcast_da.sql
@apex-plugins/process_type_plugin_rtm_broadcast_process.sql
After that, in Shared Components → Plug-ins, you should see:

Real-Time Messaging – Listener (DA)

Real-Time Messaging – Broadcast (DA)

Real-Time Messaging – Broadcast (Process)

11. How the plug-ins work (concept)
11.1 WEBSOCKET_API.broadcast_item
The DB API:

websocket_api.broadcast_item(
  p_api_key    => 'optional-api-key',
  p_base_url   => 'https://rtm.yourdomain.com',
  p_channel    => 'some-channel',
  p_event_name => 'some-event',
  p_payload    => '{"itemName":"P10_MESSAGE","value":"Hello"}'
);
internally calls MLE JavaScript (WEBSOCKET_SENDER_MODULE) which:

uses fetch() to POST to https://rtm.yourdomain.com/api/broadcast,

the Node server then broadcasts that JSON over WebSocket to all connected clients.

RTM_LOG_API records the broadcast into RTM_LOG.

11.2 RTM – Broadcast (Process)
PL/SQL process plug-in.

Typically runs after page processing/commit.

Reads an APEX item (Payload Item attribute), wraps it in JSON { itemName, value }.

Calls websocket_api.broadcast_item(...).

Logs to RTM_LOG.

Use this when:

You want messages only when the transaction succeeds,

Or from jobs, background processes, etc.

11.3 RTM – Broadcast (Dynamic Action)
DA plug-in.

Runs on client events (click, change, timer, etc.).

JS (broadcast_da.js) reads current item value in the browser and sends it to the plug-in AJAX callback.

AJAX callback calls websocket_api.broadcast_item(...) and logs the event.

Use this when:

You want user-driven events (chat messages, typing, live controls).

11.4 RTM – Listener (Dynamic Action)
DA plug-in.

JS (listener.js) opens a WebSocket connection to the base URL (e.g. wss://rtm.yourdomain.com).

Listens for messages and filters by channel + eventName.

If msg.payload.itemName and msg.payload.value exist, it updates that APEX item.

Triggers a custom APEX event (e.g. rtm-message) so other DAs can react.

Use this when:

You want pages to react in real time to server events.

12. End-to-end Example: “Hello” Broadcast
We’ll create one page where:

The page listens to messages on channel test.

A button sends the content of P10_MESSAGE to everyone on that channel.

RTM_LOG records the events.

12.1 Page structure
On Page 10:

Text item: P10_MESSAGE.

Region to display logs (optional).

Button: SEND_HELLO.

12.2 Listener DA
Create a Dynamic Action: RTM Listener – Test

Event: Page Load.

True Action: Real-Time Messaging – Listener (DA).

Attributes:

Base WebSocket URL: wss://rtm.yourdomain.com

Channel: test

Event Name: ping

APEX Event Name: rtm-message

This will connect to the server as the page loads and listen for messages on channel = test, eventName = ping.

12.3 DA Broadcast on button
Create DA: Broadcast Hello

Event: Click

Selection Type: Button

Button: SEND_HELLO.

True Action: Real-Time Messaging – Broadcast (DA).

Attributes:

API Key: (your API key, or leave empty if not enforced yet).

Base URL: https://rtm.yourdomain.com

Channel: test

Event Name: ping

Payload Item: P10_MESSAGE

On Error: LOG.

Now:

You type some text into P10_MESSAGE.

Click Send Hello.

The DA plug-in sends { itemName: "P10_MESSAGE", value: "<your text>" } to the Node server.

The Node server broadcasts it over WebSocket.

The Listener DA on the same (or other) sessions receives it, updates P10_MESSAGE (if you keep that behavior), and fires rtm-message.

You can add a second DA reacting to rtm-message:

Event: Custom.

Custom Event: rtm-message.

Selection Type: JavaScript Expression.

JavaScript Expression: document.

True Action: Execute JavaScript Code:

var msg = this.data;
console.log("RTM message on page:", msg);
apex.message.showPageSuccess("Received: " + (msg.payload && msg.payload.value));
13. Advanced Scenarios (ideas)
Because the plug-ins are generic, you can model many patterns just by choosing channel/event and payload:

Rooms / Groups

Use channels like chat:room:general, chat:room:ops, tenant:ACME.

Listener subscribes to the room; DA/Process broadcasts to it.

Per-user messages

Channel: user:&APP_USER.

From admin page, broadcast to user:SCOTT.

Only SCOTT’s sessions receive it.

Region refresh coordination

Channel: app_100:entity:CUSTOMER.

Event: customer-updated.

On P20 (edit page), Process plug-in broadcasts after successful update.

On P10 (dashboard), Listener triggers region refresh when that event arrives.

Background job notifications

DB scheduler job calls websocket_api.broadcast_item directly.

Channel: job:daily_rebuild.

Event: done.

Admin dashboard listens and shows toast + refreshes job history region.

Full chat

Page with P_CHAT_TEXT and a chat <div>:

DA Broadcast sends chat messages on channel chat:room:general.

Listener appends messages to the chat log and scrolls.

14. Generic use & flexibility
Why this is handy for real projects:

Message shape is yours
You’re not locked into “notification only”. You define the JSON structure based on your domain (orders, jobs, approvals, alerts…).

Generic routing
Channels and event names are just strings.
You can:

Map channels to apps, modules, companies, users, rooms, etc.

Map events to domain actions (order-updated, job-failed, new-message, etc.)

Any APEX behavior
Once listener.js fires your custom event, you can use standard APEX DAs to:

Refresh regions,

Set item values,

Execute PL/SQL,

Show dialogs,

Trigger other JS — all without changing the plug-in.

Small, self-contained infra
One compute instance, one Node service, one Nginx vhost, one DB schema.
Easy to replicate into another environment or into a customer’s infrastructure.

15. Uninstall
To uninstall DB parts:

@db/90_uninstall.sql
To remove plug-ins, delete them from APEX → Shared Components → Plug-ins.

To stop RTM server:

pm2 stop rtm-server   # if using PM2
pm2 delete rtm-server
# or kill the systemd service if you created one
To remove Nginx config:

sudo rm /etc/nginx/conf.d/rtm.conf
sudo systemctl reload nginx
16. License
Add your chosen OSS license in LICENSE (MIT / Apache-2.0, etc.) and mention it here.


