prompt --application/set_environment
set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
--------------------------------------------------------------------------------
--
-- Oracle APEX export file
--
-- You should run this script using a SQL client connected to the database as
-- the owner (parsing schema) of the application or as a database user with the
-- APEX_ADMINISTRATOR_ROLE role.
--
-- This export file has been automatically generated. Modifying this file is not
-- supported by Oracle and can lead to unexpected application and/or instance
-- behavior now or in the future.
--
-- NOTE: Calls to apex_application_install override the defaults below.
--
--------------------------------------------------------------------------------
begin
wwv_flow_imp.import_begin (
 p_version_yyyy_mm_dd=>'2024.11.30'
,p_release=>'24.2.10'
,p_default_workspace_id=>100001
,p_default_application_id=>146
,p_default_id_offset=>0
,p_default_owner=>'WKSP_ORACLEVERSE'
);
end;
/
 
prompt APPLICATION 146 - Real-Time Messaging Plug-in
--
-- Application Export:
--   Application:     146
--   Name:            Real-Time Messaging Plug-in
--   Date and Time:   08:25 Tuesday November 11, 2025
--   Exported By:     ADMIN
--   Flashback:       0
--   Export Type:     Component Export
--   Manifest
--     PLUGIN: 43881050044296010
--   Manifest End
--   Version:         24.2.10
--   Instance ID:     7727405682615679
--

begin
  -- replace components
  wwv_flow_imp.g_mode := 'REPLACE';
end;
/
prompt --application/shared_components/plugins/process_type/rtm_broadcast_process
begin
wwv_flow_imp_shared.create_plugin(
 p_id=>wwv_flow_imp.id(43881050044296010)
,p_plugin_type=>'PROCESS TYPE'
,p_name=>'RTM_BROADCAST_PROCESS'
,p_display_name=>'Real-Time Messaging - Broadcast (Process)'
,p_category=>'EXECUTE'
,p_supported_component_types=>'APEX_APPLICATION_PAGE_PROC:APEX_APPL_AUTOMATION_ACTIONS:APEX_APPL_TASKDEF_ACTIONS:APEX_APPL_WORKFLOW_ACTIVITIES'
,p_plsql_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'FUNCTION executeBroadcast (',
'    p_process IN apex_plugin.t_process,',
'    p_plugin  IN apex_plugin.t_plugin',
') RETURN apex_plugin.t_process_exec_result',
'IS',
'  l_result       apex_plugin.t_process_exec_result;',
'',
'  l_api_key      VARCHAR2(4000);',
'  l_base_url     VARCHAR2(4000);',
'  l_channel      VARCHAR2(4000);',
'  l_event_name   VARCHAR2(4000);',
'  l_item_name    VARCHAR2(255);',
'  l_item_value   VARCHAR2(32767);',
'  l_on_error     VARCHAR2(10);',
'',
'  l_payload_json CLOB;',
'BEGIN',
'  -- Read attributes',
'  l_api_key    := p_process.attribute_01;',
'  l_base_url   := apex_plugin_util.replace_substitutions(p_process.attribute_02);',
'  l_channel    := apex_plugin_util.replace_substitutions(p_process.attribute_03);',
'  l_event_name := apex_plugin_util.replace_substitutions(p_process.attribute_04);',
'  l_item_name  := p_process.attribute_05;',
'  l_on_error   := NVL(p_process.attribute_06, ''RAISE'');',
'',
'  -- Build payload from the page item (if provided)',
'  IF l_item_name IS NOT NULL THEN',
'    l_item_value := apex_util.get_session_state(l_item_name);',
'',
'    l_payload_json :=',
'      json_object(',
'        ''itemName'' VALUE l_item_name,',
'        ''value''    VALUE l_item_value',
'      );',
'  ELSE',
'    l_payload_json := ''{}'';',
'  END IF;',
'',
'  BEGIN',
'    websocket_api.broadcast_item(',
'      p_api_key    => l_api_key,',
'      p_base_url   => l_base_url,',
'      p_channel    => l_channel,',
'      p_event_name => l_event_name,',
'      p_payload    => l_payload_json',
'    );',
'',
'  EXCEPTION',
'    WHEN OTHERS THEN',
'      CASE l_on_error',
'        WHEN ''LOG'' THEN',
'          apex_debug.error(',
'            ''RTM Broadcast (Process) error: %s'',',
'            SQLERRM',
'          );',
'          -- (Optional) also log into RTM_LOG',
'          rtm_log_api.log_event(',
'            p_source       => ''APEX-PLUGIN'',',
'            p_channel      => l_channel,',
'            p_event_name   => l_event_name,',
'            p_payload_json => l_payload_json,',
'            p_error        => sqlerrm',
'          );',
'        WHEN ''IGNORE'' THEN',
'          NULL;',
'        ELSE',
'          RAISE;',
'      END CASE;',
'  END;',
'',
'  RETURN l_result;',
'END executeBroadcast;',
''))
,p_api_version=>1
,p_execution_function=>'executeBroadcast'
,p_substitute_attributes=>true
,p_version_scn=>40224714301315
,p_subscribe_plugin_settings=>true
,p_version_identifier=>'1.0'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(43919695204024070)
,p_plugin_id=>wwv_flow_imp.id(43881050044296010)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>1
,p_display_sequence=>10
,p_prompt=>'API Key'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_is_translatable=>false
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(43919928036025677)
,p_plugin_id=>wwv_flow_imp.id(43881050044296010)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>2
,p_display_sequence=>20
,p_prompt=>'Base URL'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_is_translatable=>false
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(43920254004027979)
,p_plugin_id=>wwv_flow_imp.id(43881050044296010)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>3
,p_display_sequence=>30
,p_prompt=>'Channel'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_is_translatable=>false
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(43920540686031146)
,p_plugin_id=>wwv_flow_imp.id(43881050044296010)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>4
,p_display_sequence=>40
,p_prompt=>'Event Name'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_is_translatable=>false
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(43920826660035269)
,p_plugin_id=>wwv_flow_imp.id(43881050044296010)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>5
,p_display_sequence=>50
,p_prompt=>'Source Item (Payload)'
,p_attribute_type=>'PAGE ITEM'
,p_is_required=>false
,p_is_translatable=>false
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(43921168097036013)
,p_plugin_id=>wwv_flow_imp.id(43881050044296010)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>6
,p_display_sequence=>60
,p_prompt=>'On Error'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_is_translatable=>false
);
end;
/
prompt --application/end_environment
begin
wwv_flow_imp.import_end(p_auto_install_sup_obj => nvl(wwv_flow_application_install.get_auto_install_sup_obj, false)
);
commit;
end;
/
set verify on feedback on define on
prompt  ...done
