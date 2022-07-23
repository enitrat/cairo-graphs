%lang starknet
from starknet.graph.graph import (
    Pair,
    Node,
    add_neighbor,
    add_node_to_graph,
    build_graph,
    get_node_index,
)
from starkware.cairo.common.alloc import alloc

const TOKEN_A = 123
const TOKEN_B = 456
const TOKEN_C = 990
const TOKEN_D = 982

const RESERVE_A_B_0_LOW = 27890
const RESERVE_A_B_1_LOW = 26789

const PAIR_A_B = 90174089
const PAIR_A_C = 90182194
const PAIR_A_D = 90712441

func build_graph_before_each() -> (
    graph : Node*, graph_len : felt, neighbors : felt*, neighbors_len : felt
):
    alloc_locals
    let (graph : Node*) = alloc()
    let (neighbors : felt*) = alloc()  # array that tracks neighbors_len

    let (node_a_neighbors : Node*) = alloc()
    let (node_b_neighbors : Node*) = alloc()
    let (node_c_neighbors : Node*) = alloc()

    local node_a : Node = Node(0, TOKEN_A, node_a_neighbors)
    local node_b : Node = Node(1, TOKEN_B, node_b_neighbors)
    local node_c : Node = Node(2, TOKEN_C, node_c_neighbors)

    # populate graph
    assert graph[0] = node_a
    assert neighbors[0] = 0
    assert graph[1] = node_b
    assert neighbors[1] = 0
    assert graph[2] = node_c
    assert neighbors[2] = 0
    let neighbors_len = 3
    let graph_len = 3
    return (graph, graph_len, neighbors, neighbors_len)
end

@external
func test_add_node_to_graph():
    let (graph : Node*) = alloc()
    let (neighbors : felt*) = alloc()  # array that tracks the number of neighbor_nodes
    let graph_len : felt = 0

    let (graph_len) = add_node_to_graph(graph_len, graph, neighbors, TOKEN_A)
    assert graph_len = 1
    assert graph[0].identifier = TOKEN_A
    assert neighbors[0] = 0

    let (graph_len) = add_node_to_graph(graph_len, graph, neighbors, TOKEN_B)
    assert graph_len = 2
    assert graph[1].identifier = TOKEN_B
    assert neighbors[1] = 0

    return ()
end

@external
func test_add_neighbor():
    alloc_locals
    let (graph, graph_len, neighbors, neighbors_len) = build_graph_before_each()
    assert graph[0].identifier = TOKEN_A
    assert graph[1].identifier = TOKEN_B
    assert graph[2].identifier = TOKEN_C
    assert neighbors_len = 3  # neighbors_len is 3 because we have 3 nodes in our graph

    # add TOKEN_B as neighbor of TOKEN_A
    let (neighbors) = add_neighbor(graph[0], graph[1], neighbors_len, neighbors, 0)
    assert graph[0].neighbor_nodes[0].identifier = TOKEN_B
    assert neighbors[0] = 1  # TOKEN_A has 1 neighbor, which is TOKEN_B
    assert neighbors[1] = 0  # TOKEN_B still has 0 neighbors

    # now add TOKEN_A as neighbor of TOKEN_B
    let (neighbors) = add_neighbor(graph[1], graph[0], neighbors_len, neighbors, 1)
    assert graph[1].neighbor_nodes[0].identifier = TOKEN_A
    assert neighbors[1] = 1  # TOKEN_B now has 1 neighbor

    # add TOKEN_C as neighbor of TOKEN_A
    let (neighbors) = add_neighbor(graph[0], graph[2], neighbors_len, neighbors, 0)
    assert graph[0].neighbor_nodes[1].identifier = TOKEN_C
    assert neighbors[0] = 2  # TOKEN_A now has 2 neighbors

    return ()
end

@external
func test_get_node_index():
    alloc_locals
    let (graph, graph_len, neighbors, neighbors_len) = build_graph_before_each()

    let (local res : felt) = get_node_index(graph_len, graph, TOKEN_A)
    assert res = 0
    let (local res : felt) = get_node_index(graph_len, graph, TOKEN_B)
    assert res = 1

    return ()
end

@external
func test_build_graph():
    let pairs : Pair* = alloc()
    assert pairs[0] = Pair(TOKEN_A, TOKEN_B)
    assert pairs[1] = Pair(TOKEN_A, TOKEN_C)
    assert pairs[2] = Pair(TOKEN_B, TOKEN_C)

    let (graph_len, graph, neighbors) = build_graph(pairs_len=3, pairs=pairs)
    assert graph_len = 3
    assert graph[0].identifier = TOKEN_A
    assert graph[1].identifier = TOKEN_B
    assert graph[2].identifier = TOKEN_C
    assert neighbors[0] = 2
    assert neighbors[1] = 2
    assert neighbors[2] = 2
    return ()
end
