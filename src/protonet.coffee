Robot        = require('hubot').robot()
Adapter      = require('hubot').adapter()

EventEmitter = require('events').EventEmitter
HTTP         = require('http')
Net          = require('net')

Qs = require('qs')

class Protonet extends Adapter
  send: (user, strings...) ->
    self = @
    strings.forEach (str) =>
      textExtension = ''

      # example protonet text extension
      imageMatch = str.match(/^(http\S+(?:jpe?g|gif|png))(\?.*)?$/i)
      if imageMatch
        textExtension = {
          "image": imageMatch[1], 
          "imageHref": imageMatch[1], 
          "imageTitle": imageMatch[1], 
          "title": imageMatch[1], 
          "type": "Image", 
          "url": imageMatch[1]
        }

      if @node_version > 300
        @bot.write {"operation":"meep.create", "payload":{"channel_id":user.room, "author":self.robot.name, "text_extension":textExtension, "message":str, "user_id":@bot.userId}}
      else
        console.log 'send prior version 300'
        options =
          host     : @node_host
          port     : @node_port
          method   : 'POST'
          auth     : @user + ':' + @password
          path     : '/api/v1/meeps'

        postData = Qs.stringify {"operation":"meep.create","message":str,"channel_id":user.room, "text_extension":textExtension}
        req = HTTP.request options, (response) ->
          response.setEncoding 'utf8'
          response.on 'data',  (chunk) ->
            console.log chunk
        req.write postData
        req.end()
      
  reply: (user, strings...) ->
    strings.forEach (str) =>
      @send user, "@#{user.name} #{str}"

  run: ->
    self = @
    options =
      user              : process.env.HUBOT_PROTONET_USER
      password          : process.env.HUBOT_PROTONET_PASSWORD
      node_host         : process.env.HUBOT_PROTONET_NODE_HOST
      node_port         : process.env.HUBOT_PROTONET_NODE_PORT
      node_version      : process.env.HUBOT_PROTONET_NODE_VERSION

    if options.user? and options.password? and options.node_host? and options.node_port? and options.node_version?
      @user             = options.user
      @password         = options.password
      @node_host        = options.node_host
      @node_port        = options.node_port
      @node_version        = options.node_version
    else
      throw new Error("Not enough parameters provided. I need a user, a password and a node host")

    bot = new ProtonetClient @user, @password, @node_host, @node_port

    bot.on "Ready", ->
      console.log 'ready'

    bot.on "Users", (message)->
      for user in message.users
        self.userForId(user.id, user)

    bot.on "TextMessage", (message)->
      unless self.robot.name == message.author
        # Replace "@mention" with "mention: ", case-insensitively
        name_escape_regexp = new RegExp("[.*+?|()\\[\\]{}\\\\]", "g")
        escaped_name = self.robot.name.replace( name_escape_regexp, "\\$&")

        name_regexp = new RegExp "^@#{escaped_name}", 'i'
        content = message.message.replace(name_regexp, self.robot.name)
        
        user = self.userForId "#{message.node_id}_#{message.user_id}", name: message.author, room: message.channel_id
        
        self.receive new Robot.TextMessage user, content

    bot.on "EnterMessage", (message) ->
      unless self.robot.name == message.author
        self.receive new Robot.EnterMessage message.author

    bot.on "LeaveMessage", (message) ->
      unless self.robot.name == message.author
        self.receive new Robot.LeaveMessage message
        

    # for room in rooms
    #   bot.sockets[room] = bot.createSocket(room)

    bot.connectAndAuthenticate()

    @bot = bot

    self.emit "connected" # this must be downcased! hubot won't load his scripts if he doesn't receive this!

exports.use = (robot) ->
  new Protonet robot

