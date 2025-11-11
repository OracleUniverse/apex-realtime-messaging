create or replace PROCEDURE websocket_send_broadcast(
  p_api_key    IN VARCHAR2,
  p_base_url   IN VARCHAR2,
  p_channel    IN VARCHAR2,
  p_event_name IN VARCHAR2,
  p_payload    IN VARCHAR2
)
AS MLE MODULE WEBSOCKET_SENDER_MODULE
SIGNATURE 'sendBroadcast(string,string,string,string,string)';
/