extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
    Gotm.connect("lobby_changed", self, "_on_lobby_changed")
    lobby_connect()

remote func set_color(color):
    $Background.color = Color(color)
    $Events.text += "Setting my color to: %s\n" % color

remote func join_lobby(new_lobby):
    print("Joining Lobby: " + str(new_lobby))
    var success = yield(new_lobby.join(), "completed")
    var peer = NetworkedMultiplayerENet.new()
    peer.create_client(Gotm.lobby.host.address, 8070)  
    get_tree().set_network_peer(peer)
    
func lobby_connect():
    print("Connecting lobby.")
    # The `fetch` object will be used to get a list of all the lobbies.
    var fetch = GotmLobbyFetch.new()
    # All of the lobbies that are currently available for your game.
    var lobbies = yield(fetch.next(10), "completed")
    # The `peer` object will contain the network interface that other games
    #  will use to contact yours.
    var peer
    # For this sample, we'll only be using one lobby. If there are any lobbies
    #  in the list, then there is already a host.
    if lobbies:
        print("Lobbies:")
        for lobby in lobbies:
            print("    %s: %s" % [str(lobby.name), lobby.get_property("created")])
        # So we'll take the first (and only) lobby in the list.
        var lobby = lobbies[0]
        # and join it.
        var success = yield(lobby.join(), "completed")
        # By creating `NetworkedMultiplayerENet` we give our game access to high
        #  level networking functions like `rpc`
        peer = NetworkedMultiplayerENet.new()
        # Since the lobby already existed, we know there is a `Gotm.lobby.host`, and
        #  we can connect to it as a client to the host's ipAddress/port.
        peer.create_client(Gotm.lobby.host.address, 8070)  
        print("Lobby Joined:")
    else:
        print("No lobbies found.")
        # Since there are no lobbies, we'll create a new one.  By setting the first
        #  parameter to `false` you tell Gotm to not create a share link. This value
        #  would be true by default.
        Gotm.host_lobby(false)
        # Notice that we can treat the `Gotm.lobby` just like any other node in our game,
        #  so we can set it's properties and call methods like normal.
        Gotm.lobby.name = "Color Changer"
        # If the `Gotm.lobby.hidden` is set to true, then it won't show up when another
        #  player won't see it when they fetch the lobbies.
        Gotm.lobby.hidden = false
        # Like above, the host needs to create a `NetworkedMultiplayerENet`
        peer = NetworkedMultiplayerENet.new()
        # Then create a new server for clients to connect to the servers port. 
        peer.create_server(8070)
        print("Lobby Created")
    # For both client & server, then add the `peer` to the node tree, and then
    #  other systems will be able to connect and send RPC calls to it.
    print_peers()
    get_tree().set_network_peer(peer)

func print_peers():
    print("Peers Visible:")
    for peer in Gotm.lobby.peers:
        print("  - %s : %s" % [peer.id, peer.display_name])
        
func on_gotm():
    if Gotm.is_live():
        $Fields/IsOnGotM.text = "On GotM: true"
    else:
        $Fields/IsOnGotM.text = "On GotM: false"

func logged_in():
    if Gotm.user.is_logged_in():
        $Fields/LoggedIn.text = "Logged In: true"
    else:
        $Fields/LoggedIn.text = "Logged In: false"
        
func usernamed():
    if Gotm.user.is_logged_in():
        $Fields/Username.text = "Username: " + Gotm.user.display_name
    else:
        $Fields/Username.text = "Username: ?"
        
func in_lobby():
    if Gotm.lobby:
        $Fields/InLobby.text = "In Lobby: " + Gotm.lobby.name
    else:
        $Fields/InLobby.text = "In Lobby: ?"
        
func host_is():
    if Gotm.lobby:
        $Fields/IsHost.text = "Host Is: " + Gotm.lobby.host.display_name
    else:
        $Fields/IsHost.text = "Host Is: ?"
        
func number_in_lobby():
    if Gotm.lobby:
        $Fields/NumberInLobby.text = "Players In Lobby: " + str(len(Gotm.lobby.peers) + 1)
    else:
        $Fields/NumberInLobby.text = "Players In Lobby: 0"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    on_gotm()
    logged_in()
    usernamed()
    in_lobby()
    host_is()
    number_in_lobby()

func _on_SendColor_pressed():
    print("Sending Color: " + str($ColorPickerButton.color))
    rpc("set_color", $ColorPickerButton.color)

func _on_lobby_changed():
    print("Lobby changed.\n")
    if Gotm.lobby:
        print("Lobby Exists.\n")
        get_tree().connect("network_peer_connected", self, "_on_network_peer_connected")
        get_tree().connect("network_peer_disconnected", self, "_on_network_peer_disconnected")
        if Gotm.lobby.is_host():
            print("I'm the Host: %s\n" % str(Gotm.lobby.id))
        print_peers()
    else:
        print("Lobby Lost.")
        lobby_connect()

func _on_network_peer_connected(peer_id):
    print("Peer network connection: %s\n" % str(peer_id))
    print_peers()

func _on_network_peer_disconnected(peer_id):
    print("Peer network disconnection: %s\n" % str(peer_id))
    print_peers()
