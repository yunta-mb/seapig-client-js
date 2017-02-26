
ObjectVersion =
        view: (vnode)->
                if Array.isArray(vnode.attrs.version) or !vnode.attrs.version or typeof vnode.attrs.version == "number"
                        m '', JSON.stringify(vnode.attrs.version, null, 2)
                else
                        for key, value of vnode.attrs.version
                                m '', key+': '+JSON.stringify(value, null, 2)

Header =
        view: (vnode)->
                m 'nav.navbar.navbar-toggleable-md.navbar-light.bg-primary.navbar-inverse',
                        m 'button.navbar-toggler.navbar-toggler-right', type: "button", 'data-toggle': "collapse", 'data-target': "#navbar-menu", 'aria-controls': "navbar-menu", 'aria-expanded': "false", 'aria-label': "Toggle navigation",
                                m 'span.navbar-toggler-icon'
                        m 'a.navbar-brand', href: "https://github.com/yunta-mb/seapig-server", 'SeaPig'
                        if seapig_client?
                                [
                                        m '#navbar-menu.collapse.navbar-collapse',
                                                m 'ul.navbar-nav.mr-auto',
                                                        m 'li.nav-item'+(vnode.attrs.route == "statistics" and ".active"),
                                                                m 'a.nav-link', href: "/"+encodeURIComponent(seapig_client.uri)+"/statistics", oncreate: m.route.link, "Statistics"
                                                        m 'li.nav-item'+(vnode.attrs.route == "connections" and ".active"),
                                                                m 'a.nav-link', href: "/"+encodeURIComponent(seapig_client.uri)+"/connections", oncreate: m.route.link, "Connections"
                                                        m 'li.nav-item'+(vnode.attrs.route == "objects" and ".active"),
                                                                m 'a.nav-link', href: "/"+encodeURIComponent(seapig_client.uri)+"/objects", oncreate: m.route.link, "Objects"
                                                        m 'li.nav-item'+(vnode.attrs.route == "observe" and ".active"),
                                                                m 'a.nav-link', href: "/"+encodeURIComponent(seapig_client.uri)+"/observe"+(seapig_object? and "/"+encodeURIComponent(seapig_object.id) or ""), oncreate: m.route.link, "Observe"+(seapig_object? and ":"+seapig_object.id or "")
                                        m 'span.text-white', "Server: "+seapig_client.uri
                                        m 'button.btn.btn-outline', onclick: (()->m.route.set("/")), "Disconnect"
                                ]

Footer =
        view: (vnode)->
                m '.col', m.trust '&nbsp;'

Layout =
        view: (vnode)->
                _.union(
                        [ m Header ]
                        [
                                if seapig_client? and seapig_client.connected
                                        vnode.attrs.child()
                                else
                                        m '.container-flex.mx-auto',
                                                m '.card.mx-auto.my-4', style: { width: '600px' },
                                                        m '.card-block',
                                                                if seapig_client.error?
                                                                        if seapig_client.error.while == "connecting"
                                                                                [
                                                                                        m '', "Couldn't connect to server:"
                                                                                        m '', seapig_client.error.error.toString()
                                                                                ]
                                                                        else
                                                                                m '', 'Connection failed. Reconnecting...'
                                                                else
                                                                        m '', "Connecting to server..."
                        ]
                        [ m Footer ])


Connection =
        view: (vnode)->
                [
                        m Header
                        m '.container-flex.mx-auto',
                                m '.card.mx-auto.my-4', style: { width: '600px' },
                                        m '.card-block',
                                                m 'form.m-2.text-center',
                                                        m 'input#server-url.mb-2.mx-auto', type: "text", placeholder: 'SeaPig server URL', style: { width: '500px' }
                                                        m 'button.btn.btn-outline.btn-primary.mx-auto', type: "submit", onclick: (()->m.route.set("/:server/statistics", server: encodeURIComponent($("#server-url").val()))), "Connect"
                        m Footer
                ]



