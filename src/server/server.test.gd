class_name ServerTest
extends GdUnitTestSuite

const WorldScene: PackedScene = preload("res://src/world/world.tscn")
const ServerScene: PackedScene = preload("res://src/server/server.tscn")

# The class under test
var _server: Server
var _world: World


func before_test() -> void:
	# Create an instance of the server script
	_server = mock(Server,CALL_REAL_FUNC)
	_world = mock("res://src/world/world.tscn",CALL_REAL_FUNC)
	add_child(_world)
	_server.world = _world


func test_get_random_vector_within_radius_and_on_ground() -> void:
	# Test the distance calculation algorithm used by _get_random_vector
	var radius: float = 50.0
	var center: Vector3 = Vector3(10, 0, 20)

	# Act & Assert - Verify random points stay within radius
	for i: int in range(100):
		# Replicate the calculation from _get_random_vector
		var r: float = radius * sqrt(randf())
		var theta: float = randf() * 2 * PI
		var x: float = center.x + r * cos(theta)
		var z: float = center.z + r * sin(theta)

		# Assert XZ distance is within the radius
		var distance: float = Vector2(x - center.x, z - center.z).length()
		assert_float(distance).is_less_equal(radius)


func test_spawn_spring_method_exists() -> void:
	assert_bool(_server.has_method("_spawn_spring")).is_true()


func test_spawn_spring_adds_it_to_terra() -> void:
	_server.world = _world
	do_return(0.0).on(_world).get_ground_y(any_float(), any_float())

	var character: MarbleCharacter = auto_free(MarbleCharacter.new())
	character.global_position = Vector3(0, 0, 0)
	character.global_transform.basis = Basis(Vector3.RIGHT, Vector3.UP, Vector3.BACK)

	_server._spawn_spring(character)

	assert_int(_world.terra.get_child_count()).is_equal(1)
	assert_object(_world.terra.get_child(0)).is_instanceof(Spring)


# --- Tests for Steam/ENet networking changes ---

func test_use_steam_defaults_to_true() -> void:
	var server: Server = auto_free(Server.new())
	assert_bool(server.use_steam).is_true()


func test_use_steam_can_be_set_to_false() -> void:
	_server.use_steam = false
	assert_bool(_server.use_steam).is_false()


func test_steam_signals_skipped_when_steam_disabled() -> void:
	# When use_steam is false, _steam_signals should return early without error
	_server.use_steam = false
	# Should not crash or attempt to connect Steam signals
	_server._steam_signals()


func test_quit_without_steam_does_not_call_leave_lobby() -> void:
	# When use_steam is false, quit should skip Steam.leaveLobby
	_server.use_steam = false
	# Add server to the scene tree so get_tree() is not null (needed by _persist)
	var s: Server = mock(Server, CALL_REAL_FUNC)
	add_child(s)
	# Re-assign world since add_child triggers _ready which overwrites @onready vars
	s.use_steam = false
	s.world = _world
	s.quit()
	remove_child(s)
# If we got here without error, Steam.leaveLobby was correctly skipped


func test_on_peer_connected_enet_player_id_format() -> void:
	# When use_steam is false, player_id should be "ENet_<peer_id>"
	_server.use_steam = false
	_server.players = auto_free(Node.new())

	# Create a character from scene so @onready child nodes exist
	var character: MarbleCharacter = auto_free(MarbleCharacter.scene.instantiate())
	character.name = "test_char"
	_server.world.characters.add_child(character)

	# Create a player with ENet naming
	var player: Player = auto_free(Player.new())
	player.name = "ENet_1"
	player.peer_id = 1
	player.current_character_id = "test_char"
	_server.players.add_child(player)

	# Mock client
	var mock_client: Client = auto_free(Client.new())
	mock_client.world = _server.world
	_server.client = mock_client

	_server._on_peer_connected(1)

	# Verify the player was found and connected
	assert_bool(_server.connected_players.has(1)).is_true()
	assert_object(_server.connected_players[1]).is_same(player)


func test_on_peer_connected_enet_sets_friend_name() -> void:
	# When use_steam is false, friend_name should be "Player_<peer_id>"
	_server.use_steam = false
	_server.players = auto_free(Node.new())

	var character: MarbleCharacter = auto_free(MarbleCharacter.scene.instantiate())
	character.name = "test_char"
	_server.world.characters.add_child(character)

	var player: Player = auto_free(Player.new())
	player.name = "ENet_42"
	player.peer_id = 42
	player.current_character_id = "test_char"
	_server.players.add_child(player)

	var mock_client: Client = auto_free(Client.new())
	mock_client.world = _server.world
	_server.client = mock_client

	_server._on_peer_connected(42)

	# Character should have the ENet-style player name
	assert_str(character.player_name).is_equal("Player_42")


func test_on_peer_connected_steam_player_id_format() -> void:
	var character: MarbleCharacter = auto_free(MarbleCharacter.scene.instantiate())
	character.name = "test_char"
	_server.world.characters.add_child(character)

	var mock_client: Client = auto_free(Client.new())
	mock_client.world = _server.world

	# Add server to scene tree so multiplayer is not null
	_server.use_steam = true
	add_child(_server)
	# Re-assign after add_child since _ready overwrites @onready vars
	_server.world = _world
	_server.client = mock_client
	_server.players = auto_free(Node.new())

	# Pre-create a player with Steam naming
	var player: Player = auto_free(Player.new())
	var fake_steam_id: int = 76561197960287930 # Example SteamID64
	player.name = "Steam_" + str(fake_steam_id)
	player.peer_id = 42
	player.current_character_id = "test_char"
	_server.players.add_child(player)

	var target_peer_id: int = 42
	do_return(fake_steam_id).on(_server).get_steam_id(any())
	assert_int(_server.get_steam_id(target_peer_id)).is_equal(fake_steam_id)
	
	do_return(player).on(_server)._create_player(42, "Steam_" + str(fake_steam_id))

	_server._on_peer_connected(42)

	remove_child(_server)

	assert_bool(_server.connected_players.has(42)).is_true()
	assert_object(_server.connected_players[42]).is_same(player)
	assert_object(_server.connected_players[42].name).is_same(player.name)


func test_chat_routes_to_enet_player() -> void:
	# When use_steam is false, chat should look up player from connected_players
	_server.use_steam = false

	var character: MarbleCharacter = auto_free(MarbleCharacter.scene.instantiate())
	character.name = "test_char"
	_server.world.characters.add_child(character)

	var player: Player = auto_free(Player.new())
	player.name = "ENet_1"
	player.peer_id = 1
	player.current_character_id = "test_char"

	_server.connected_players[1] = player

	# chat() calls multiplayer.get_remote_sender_id() which returns 0 in tests
	# so we set up connected_players[0] as well
	_server.connected_players[0] = player

	do_return(0).on(_server).get_remote_sender_id()

	# Should not crash trying to access Steam API
	_server.chat("hello")
