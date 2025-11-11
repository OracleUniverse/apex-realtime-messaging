
  CREATE OR REPLACE MLE MODULE "WEBSOCKET_SENDER_MODULE" 
   LANGUAGE JAVASCRIPT AS 
import { fetch } from "mle-js-fetch";

/*
  sendBroadcast
  -------------
*/
export async function sendBroadcast(apiKey, baseUrl, channel, eventName, payload) {
  if (!baseUrl) {
    throw new Error("sendBroadcast: baseUrl is required");
  }
  if (!channel) {
    throw new Error("sendBroadcast: channel is required");
  }

  const url = baseUrl.replace(/\/+$/, "") + "/api/broadcast";

  let parsedPayload;
  try {
    parsedPayload = payload ? JSON.parse(payload) : {};
  } catch (e) {
    throw new Error("sendBroadcast: invalid payload JSON - " + e.message);
  }

  const body = {
    channel: channel,
    eventName: eventName || null,
    payload: parsedPayload
  };

  const headers = {
    "Content-Type": "application/json"
  };

  if (apiKey) {
    headers["x-api-key"] = apiKey;
  }

  const resp = await fetch(url, {
    method: "POST",
    headers: headers,
    body: JSON.stringify(body)
  });

  if (!resp.ok) {
    const text = await resp.text();
    throw new Error("Broadcast failed: HTTP " + resp.status + " - " + text);
  }

  return true;
}
/