Statistics =
        view: (vnode)->
                if seapig_statistics.valid
                        m '.container-flex', style: { width: '95%' }, class: 'mx-auto',
                                m StatisticsRow, measure: 'connections-count', chart: BarChart, name: "Number&nbsp;of connections", aggregate: "last"
                                m StatisticsRow, measure: 'message-outgoing-count', chart: BarChart, name: "Number&nbsp;of outgoing&nbsp;messages", aggregate: "count"
                                m StatisticsRow, measure: 'message-outgoing-size', chart: BarChart, name: "Total&nbsp;size&nbsp;of outgoing&nbsp;messages&nbsp;[B]", aggregate: "sum"
                                m StatisticsRow, measure: 'message-outgoing-size', chart: SpectrumChart, name: "Size&nbsp;of outgoing&nbsp;messages&nbsp;[B]", aggregate: "histogram"
                                m StatisticsRow, measure: 'message-incoming-count', chart: BarChart, name: "Number&nbsp;of incoming&nbsp;messages", aggregate: "count"
                                m StatisticsRow, measure: 'message-incoming-size', chart: BarChart, name: "Total&nbsp;size&nbsp;of incoming&nbsp;messages&nbsp;[B]", aggregate: "sum"
                                m StatisticsRow, measure: 'message-incoming-size', chart: SpectrumChart, name: "Size&nbsp;of incoming&nbsp;messages&nbsp;[B]", aggregate: "histogram"
                                m StatisticsRow, measure: 'message-incoming-processing-time', chart: SpectrumChart, name: "&nbsp Processing&nbsp;time&nbsp;[μs]", aggregate: "histogram"



Connections =
        view: (vnode)->
                if seapig_connections.valid
                        m '.container-flex.mt-3', style: { width: '95%' }, class: 'mx-auto',
                                m '.row.justify-content-md-center',
                                        m '.col',
                                                m 'table.table.table-sm',
                                                        m 'thead',
                                                                m 'tr',
                                                                        m 'th', "ConnID"
                                                                        m 'th', "Client ID"
                                                                        m 'th', "Consumes"
                                                                        m 'th', "Produces"
                                                                        m 'th', "Now producing"
                                                        m 'tbody',
                                                                for [connection_id, connection] in _.sortBy(_.pairs(seapig_connections.object), (c)->c[0])
                                                                        for client_id, client of connection.clients
                                                                                m 'tr',
                                                                                        m 'td', connection_id
                                                                                        m 'th', client_id
                                                                                        m 'td',
                                                                                                m '', object for object in _.sortBy(client.consumes)
                                                                                        m 'td',
                                                                                                m '', object for object in _.sortBy(client.produces)
                                                                                        m 'td', if client.producing
                                                                                                [
                                                                                                        m '', client.producing[0]
                                                                                                        m '', JSON.stringify(client.producing[1])
                                                                                                ]


Objects =
        view: (vnode)->
                if seapig_connections.valid
                        m '.container-flex.mt-3', style: { width: '95%' }, class: 'mx-auto',
                                m '.row.justify-content-md-center',
                                        m '.col',
                                                m 'table.table.table-sm',
                                                        m 'thead',
                                                                m 'tr',
                                                                        m 'th', "Object ID"
                                                                        m 'th', style: { width: "100px" }, "State"
                                                                        m 'th', "Highest Version known"
                                                                        m 'th', "Highest Version inferred"
                                                                        m 'th', "Consumers"
                                                                        m 'th', "Producers"
                                                        m 'tbody',
                                                                for [object_id, object] in _.sortBy(_.pairs(seapig_objects.object))
                                                                        m 'tr',
                                                                                m 'th',
                                                                                        m 'a', href: '/'+encodeURIComponent(seapig_client.uri)+'/observe/'+encodeURIComponent(object_id), oncreate: m.route.link, object_id
                                                                                m 'td', if object.state.current
                                                                                                "current"
                                                                                        else if object.state.producing
                                                                                                "producing"
                                                                                        else if object.state.enqueued
                                                                                                "enqueued"
                                                                                        else
                                                                                                "waiting for dependencies"
                                                                                m 'td',
                                                                                        m ObjectVersion, version: object.version_highest_known
                                                                                m 'td',
                                                                                        m ObjectVersion, version: object.version_highest_inferred
                                                                                m 'td',
                                                                                        m '', consumer for consumer in _.sortBy(object.consumers)
                                                                                m 'td',
                                                                                        m '', producer for producer in _.sortBy(object.producers)


