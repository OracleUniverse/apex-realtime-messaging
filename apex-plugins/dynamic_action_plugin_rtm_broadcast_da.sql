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
--     PLUGIN: 43971088010149102
--   Manifest End
--   Version:         24.2.10
--   Instance ID:     7727405682615679
--

begin
  -- replace components
  wwv_flow_imp.g_mode := 'REPLACE';
end;
/
prompt --application/shared_components/plugins/dynamic_action/rtm_broadcast_da
begin
wwv_flow_imp_shared.create_plugin(
 p_id=>wwv_flow_imp.id(43971088010149102)
,p_plugin_type=>'DYNAMIC ACTION'
,p_name=>'RTM_BROADCAST_DA'
,p_display_name=>unistr('Real-Time Messaging \2013 Broadcast (DA)')
,p_category=>'EXECUTE'
,p_javascript_file_urls=>'#PLUGIN_FILES#broadcast_da.js'
,p_plsql_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'FUNCTION rtm_da_broadcast_render (',
'    p_dynamic_action IN apex_plugin.t_dynamic_action,',
'    p_plugin         IN apex_plugin.t_plugin',
') RETURN apex_plugin.t_dynamic_action_render_result',
'IS',
'    l_result apex_plugin.t_dynamic_action_render_result;',
'BEGIN',
'    -- JS entry point (broadcast_da.js)',
'    l_result.javascript_function := ''executeClientBroadcast'';',
'',
'    -- Expose AJAX identifier',
'    l_result.ajax_identifier := apex_plugin.get_ajax_identifier;',
'',

,p_api_version=>1
,p_render_function=>'RTM_DA_BROADCAST_RENDER'
,p_ajax_function=>'RTM_DA_BROADCAST_AJAX'
,p_standard_attributes=>'ITEM:STOP_EXECUTION_ON_ERROR:WAIT_FOR_RESULT'
,p_substitute_attributes=>true
,p_version_scn=>40224728351521
,p_subscribe_plugin_settings=>true
,p_version_identifier=>'1.0'
,p_files_version=>58
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(43974308870185675)
,p_plugin_id=>wwv_flow_imp.id(43971088010149102)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>1
,p_display_sequence=>10
,p_prompt=>'API Key'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_default_value=>'0301198103011981'
,p_is_translatable=>false
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(43974605214188536)
,p_plugin_id=>wwv_flow_imp.id(43971088010149102)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>2
,p_display_sequence=>20
,p_prompt=>'Base URL'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_default_value=>'https://rtm.oracleapex.cloud'
,p_is_translatable=>false
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(43974929903189873)
,p_plugin_id=>wwv_flow_imp.id(43971088010149102)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>3
,p_display_sequence=>30
,p_prompt=>'Channel'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_default_value=>'test'
,p_is_translatable=>false
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(43975276205191574)
,p_plugin_id=>wwv_flow_imp.id(43971088010149102)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>4
,p_display_sequence=>40
,p_prompt=>'Event Name'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_default_value=>'ping'
,p_is_translatable=>false
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(43975530585193755)
,p_plugin_id=>wwv_flow_imp.id(43971088010149102)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>5
,p_display_sequence=>50
,p_prompt=>'Payload Item'
,p_attribute_type=>'PAGE ITEM'
,p_is_required=>false
,p_is_translatable=>false
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(43975890774197399)
,p_plugin_id=>wwv_flow_imp.id(43971088010149102)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>6
,p_display_sequence=>60
,p_prompt=>'On Error'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>false
,p_default_value=>'LOG'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(43976161802198247)
,p_plugin_attribute_id=>wwv_flow_imp.id(43975890774197399)
,p_display_sequence=>10
,p_display_value=>'RAISE'
,p_return_value=>'RAISE'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(43976552120199395)
,p_plugin_attribute_id=>wwv_flow_imp.id(43975890774197399)
,p_display_sequence=>20
,p_display_value=>'LOG'
,p_return_value=>'LOG'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(43976903098201072)
,p_plugin_attribute_id=>wwv_flow_imp.id(43975890774197399)
,p_display_sequence=>30
,p_display_value=>'IGNORE'
,p_return_value=>'IGNORE'
);
end;
/
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '66756E6374696F6E2065786563757465436C69656E7442726F61646361737428206461436F6E746578742029207B0D0A2020202076617220637478203D206461436F6E74657874207C7C20746869733B0D0A202020206966202820216374782029207B0D';
wwv_flow_imp.g_varchar2_table(2) := '0A2020202020202020636F6E736F6C652E6572726F72282252544D2044412042726F6164636173743A206E6F20636F6E746578742E222C20637478293B0D0A202020202020202072657475726E3B0D0A202020207D0D0A0D0A2020202076617220616374';
wwv_flow_imp.g_varchar2_table(3) := '696F6E203D206374782E616374696F6E207C7C206374783B0D0A0D0A202020202F2F20436F6D65732066726F6D206C5F726573756C742E616A61785F6964656E7469666965722061626F76650D0A2020202076617220616A61784964203D20616374696F';
wwv_flow_imp.g_varchar2_table(4) := '6E2E616A61784964656E746966696572207C7C206374782E616A61784964656E7469666965723B0D0A20202020696620282021616A617849642029207B0D0A2020202020202020636F6E736F6C652E6572726F72282252544D2044412042726F61646361';
wwv_flow_imp.g_varchar2_table(5) := '73743A206D697373696E6720616A61784964656E746966696572202F20636F6E746578742E222C20637478293B0D0A202020202020202072657475726E3B0D0A202020207D0D0A0D0A202020202F2F205468657365206172652066726F6D206C5F726573';
wwv_flow_imp.g_varchar2_table(6) := '756C742E6174747269627574655F58582061626F76650D0A20202020766172206368616E6E656C2020203D20616374696F6E2E61747472696275746530333B20202F2F204368616E6E656C0D0A20202020766172206576656E744E616D65203D20616374';
wwv_flow_imp.g_varchar2_table(7) := '696F6E2E61747472696275746530343B20202F2F204576656E74204E616D650D0A20202020766172206974656D4E616D6520203D20616374696F6E2E61747472696275746530353B20202F2F205061796C6F6164204974656D202841504558206974656D';
wwv_flow_imp.g_varchar2_table(8) := '206E616D65290D0A0D0A20202020766172206974656D56616C7565203D206E756C6C3B0D0A2020202069662028206974656D4E616D652029207B0D0A20202020202020206974656D56616C7565203D20617065782E6974656D28206974656D4E616D6520';
wwv_flow_imp.g_varchar2_table(9) := '292E67657456616C756528293B0D0A202020207D0D0A0D0A20202020766172207061796C6F6164203D207B0D0A20202020202020206974656D4E616D65203A206974656D4E616D652C0D0A202020202020202076616C7565202020203A206974656D5661';
wwv_flow_imp.g_varchar2_table(10) := '6C75650D0A202020207D3B0D0A0D0A20202020636F6E736F6C652E6C6F67282252544D2044412042726F6164636173743A2063616C6C696E6720414A4158222C207B0D0A2020202020202020616A61784964202020203A20616A617849642C0D0A202020';
wwv_flow_imp.g_varchar2_table(11) := '20202020206368616E6E656C2020203A206368616E6E656C2C0D0A20202020202020206576656E744E616D65203A206576656E744E616D652C0D0A20202020202020207061796C6F61642020203A207061796C6F61640D0A202020207D293B0D0A0D0A20';
wwv_flow_imp.g_varchar2_table(12) := '202020617065782E7365727665722E706C7567696E280D0A2020202020202020616A617849642C0D0A20202020202020207B0D0A202020202020202020202020783031203A204A534F4E2E737472696E67696679287061796C6F6164290D0A2020202020';
wwv_flow_imp.g_varchar2_table(13) := '2020207D2C0D0A20202020202020207B0D0A2020202020202020202020206461746154797065203A20226A736F6E222C0D0A2020202020202020202020207375636365737320203A2066756E6374696F6E2028704461746129207B0D0A20202020202020';
wwv_flow_imp.g_varchar2_table(14) := '202020202020202020636F6E736F6C652E6C6F67282252544D2044412042726F61646361737420737563636573733A222C207044617461293B0D0A2020202020202020202020207D2C0D0A2020202020202020202020206572726F72202020203A206675';
wwv_flow_imp.g_varchar2_table(15) := '6E6374696F6E20286A715848522C20746578745374617475732C206572726F725468726F776E29207B0D0A20202020202020202020202020202020636F6E736F6C652E6572726F72280D0A20202020202020202020202020202020202020202252544D20';
wwv_flow_imp.g_varchar2_table(16) := '44412042726F61646361737420414A4158206572726F723A222C0D0A2020202020202020202020202020202020202020746578745374617475732C0D0A20202020202020202020202020202020202020206572726F725468726F776E2C0D0A2020202020';
wwv_flow_imp.g_varchar2_table(17) := '2020202020202020202020202020206A71584852202626206A715848522E726573706F6E7365546578740D0A20202020202020202020202020202020293B0D0A2020202020202020202020207D0D0A20202020202020207D0D0A20202020293B0D0A7D0D';
wwv_flow_imp.g_varchar2_table(18) := '0A';
end;
/
begin
wwv_flow_imp_shared.create_plugin_file(
 p_id=>wwv_flow_imp.id(43971662916171924)
,p_plugin_id=>wwv_flow_imp.id(43971088010149102)
,p_file_name=>'broadcast_da.js'
,p_mime_type=>'text/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
);
end;
/
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '66756E6374696F6E2065786563757465436C69656E7442726F6164636173742865297B76617220613D657C7C746869733B69662861297B76617220743D612E616374696F6E7C7C612C723D742E616A61784964656E7469666965727C7C612E616A617849';
wwv_flow_imp.g_varchar2_table(2) := '64656E7469666965723B69662872297B766172206F3D742E61747472696275746530332C6E3D742E61747472696275746530342C733D742E61747472696275746530352C693D6E756C6C3B73262628693D617065782E6974656D2873292E67657456616C';
wwv_flow_imp.g_varchar2_table(3) := '75652829293B76617220633D7B6974656D4E616D653A732C76616C75653A697D3B636F6E736F6C652E6C6F67282252544D2044412042726F6164636173743A2063616C6C696E6720414A4158222C7B616A617849643A722C6368616E6E656C3A6F2C6576';
wwv_flow_imp.g_varchar2_table(4) := '656E744E616D653A6E2C7061796C6F61643A637D292C617065782E7365727665722E706C7567696E28722C7B7830313A4A534F4E2E737472696E676966792863297D2C7B64617461547970653A226A736F6E222C737563636573733A66756E6374696F6E';
wwv_flow_imp.g_varchar2_table(5) := '2865297B636F6E736F6C652E6C6F67282252544D2044412042726F61646361737420737563636573733A222C65297D2C6572726F723A66756E6374696F6E28652C612C74297B636F6E736F6C652E6572726F72282252544D2044412042726F6164636173';
wwv_flow_imp.g_varchar2_table(6) := '7420414A4158206572726F723A222C612C742C652626652E726573706F6E736554657874297D7D297D656C736520636F6E736F6C652E6572726F72282252544D2044412042726F6164636173743A206D697373696E6720616A61784964656E7469666965';
wwv_flow_imp.g_varchar2_table(7) := '72202F20636F6E746578742E222C61297D656C736520636F6E736F6C652E6572726F72282252544D2044412042726F6164636173743A206E6F20636F6E746578742E222C61297D';
end;
/
begin
wwv_flow_imp_shared.create_plugin_file(
 p_id=>wwv_flow_imp.id(44019521353970826)
,p_plugin_id=>wwv_flow_imp.id(43971088010149102)
,p_file_name=>'broadcast_da.min.js'
,p_mime_type=>'text/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
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
