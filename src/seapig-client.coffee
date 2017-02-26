class @SeapigClient


        constructor: (uri, options = {})->
                @uri = uri
                @options = options
                @slave_objects = {}
                @master_objects = {}
                @connected = false
                @socket = undefined
                @error = undefined
                @connect()


        connect: ()->

                @reconnect_on_close = true
                return @socket.close() if @socket?

                try
                        @socket = new WebSocket(@uri)
                catch error
                        @error =  { while: "connecting", error: error }
                        @onstatuschange_proc(@) if @onstatuschange_proc?
                        return false

                @socket.onopen = ()=>
                        console.log('Connected to seapig server') if @options.debug
                        @connected = true
                        @error = null
                        @onstatuschange_proc(@) if @onstatuschange_proc?
                        @socket.send(JSON.stringify(action: 'client-options-set', options: @options))
                        for id, object of @slave_objects
                                @socket.send(JSON.stringify(action: 'object-consumer-register', pattern: id, "version-known": object.version))
                                object.validate()
                        for id, object of @master_objects
                                @socket.send(JSON.stringify(action: 'object-producer-register', pattern: id, "version-known": object.version))

                @socket.onclose = ()=>
                        console.log('Seapig connection closed') if @options.debug
                        @connected = false
                        @socket = undefined
                        object.invalidate() for id, object of @slave_objects
                        @onstatuschange_proc(@) if @onstatuschange_proc?
                        @reconnection_timer = setTimeout((=> @reconnection_timer = undefined; @connect()), 2000) if @reconnect_on_close

                @socket.onerror = (error)=>
                        console.log('Seapig socket error', error) if @options.debug
                        @error = { while: "connected", error: error }

                @socket.onmessage = (event) =>
                        message = JSON.parse(event.data)
                        switch message.action
                                when 'object-update'
                                        for id, object of @slave_objects
                                                object.patch(message) if object.matches(message['id'])
                                when 'object-destroy'
                                        for id, object of @slave_objects
                                                object.destroy(message['id']) if object.matches(message['id'])
                                        for id, object of @master_objects
                                                object.destroy(message['id']) if object.matches(message['id'])
                                when 'object-produce'
                                        handler = _.find(_.values(@master_objects), (object)-> object.matches(message['id']))
                                        console.error('Seapig server submitted invalid "produce" request', message) if (not handler) and @options.debug
                                        handler.produce(message['id'], message['version-inferred']) if handler
                                else
                                        console.error('Seapig server submitted an unsupported message', message)  if @options.debug
                        null


        disconnect: ()->
                @reconnect_on_close = false
                clearTimeout(@reconnection_timer) if @reconnection_timer?
                @socket.close() if @socket?



        onstatuschange: (proc)->
                @onstatuschange_proc = proc
                @


        slave: (id, options={})->
                throw "Both or none of 'object' and 'version' are needed" if (options["object"] and not options['version']) or (not options["object"] and options['version'])
                @slave_objects[id] = if id.indexOf('*') >= 0 then new SeapigWildcardSlaveObject(@, id, options) else new SeapigSlaveObject(@, id, options)
                @socket.send(JSON.stringify(action: 'object-consumer-register', pattern: id, "version-known": @slave_objects[id].version)) if @connected
                @slave_objects[id]


        master: (id, options={})->
                @master_objects[id] = if id.indexOf('*') >= 0 then new SeapigWildcardMasterObject(@, id, options) else new SeapigMasterObject(@, id, options)
                @socket.send(JSON.stringify(action: 'object-producer-register', pattern: id, "version-known": @master_objects[id].version)) if @connected
                @master_objects[id]


        unlink: (id)->
                if @slave_objects[id]?
                        delete @slave_objects[id]
                        @socket.send(JSON.stringify(action: 'object-consumer-unregister', pattern: id)) if @connected
                if @master_objects[id]?
                        delete @master_objects[id]
                        @socket.send(JSON.stringify(action: 'object-producer-unregister', pattern: id)) if @connected