Observe =

        view: (vnode)->
                m '.container-flex.mt-3', style: { width: '95%' }, class: 'mx-auto',
                        m '.row.justify-content-md-center',
                                m '.col',
                                        m '.card',
                                                m '.card-header.text-center',
                                                        m 'form.form-inline',
                                                                m '.input-group.mr-sm-2',
                                                                        m '.input-group-addon', "Seapig Object ID"
                                                                        m 'input#object-id.form-control', disabled: (seapig_object?), type: "text", style: { width: '500px' }
                                                                m 'button.btn.btn-primary.mr-sm-2', disabled: (seapig_object?), type: "submit", onclick: (=> m.route.set("/"+encodeURIComponent(seapig_client.uri)+"/observe/:pattern", pattern: encodeURIComponent($("#object-id").val())); false), "Subscribe"
                                                                m 'button.btn.btn-primary', disabled: (! seapig_object?), type: "submit", onclick: (=> m.route.set("/"+encodeURIComponent(seapig_client.uri)+"/observe"); false),  "Un-subscribe"
                                                if seapig_object?
                                                        [
                                                                m '.row.ml-0.mr-0', style: { "border-bottom": "1px solid rgba(0,0,0,.125)" },
                                                                        m '.col.col-md-auto.bg-faded.pt-2.pb-1', style: { width: '150px' }, 'Valid'
                                                                        m '.col.pt-2.pb-1', JSON.stringify(seapig_object.valid)
                                                                m '.row.ml-0.pt-0', style: { "border-bottom": "1px solid rgba(0,0,0,.125)" },
                                                                        m '.col.col-md-auto.bg-faded.pt-2.pb-1', style: { width: '150px' }, 'Version'
                                                                        m '.col.pt-2.pb-1',
                                                                                m ObjectVersion, version: seapig_object.version
                                                                m '.row.ml-0.pt-0', style: { "border-bottom": "1px solid rgba(0,0,0,.125)" },
                                                                        m '.col.col-md-auto.bg-faded.pt-2.pb-1', style: { width: '150px' }, 'JSON Size'
                                                                        m '.col.pt-2.pb-1', JSON.stringify(seapig_object.object).length
                                                                m '.row.ml-0.pt-0',
                                                                        m '.col.col-md-auto.bg-faded.pt-2.pb-1', style: { width: '150px' }, 'Object'
                                                                        m '.col.pt-2.pb-1',
                                                                                m 'pre', JSON.stringify(seapig_object.object, null, 8)
                                                        ]

        unsubscribe: ()->
                if seapig_object?
                        seapig_object.unlink()
                        window.seapig_object = null

        subscribe: (id)->
                window.seapig_object = seapig_client.slave(id).onstatuschange (pig)-> m.redraw()


        oncreate: (vnode)->
                @onupdate(vnode)
                $("#object-id").val(seapig_object and seapig_object.id or "")

        onupdate: (vnode)->
                if (vnode.attrs.pattern?)
                        if ((not seapig_object) or (seapig_object.id != vnode.attrs.pattern))
                                @unsubscribe()
                                @subscribe(vnode.attrs.pattern)
                else
                        @unsubscribe()





StatisticsRow =
        view: (vnode)->
                m '.row',
                        m '.col', style: { "max-width": '50px' , 'transform-origin': '0 0 0', 'transform': 'rotate(-90deg) translate(-230px,10px)'}, m.trust vnode.attrs.name
                        m '.col',
                                m vnode.attrs.chart, data: seapig_statistics.object["seconds"], measure: vnode.attrs.measure, aggregate: vnode.attrs.aggregate
                                m Aggregates, data: seapig_statistics.object["seconds"], measure: vnode.attrs.measure
                        m '.col',
                                m vnode.attrs.chart, data: seapig_statistics.object["minutes"], measure: vnode.attrs.measure, aggregate: vnode.attrs.aggregate
                                m Aggregates, data: seapig_statistics.object["minutes"], measure: vnode.attrs.measure
                        m '.col',
                                m vnode.attrs.chart, data: seapig_statistics.object["hours"], measure: vnode.attrs.measure, aggregate: vnode.attrs.aggregate
                                m Aggregates, data: seapig_statistics.object["hours"], measure: vnode.attrs.measure
                        m '.col',
                                m vnode.attrs.chart, data: seapig_statistics.object["days"], measure: vnode.attrs.measure, aggregate: vnode.attrs.aggregate
                                m Aggregates, data: seapig_statistics.object["days"], measure: vnode.attrs.measure


