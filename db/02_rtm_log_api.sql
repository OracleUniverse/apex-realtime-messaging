create or replace package body rtm_log_api as

  procedure log_event(
    p_source       in varchar2,
    p_channel      in varchar2,
    p_event_name   in varchar2,
    p_payload_json in clob,
    p_http_status  in number,
    p_extra_info   in varchar2,
    p_error        in varchar2
  ) is
  begin
    insert into rtm_log(
      source,
      channel,
      event_name,
      payload_json,
      http_status,
      extra_info,
      error_message
    )
    values(
      p_source,
      p_channel,
      p_event_name,
      p_payload_json,
      p_http_status,
      p_extra_info,
      p_error
    );
  exception
    when others then
      -- Never break the app because logging failed
      null;
  end log_event;

end rtm_log_api;
/