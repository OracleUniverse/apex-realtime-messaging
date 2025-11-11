function executeClientBroadcast( daContext ) {
    var ctx = daContext || this;
    if ( !ctx ) {
        console.error("RTM DA Broadcast: no context.", ctx);
        return;
    }

    var action = ctx.action || ctx;

    // Comes from l_result.ajax_identifier above
    var ajaxId = action.ajaxIdentifier || ctx.ajaxIdentifier;
    if ( !ajaxId ) {
        console.error("RTM DA Broadcast: missing ajaxIdentifier / context.", ctx);
        return;
    }

    // These are from l_result.attribute_XX above
    var channel   = action.attribute03;  // Channel
    var eventName = action.attribute04;  // Event Name
    var itemName  = action.attribute05;  // Payload Item (APEX item name)

    var itemValue = null;
    if ( itemName ) {
        itemValue = apex.item( itemName ).getValue();
    }

    var payload = {
        itemName : itemName,
        value    : itemValue
    };

    console.log("RTM DA Broadcast: calling AJAX", {
        ajaxId    : ajaxId,
        channel   : channel,
        eventName : eventName,
        payload   : payload
    });

    apex.server.plugin(
        ajaxId,
        {
            x01 : JSON.stringify(payload)
        },
        {
            dataType : "json",
            success  : function (pData) {
                console.log("RTM DA Broadcast success:", pData);
            },
            error    : function (jqXHR, textStatus, errorThrown) {
                console.error(
                    "RTM DA Broadcast AJAX error:",
                    textStatus,
                    errorThrown,
                    jqXHR && jqXHR.responseText
                );
            }
        }
    );
}