Aggregates =
        view: (vnode)->
                if log = vnode.attrs.data.entities[vnode.attrs.measure]
                        m '',style: { "margin-left": '50px'},
                                if _.find(_.pairs(log.metrics), (metric)->metric[1].show and log[metric[0]] and _.last(log[metric[0]])?)?
                                        [
                                                m 'span', 'Last '+vnode.attrs.data.seconds+'s time slot: '
                                                m 'span', m.trust " last&nbsp;value&nbsp;=&nbsp;"+_.last(log.last) if log.last? and _.last(log.last)?
                                                m 'span', m.trust " count&nbsp;=&nbsp;"+_.last(log.count) if log.count? and _.last(log.count)?
                                                m 'span', m.trust " sum&nbsp;=&nbsp;"+_.last(log.sum) if log.sum? and _.last(log.sum)?
                                                m 'span', m.trust " average&nbsp;=&nbsp;"+_.last(log.average) if log.average? and _.last(log.average)?
                                                m 'span', m.trust " maximum&nbsp;=&nbsp;"+_.last(log.maximum) if log.maximum? and _.last(log.maximum)?
                                        ]


Chart =
        view: (vnode) ->
                m '', style: { position: 'relative', height: '200px', "margin-top": "50px"},
                        m 'canvas', style: { position: 'absolute', 'background-color': 'black' }
                        m 'svg', style: { position: 'absolute', width: '100%', height: '100%' },
                                m 'g.x-axis'
                                m 'g.y-axis'
                        m '.chart-tooltip', style: { position: 'absolute'  }


        oncreate: (vnode)->
                @node = d3.select(vnode.dom)
                #@color = d3.interpolateCubehelixDefault
                #@color = (i)-> d3.interpolateCool(Math.pow(i, 1.0/2.0))
                #@color = (i)-> d3.interpolateInferno(Math.pow(i, 1.0/2.0))
                #@color = (i)-> d3.interpolatePlasma(Math.pow(i, 1.0/2.0))
                @color = (i)-> d3.interpolateViridis(Math.pow(i, 1.0/2.0))
                #@color = (i)-> d3.interpolateCubehelixDefault(Math.pow(i, 1.0/2.0))
                #interpolator = d3.interpolateCubehelixLong(d3.cubehelix(300, 0.5, 0.0), d3.cubehelix(-240, 0.5, 0.8));
                #@color = (i)-> interpolator(Math.pow(i, 1.0/2.0))
                @onbeforeupdate(vnode, null)


        onbeforeupdate: (vnode, old_vnode)->
                timestamp = vnode.attrs.data.timestamp
                return false if timestamp == @last_drawn_at
                @last_drawn_at = timestamp

                data = vnode.attrs.data.entities[vnode.attrs.measure]
                keep = vnode.attrs.data.keep
                seconds = vnode.attrs.data.seconds

                margin_left = 50
                margin_bottom = 20
                chart_height = @node.node().getBoundingClientRect().height
                chart_width = @node.node().getBoundingClientRect().width
                area_height = chart_height - margin_bottom
                area_width = chart_width - margin_left

                @node.select("canvas").attr("height", area_height).attr("width", area_width).style("left", margin_left+"px")

                timestamp_right = timestamp
                timestamp_left = timestamp_right - (keep*seconds)
                x_scale = d3.scaleTime().domain([new Date(timestamp_left-seconds),new Date(timestamp_right)]).range([0,area_width-1])
                xAxis = d3.axisBottom(x_scale)
                @node.select(".x-axis").attr("transform", "translate(" + margin_left + "," + area_height + ")").call(xAxis)

                canvas = @node.select("canvas").node().getContext("2d")
                canvas.clearRect(0,0,area_width,area_height)
                if data[vnode.attrs.aggregate].length > 0
                        canvas.fillStyle = @color(0)
                        canvas.fillRect(x = x_scale(new Date(timestamp-seconds*data[vnode.attrs.aggregate].length)), 0, x_scale(new Date(timestamp))-x, area_height)

                @node.select(".y-axis").attr("transform", "translate(" + (margin_left) + "," + (0) + ")")
                @draw(timestamp, data, keep, seconds, area_width, area_height, x_scale, canvas, vnode.attrs.aggregate) if data[vnode.attrs.aggregate].length > 0

                false