class ProtonetClient extends EventEmitter
  constructor: (user, password, node_host, node_port) ->
    @domain            = node_host
    @port              = node_port
    @user              = user
    @password          = password
    @encoding          = 'utf8'
    @connected         = false
    
  getFromApi: (path, callback) ->
    options =
      host     : @domain
      port     : @port
      method   : 'GET'
      auth     : @user + ':' + @password
      path     : path

    req = HTTP.request options, (response) ->
      response.setEncoding 'utf8'
      response.on 'data',  (chunk) ->
        userData = JSON.parse chunk
        callback(userData)

  connectAndAuthenticate: ->
    self = @

    options =
      host     : @domain
      port     : @port
      path     : '/api/v1/users/find_by_login/' + @user
      method   : 'GET'
      auth     : @user + ':' + @password

    req = HTTP.request options, (response) ->
      response.setEncoding 'utf8'
      response.on 'data',  (chunk) ->
        userData = JSON.parse chunk
        self.userId = userData.id
        self.connect userData.id, userData.communication_token
    req.on "error", ->
      console.log "api server '" + options.host + "' is not responding."
      self.reconnect()

    req.end()

  startAutomaticPing: ->
    self = @
    @.write { operation: "ping" } # one ping when starting
    @pingInterval = setInterval ->
      self.write { operation: "ping" }
    , 30000

  stopAutomaticPing: ->
    clearInterval @pingInterval

  connect: (userId, userCommunicationToken) ->
    console.log 'opened socket'
    self = @

    @socket = Net.connect 5000, @domain, () ->
      # 'connect' listener
      @.write '{\"payload\":{\"type\":\"web\",\"token\":\"' + userCommunicationToken + '\",\"user_id\":' + userId + '},\"operation\":\"authenticate\"}' + '\x00'
      self.startAutomaticPing()
      self.connected = true
      if self.reconnectInterval
        clearInterval self.reconnectInterval
        self.reconnectInterval = false
      self.emit "Ready"

    #callback
    @socket.on 'data', (data) ->
      self.buffer = "" if !self.buffer?
      # console.log 'data: ' + data
      self.buffer += data
      # console.log '@buffer: ' + self.buffer
      # console.log 'index: ' + self.buffer.indexOf('\x00')
      until self.buffer.indexOf('\x00') == -1
        line = self.buffer.slice 0, self.buffer.indexOf('\x00')
        self.buffer = self.buffer.slice self.buffer.indexOf('\x00')+1, self.buffer.length
        message = if line is '' then null else JSON.parse(line)
      
        if message
          console.log "Line: #{line}\n"
          # if message.type == "users"
          #   self.emit "Users", message
          if message.trigger == "meep.receive"
            self.emit "TextMessage", message
          if message.trigger == 'socket.update_id'
            console.log 'current_socket_id ' + self.socket_id
            self.socket_id = message.socket_id
            console.log 'new_socket_id ' + self.socket_id
          # if message.trigger == "user.came_online"
          #   self.emit "EnterMessage", message
          # if message.trigger == "user.goes_offline"
          #   self.emit "LeaveMessage", message
          # if message.type == "error"
          #   self.disconnect room, message.message

    @socket.addListener "error", ->
      console.log "socket server '" + @domain + "' is not responding."
      self.connected = false
      self.reconnect()

    @socket.addListener "eof", ->
      console.log "eof"
    @socket.addListener "timeout", ->
      console.log "timeout"
    @socket.addListener "end", ->
      console.log "end"
      self.reconnect()

    @socket.setEncoding @encoding

    @socket

  reconnect: ->
    self = @
    if !@reconnectInterval
      console.log 'reconnect interval set up'
      @connected = false
      @stopAutomaticPing()
      @reconnectInterval = setInterval ->
        console.log 'trying to reconnect.'
        self.connectAndAuthenticate()
      , 30000

  write: (args) ->
    self = @

    if @socket.readyState != 'open'
      return @reconnect 'cannot send with readyState: ' + @socket.readyState

    console.log 'socket_id: ' + @socket_id
    args['payload']['socket_id'] = @socket_id if args && args['payload'] && @socket_id

    message = JSON.stringify(args)
    console.log "write message: #{message}"

    @socket.write message + '\x00', @encoding

  disconnect: (why) ->
    if @socket != 'closed'
      @socket.end()
      console.log 'disconnected (reason: ' + why + ')'
    @stopAutomaticPing()
    @connected = false