class SeapigObject


        constructor: (client, id, options)->
                @client = client
                @id = id
                @destroyed = false
                @object = {}
                @initialized = !!options.object
                _.extend(@object, options.object) if options.object?


        destroy: (id)->
                @destroyed = true
                @onstatuschange_proc(@) if @onstatuschange_proc?
                @ondestroy_proc(@) if @ondestroy_proc?


        matches: (id)->
                id.match(new RegExp(@id.replace(/[^A-Za-z0-9*]/g,"\\$&").replace("*",".*?")))


        sanitized: ()->
                JSON.parse(JSON.stringify(@object))


        ondestroy: (proc)->
                @ondestroy_proc = proc
                @


        onstatuschange: (proc)->
                @onstatuschange_proc = proc
                @


        unlink: () ->
                @client.unlink(@id)



class SeapigSlaveObject extends SeapigObject


        constructor: (client, id, options)->
                super(client, id, options)
                @version = (options.version or 0)
                @valid = false
                @received_at = null


        onchange: (proc)->
                @onchange_proc = proc
                @

# ----- for SeapigClient

        patch: (message)->
                @received_at = new Date()
                old_object = JSON.stringify(@object)
                if  (not message['version-old']) or (message['version-old'] == 0) or message.value?
                        delete @object[key] for key, value of @object
                else if not _.isEqual(@version, message['version-old'])
                        console.error("Seapig lost some updates, this shouldn't ever happen. object:",@id," version:", @version, " message:", message)
                if message.value?
                        for key,value of message.value
                                @object[key] = value
                else
                        jsonpatch.apply(@object, message.patch)
                @version = message['version-new']
                @valid = true
                @initialized = true
                @onstatuschange_proc(@) if @onstatuschange_proc?
                @onchange_proc(@) if @onchange_proc? and old_object != JSON.stringify(@object)

        validate: ()->
                @valid = @initialized
                @onstatuschange_proc(@) if @onstatuschange_proc?


        invalidate: ()->
                @valid = false
                @onstatuschange_proc(@) if @onstatuschange_proc?



class SeapigMasterObject extends SeapigObject


        constructor: (client, id, options)->
                super(client, id, options)
                @version = (options.version or [(new Date()).getTime(), 0])
                @shadow = @sanitized()
                @stall = false


        onproduce: (proc)->
                @onproduce_proc = proc
                @


        set: (options={})->
                @version = options.version if options.version?
                if options.object?
                        @stall = false
                        delete @object[key] for key, value of @object
                        _.extend(@object, options.object)
                else if options.object == false or options.stall
                        @stall = true
                @shadow = @sanitized()
                @initialized = true
                @upload(0, {}, @version, if @stall then false else @shadow)


        bump: (options={})->
                version_old = @version
                data_old = @shadow
                @version = (options.version or [version_old[0], version_old[1]+1])
                @shadow = @sanitized()
                @initialized = true
                @upload(version_old, data_old, @version, if @stall then false else @shadow)

# ----- for SeapigClient

        produce: (id, version_inferred)->
                if @onproduce_proc?
                        @onproduce_proc(@, version_inferred)
                else
                        throw "Master object #{id} has to either be initialized at all times or have an onproduce callback" if not @initialized
                        @upload(0, {}, @version, @shadow)

        upload: (version_old, data_old, version_new, data_new)->
                if @client.connected
                        if version_old == 0 or data_new == false
                                @client.socket.send JSON.stringify(id: @id, action: 'object-patch', "version-new": version_new, value: data_new)
                        else
                                diff = jsonpatch.compare(data_old, data_new)
                                if JSON.stringify(diff).length < JSON.stringify(data_new).length #can we afford this?
                                        @client.socket.send JSON.stringify(id: @id, action: 'object-patch', 'version-old': version_old, 'version-new': version_new, patch: diff)
                                else
                                        @client.socket.send JSON.stringify(id: @id, action: 'object-patch', 'version-new': version_new, value: data_new)
                @


class SeapigWildcardSlaveObject extends SeapigSlaveObject

        constructor: (client, id, options)->
                super(client, id, options)
                @children = {}


        patch: (message)->
                if not @children[message['id']]?
                        @children[message['id']] = new SeapigSlaveObject(@client, message['id'], {}).onchange(@onchange_proc).onstatuschange(@onstatuschange_proc)
                        @object[message['id']] = @children[message['id']].object
                @children[message['id']].patch(message)


        destroy: (id)->
                return if not (destroyed = @children[id])?
                delete @object[id]
                delete @children[id]
                destroyed.destroy(id)
