function renderListener( daContext ) {
    // APEX DA plug-ins usually pass the dynamic action context in,
    // but if not, "this" will be the context.
    var ctx = daContext || this || {};

    // Plug-in attributes (keep same mapping you already use)
    var baseUrl       = ctx.attribute01 || 'wss://rtm.oracleapex.cloud';
    var channel       = ctx.attribute02 || 'test';
    var eventName     = ctx.attribute03 || 'ping';
    var apexEventName = ctx.attribute04 || 'rtm-message';

    // Reconnect delay (ms) – hard-coded, or add another attribute if you like
    var RECONNECT_DELAY = 3000;

    // If we already have an open socket for this context, reuse it
    if (ctx._rtmSocket && ctx._rtmSocket.readyState === WebSocket.OPEN) {
        console.log('RTM listener: socket already open, reusing:', baseUrl);
        return;
    }

    // Handle one decoded message object
    function handleMessage(msg) {
        // Filter by channel / event if present
        if (msg.channel && msg.channel !== channel) {
            return;
        }
        if (msg.eventName && msg.eventName !== eventName) {
            return;
        }

        console.log('RTM listener received message:', msg);

        // If payload is { itemName: "P10_MESSAGE", value: "Hello" }
        // then update that APEX item automatically
        if (msg.payload &&
    msg.payload.itemName &&
    typeof msg.payload.value !== 'undefined' &&
    msg.payload.value !== null &&
    msg.payload.value !== '' &&      // 👈 ignore empty string
    window.apex && apex.item)
{
    try {
        apex.item(msg.payload.itemName).setValue(msg.payload.value);
        console.log(
          'RTM listener: set',
          msg.payload.itemName,
          'to',
          msg.payload.value
        );
    } catch (e) {
        console.warn(
          'RTM listener: could not set APEX item',
          msg.payload.itemName,
          e
        );
    }
}


        // Fire our APEX custom event so other Dynamic Actions can react
        if (window.apex && apex.event && apex.event.trigger) {
            apex.event.trigger(document, apexEventName, msg);
        }
    }

    // Connect function with auto-reconnect logic
    function connect() {
        console.log(
          'RTM listener connecting to',
          baseUrl,
          'channel=',
          channel,
          'event=',
          eventName
        );

        var socket = new WebSocket(baseUrl);
        ctx._rtmSocket = socket;  // keep reference on the DA context

        socket.onopen = function () {
            console.log('RTM listener connected:', baseUrl);
        };

        socket.onmessage = function (evt) {
            var msg;
            try {
                msg = JSON.parse(evt.data);
            } catch (e) {
                console.error('RTM listener: invalid JSON', e, evt.data);
                return;
            }
            handleMessage(msg);
        };

        socket.onclose = function (evt) {
            console.log('RTM listener closed:', evt.code, evt.reason || '');

            // 1000 = normal closure, 1001 = going away (page unload)
            // Only auto-reconnect for "unexpected" closures
            if (evt.code !== 1000 && evt.code !== 1001) {
                console.log(
                  'RTM listener: reconnecting in ' + RECONNECT_DELAY + ' ms...'
                );
                setTimeout(connect, RECONNECT_DELAY);
            }
        };

        socket.onerror = function (err) {
            console.error('RTM listener error:', err);
        };
    }

    // Initial connect
    connect();
}
