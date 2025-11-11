create or replace package websocket_api as
  procedure broadcast_item(
    p_api_key    in varchar2,  -- optional; can be NULL to use default
    p_base_url   in varchar2,  -- optional; can be NULL to use default
    p_channel    in varchar2,
    p_event_name in varchar2,
    p_payload    in clob       -- JSON string
  );
end websocket_api;
/



create or replace package body websocket_api as

  -- Defaults if plugin attributes are left empty
  g_default_base_url constant varchar2(200) := 'https://rtm.oracleapex.cloud';
  g_default_api_key  constant varchar2(200) := '0301198103011981';

  -- simple string-escaper for JSON values (very basic, enough for channel/event)
  function esc(p_str in varchar2) return varchar2 is
  begin
    return replace(replace(p_str, '\', '\\'), '"', '\"');
  end;

  procedure broadcast_item(
    p_api_key    in varchar2,
    p_base_url   in varchar2,
    p_channel    in varchar2,
    p_event_name in varchar2,
    p_payload    in clob
  ) is
    l_base_url   varchar2(200);
    l_api_key    varchar2(200);
    l_body       clob;
    l_response   clob;
    l_status     pls_integer;
  begin
    -- Resolve URL / API key (plugin attribute or default)
    l_base_url := nvl(trim(p_base_url), g_default_base_url);
    l_api_key  := nvl(trim(p_api_key),  g_default_api_key);

    -- Build JSON body EXACTLY as Node expects:
    -- { "channel": "test", "event_name": "ping", "payload": { ... } }
    --
    -- p_payload must be valid JSON *object or array*, e.g.:
    --   { "itemName": "P10_MESSAGE", "value": "Hello" }
    --
    l_body :=
         '{'
      || '"channel":"'    || esc(p_channel)    || '"'
      || ',"event_name":"'|| esc(p_event_name) || '"'
      || ',"payload":'    || nvl(p_payload, '{}')
      || '}';

    -- HTTP headers
    apex_web_service.g_request_headers.delete;
    apex_web_service.g_request_headers(1).name  := 'Content-Type';
    apex_web_service.g_request_headers(1).value := 'application/json';
    apex_web_service.g_request_headers(2).name  := 'x-api-key';
    apex_web_service.g_request_headers(2).value := l_api_key;

    -- REST call
    l_response := apex_web_service.make_rest_request(
      p_url         => l_base_url || '/api/broadcast',
      p_http_method => 'POST',
      p_body        => l_body
    );

    l_status := apex_web_service.g_status_code;

    -- Log outcome
    rtm_log_api.log_event(
      p_source       => 'APEX',
      p_channel      => p_channel,
      p_event_name   => p_event_name,
      p_payload_json => p_payload,
      p_http_status  => l_status,
      p_extra_info   => substr(l_response, 1, 4000)
    );

    if l_status not between 200 and 299 then
      raise_application_error(
        -20000,
        'RTM broadcast failed, HTTP status=' || l_status
      );
    end if;

  exception
    when others then
      rtm_log_api.log_event(
        p_source       => 'APEX',
        p_channel      => p_channel,
        p_event_name   => p_event_name,
        p_payload_json => p_payload,
        p_error        => sqlerrm
      );
      raise;
  end broadcast_item;

end websocket_api;
/