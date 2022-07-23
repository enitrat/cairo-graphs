from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.alloc import alloc
from starkware.cairo.lang.compiler.lib.registers import get_fp_and_pc

from starknet.data_types.data_types import Node, Pair
# Adjancency list graph implementation
# Meant to build a graph from AMM pairs

# @notice builds a graph of nodes interconnected if the pair of tokens exists
# @param pairs : An array of pairs
func build_graph(pairs_len : felt, pairs : Pair*) -> (
    graph_len : felt, graph : Node*, neighbors : felt*
):
    alloc_locals
    let (local graph : Node*) = alloc()
    let (local neighbors : felt*) = alloc()  # array that tracks neighbors_len

    # the node at graph[i] has neighbors[i] neighbors
    # that allows us to dynamically add neighbors to nodes, without
    # needing to copy the struct entirely to update len
    let (graph_len,neighbors) = _build_graph(pairs_len, pairs, 0, graph, neighbors)

    return (graph_len, graph, neighbors)
end

# @notice internal function to build the graph recursively
# @dev
# @param pairs_len : The length of the pairs array
# @param pairs : The pairs array
# @param graph_len : The length of the graph
# @param graph : The graph
# @param neighbors : The array of neighbors
func _build_graph(
    pairs_len : felt, pairs : Pair*, graph_len : felt, graph : Node*, neighbors : felt*
) -> (graph_len : felt,neighbors:felt*):
    alloc_locals

    if pairs_len == 0:
        return (graph_len,neighbors)
    end

    let token_0 = [pairs].token_0
    let token_1 = [pairs].token_1

    let (graph_len) = try_add_node(graph_len, graph, neighbors, token_0)
    let (graph_len) = try_add_node(graph_len, graph, neighbors, token_1)

    let (token_0_index) = get_node_index(graph_len, graph, token_0)
    let (token_1_index) = get_node_index(graph_len, graph, token_1)

    let node_0 : Node = graph[token_0_index]
    let node_1 : Node = graph[token_1_index]

    let (neighbors : felt*) = add_neighbor(node_0, node_1, graph_len, neighbors, token_0_index)
    let (neighbors : felt*) = add_neighbor(node_1, node_0, graph_len, neighbors, token_1_index)

    return _build_graph(pairs_len - 1, pairs + Pair.SIZE, graph_len, graph, neighbors)
end

func try_add_node(graph_len : felt, graph : Node*, neighbors : felt*, token : felt) -> (
    graph_len : felt
):
    let (token_index) = get_node_index(graph_len, graph, token)

    if token_index == -1:
        let (graph_len) = add_node_to_graph(graph_len, graph, neighbors, token)
        return (graph_len)
    end
    return (graph_len)
end

# @notice adds a node to the graph
# @param node : The node to add
func add_node_to_graph(graph_len : felt, graph : Node*, neighbors : felt*, identifier : felt) -> (
    new_graph_len : felt
):
    let neighbor_nodes : Node* = alloc()
    tempvar node : Node = Node(graph_len, identifier, neighbor_nodes)
    assert graph[graph_len] = node
    assert neighbors[graph_len] = 0
    let graph_len = graph_len + 1
    return (graph_len)
end

# @notice adds a neighbor to the neighbors of a node
# @param node pointer to the current node
# @param neighbor the neighbor to add to the current node
# @return the updated node
func add_neighbor(
    node : Node,
    new_neighbor : Node,
    neighbors_len : felt,
    neighbors : felt*,
    node_index_in_graph : felt,
) -> (new_neighbors : felt*):
    let current_len = neighbors[node_index_in_graph]
    assert node.neighbor_nodes[current_len] = new_neighbor
    # update neighbors_len
    let (new_neighbors : felt*) = increment_neighbors_len(
        neighbors_len, neighbors, node_index_in_graph
    )
    return (new_neighbors)
end

func increment_neighbors_len(
    neighbors_len : felt, neighbors : felt*, node_index_in_graph : felt
) -> (new_neighbors : felt*):
    alloc_locals
    let (__fp__, _) = get_fp_and_pc()
    let (local res : felt*) = alloc()
    local new_value = neighbors[node_index_in_graph] + 1
    memcpy(res, neighbors, node_index_in_graph)  # copy index elems from neighbors_len to res
    memcpy(res + node_index_in_graph, &new_value, 1)  # store updated_node at memory cell [res+member_index]

    # first pointer to copy in
    # first pointer to copy from
    # number of value to copy
    memcpy(
        res + node_index_in_graph + 1,
        neighbors + node_index_in_graph + 1,
        neighbors_len - node_index_in_graph - 1,
    )  # copy the rest of

    return (res)
end

# @notice returns the index of the node in the graph
# @returns -1 if it's not in the graph
# @returns array index otherwise
func get_node_index(graph_len : felt, graph : Node*, identifier : felt) -> (index : felt):
    if graph_len == 0:
        return (-1)
    end

    let current_identifier : felt = [graph].identifier
    if current_identifier == identifier:
        return ([graph].index)
    end

    return get_node_index(graph_len - 1, graph + Node.SIZE, identifier)
end