SpectrumChart = _.extend {}, Chart,

        draw: (timestamp, data, keep, seconds, area_width, area_height, x_scale, canvas) ->
                max_bin = _.max(_.map(data.histogram, (column)-> column.length)) + 1
                max_of_bin = (Math.pow(10.0,(bin)*1.0/data.metrics.histogram.multiplier) for bin in [0..max_bin])
                max_count = _.max(_.map(data.histogram, (column)-> _.max(column)))
                max_value = max_of_bin[max_bin]
                max_value = 1 if max_value < 0.1
                y_scale = d3.scaleLog().domain([max_value,1]).range([0,area_height])
                yAxis = d3.axisLeft(y_scale).tickSizeOuter([10]).ticks(3).tickFormat(d3.format("2.0s"))
                @node.select(".y-axis").call(yAxis)

                for column, t in data.histogram
                        x = x_scale(new Date(timestamp-seconds*(data.histogram.length-t)))
                        width = x_scale(new Date(timestamp-seconds*(data.histogram.length-t-1))) - x + 1
                        for i in [0..max_bin]
                                if column[i] > 0
                                        canvas.fillStyle = @color((column[i] or 0)*1.0/max_count)
                                        canvas.fillRect(x, y = y_scale(max_of_bin[i]), width, y_scale(max_of_bin[i-1]) - y + 1)


BarChart = _.extend {}, Chart,

        draw: (timestamp, data, keep, seconds, area_width, area_height, x_scale, canvas, aggregate) ->
                max_count = _.max(data[aggregate])
                y_scale = d3.scaleLinear().domain([max_count,0]).range([0,area_height])
                yAxis = d3.axisLeft(y_scale).tickSizeOuter([10]).tickFormat(d3.format(".2s")).ticks([7])
                @node.select(".y-axis").call(yAxis)

                canvas.fillStyle = @color(0.5)
                for column, t in data[aggregate]
                        canvas.fillRect(
                                x = x_scale(new Date(timestamp-seconds*(data[aggregate].length-t))),
                                y = y_scale(column),
                                x_scale(new Date(timestamp-seconds*(data[aggregate].length-t-1))) - x + 1,
                                y_scale(0) - y - 1)




$(document).ready =>

        connect = (uri)=>
                return if @seapig_client?
                @seapig_client = new SeapigClient(uri, name: 'web-viewer', debug: true).onstatuschange (pig_client)-> m.redraw()
                @seapig_statistics = @seapig_client.slave("SeapigServer::Statistics").onchange (pig_object)-> m.redraw()
                @seapig_connections = @seapig_client.slave("SeapigServer::Connections").onchange (pig_object)-> m.redraw()
                @seapig_objects = @seapig_client.slave("SeapigServer::Objects").onstatuschange (pig_object)-> m.redraw()
                @seapig_object = null


        disconnect = ()=>
                return if not @seapig_client?
                @seapig_client.disconnect()
                @seapig_client = null


        m.route document.body, '/',
                "/": { view: (-> m Connection), oninit: (vnode)-> disconnect() }
                "/:server/statistics": { view: (-> m Layout, child: => m(Statistics)), oninit: (vnode)-> connect(vnode.attrs.server) }
                "/:server/connections": { view: (-> m Layout, child: => m(Connections)), oninit: (vnode)-> connect(vnode.attrs.server) }
                "/:server/objects": { view: (-> m Layout, child: => m(Objects)), oninit: (vnode)-> connect(vnode.attrs.server) }
                "/:server/observe": { view: (-> m Layout, child: => m(Observe)), oninit: (vnode)-> connect(vnode.attrs.server) }
                "/:server/observe/:pattern": { view: ((vnode)-> m Layout, child: => m(Observe, pattern: vnode.attrs.pattern)), oninit: (vnode)-> connect(vnode.attrs.server) }
