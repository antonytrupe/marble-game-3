class_name TreeSpawnTest
extends GdUnitTestSuite

var _server: Server
var _mock_world: World
var _mock_flora: Node

func before_test() -> void:
	_server = auto_free(Server.new())
	_mock_world = mock(World)
	_mock_flora = mock(Node)
	_server.world = _mock_world
	# In GDScript, we can't easily mock property access if it's not a function
	# but we can try to set it if it's not @onready or if we bypass it.
	# Actually, in Server.gd, world is @onready, so we can just set it.
	_mock_world.flora = _mock_flora

func test_spawn_trees_avoids_overlap() -> void:
	# 1. Setup existing tree
	var existing_tree = auto_free(MarbleTree.new())
	existing_tree.position = Vector3(0, 0, 0)
	existing_tree.scale = Vector3(1, 1, 1)
	
	do_return([existing_tree]).on(_mock_flora).get_children()
	
	# Mock _get_random_vector to return a position close to (0,0,0) first, then far away
	# Wait, _get_random_vector is in the same class, we might need to mock the server itself
	# or just rely on the random distribution and check results.
	
	# Since we can't easily mock internal calls in the same object without partial doubles
	# and _get_random_vector uses randf(), we'll just run _spawn_trees and check the results.
	
	# We need to mock world.get_ground_y which is called by _get_random_vector
	do_return(0.0).on(_mock_world).get_ground_y(any_float(), any_float())
	
	# 2. Act - spawn 10 trees
	_server._spawn_trees(10, Vector3(0, 0, 0))
	
	# 3. Assert - all spawned trees should be at least 5.0 away from existing_tree (0,0,0)
	# and at least 5.0 away from each other.
	var spawned_trees = []
	# We need to capture the trees added to flora
	# Since we can't easily capture arguments in GdUnit4 without more setup,
	# let's just use a real Node for flora and check its children.
	_server.world.flora = Node.new()
	_server.world.flora.add_child(existing_tree)
	
	_server._spawn_trees(10, Vector3(0, 0, 0))
	
	var children = _server.world.flora.get_children()
	assert_int(children.size()).is_equal(11) # 1 existing + 10 new
	
	for i in range(children.size()):
		for j in range(i + 1, children.size()):
			var t1 = children[i]
			var t2 = children[j]
			var dist = t1.position.distance_to(t2.position)
			assert_float(dist).is_greater_equal(4.9) # Allow some floating point epsilon
	
	_server.world.flora.free()


func test_spawn_single_tree_in_front_of_character() -> void:
	# 1. Setup
	var character: MarbleCharacter = auto_free(MarbleCharacter.new())
	_server.add_child(character)
	character.position = Vector3(10, 0, 10)
	# Looking towards -Z (default)
	character.transform.basis = Basis.IDENTITY
	
	_server.world.flora = auto_free(Node.new())
	do_return(0.0).on(_mock_world).get_ground_y(any_float(), any_float())
	
	# 2. Act
	_server._spawn_trees(1, character.position, 0.0, character)
	
	# 3. Assert
	var children = _server.world.flora.get_children()
	assert_int(children.size()).is_equal(1)
	var tree = children[0]
	
	# Expected position: center (10,0,10) + forward (0,0,-1) * 4.0 = (10, 0, 6)
	assert_float(tree.position.x).is_equal(10.0)
	assert_float(tree.position.z).is_equal(6.0)
