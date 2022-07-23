from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.alloc import alloc
from starkware.cairo.lang.compiler.lib.registers import get_fp_and_pc
from starkware.cairo.common.math import assert_not_equal
from src.data_types.data_types import Vertex, Edge

# # Adjancency list graph implementation
# # Meant to build a graph from AMM pairs

# # @notice builds a graph of nodes interconnected if the pair of tokens exists
# # @param pairs : An array of pairs
# # @returns graph_len : number of graph vertices
# # @returns graph : an array of vertices
# # @returns adj_vertices_count : an array that tracks the number of adjacent vertices of each vertex
# func build_graph(pairs_len : felt, pairs : Pair*) -> (
#     graph_len : felt, graph : Vertex*, adj_vertices_count : felt*
# ):
#     alloc_locals
#     let (local graph : Node*) = alloc()
#     let (local adj_vertices_count : felt*) = alloc()

# # the node at graph[i] has adj_vertices_count[i] adjacent vertices.
#     # that allows us to dynamically modify the number of neighbors to a vertex, without the need
#     # to rebuild the graph (since memory is write-once, we can't update a property of a struct already stored.)
#     let (graph_len, adj_vertices_count) = _build_graph(
#         pairs_len, pairs, 0, graph, adj_vertices_count
#     )

# return (graph_len, graph, adj_vertices_count)
# end

# # @notice internal function to build the graph recursively
# # @dev
# # @param pairs_len : The length of the pairs array
# # @param pairs : The pairs array
# # @param graph_len : The length of the graph
# # @param graph : The graph
# # @param neighbors : The array of neighbors
# func _build_graph(
#     pairs_len : felt, pairs : Pair*, graph_len : felt, graph : Vertex*, adj_vertices_count : felt*
# ) -> (graph_len : felt, adj_vertices_count : felt*):
#     alloc_locals

# if pairs_len == 0:
#         return (graph_len, adj_vertices_count)
#     end

# let token_0 = [pairs].token_0
#     let token_1 = [pairs].token_1

# let (graph_len) = try_add_node(graph_len, graph, adj_vertices_count, token_0)
#     let (graph_len) = try_add_node(graph_len, graph, adj_vertices_count, token_1)

# let (token_0_index) = get_vertex_index(graph_len, graph, token_0)
#     let (token_1_index) = get_vertex_index(graph_len, graph, token_1)

# let node_0 : Node = graph[token_0_index]
#     let node_1 : Node = graph[token_1_index]

# let (adj_vertices_count : felt*) = add_neighbor(
#         node_0, node_1, graph_len, adj_vertices_count, token_0_index
#     )
#     let (adj_vertices_count : felt*) = add_neighbor(
#         node_1, node_0, graph_len, adj_vertices_count, token_1_index
#     )

# return _build_graph(pairs_len - 1, pairs + Pair.SIZE, graph_len, graph, adj_vertices_count)
# end

# @notice Adds an edge between two graph vertices
# @dev if the vertices don't exist yet, adds them to the graph
# @param graph_len : The length of the graph
# @param graph : The graph
# @param adj_vertices_count : The array of adjacent vertices counts
# @param vertex0 : The first vertex
# @param vertex1 : The second vertex
# @returns graph_len : The new length of the graph
# @returns adj_vertices_count : The new array of adjacent vertices counts
# TODO allow weight
func add_edge(graph : Vertex*, graph_len : felt, adj_vertices_count : felt*, edge : Edge) -> (
    graph_len : felt, adj_vertices_count : felt*
):
    alloc_locals
    let src_identifier = edge.src_identifier
    let dst_identifier = edge.dst_identifier
    let weight = edge.weight
    assert_not_equal(src_identifier, dst_identifier)  # can't add two nodes with the same identifier
    let (src_vertex_index) = get_vertex_index(graph_len, graph, src_identifier)
    let (dst_vertex_index) = get_vertex_index(graph_len, graph, dst_identifier)

    # Add both vertices to the graph if they aren't already there
    if src_vertex_index == -1:
        let (local new_graph_len) = add_vertex_to_graph(
            graph_len, graph, adj_vertices_count, src_identifier
        )
        tempvar src_vertex_index = new_graph_len - 1
        tempvar graph_len = new_graph_len
    else:
        tempvar src_vertex_index = src_vertex_index
        tempvar graph_len = graph_len
    end

    tempvar src_vertex_index = src_vertex_index

    if dst_vertex_index == -1:
        let (local new_graph_len) = add_vertex_to_graph(
            graph_len, graph, adj_vertices_count, dst_identifier
        )
        tempvar dst_vertex_index = new_graph_len - 1
        tempvar graph_len = new_graph_len
    else:
        tempvar dst_vertex_index = dst_vertex_index
        tempvar graph_len = graph_len
    end

    tempvar dst_vertex_index = dst_vertex_index
    tempvar graph_len = graph_len

    # Add the edge from src to dst to the graph, stored as an adjacent vertex in the adjacency lists of the source.
    let (adj_vertices_count : felt*) = add_neighbor(
        graph[src_vertex_index],
        graph[dst_vertex_index],
        graph_len,
        adj_vertices_count,
        src_vertex_index,
        weight,
    )
    return (graph_len, adj_vertices_count)
end

# @notice adds a vertex to the graph
# @param vertex : The vertex to add
# @param graph_len : The length of the graph
# @param graph : The graph represented by an array of vertices
# @param adj_vertices_count : The array of adjacent vertices counts
# @param identifier : Unique identifier for the vertex to add
# @returns graph_len : The new length of the graph
# TODO allow additional data
func add_vertex_to_graph(
    graph_len : felt, graph : Vertex*, adj_vertices_count : felt*, identifier : felt
) -> (new_graph_len : felt):
    let adj_vertices : Vertex* = alloc()
    tempvar vertex : Vertex = Vertex(graph_len, identifier, adj_vertices)
    assert graph[graph_len] = vertex
    assert adj_vertices_count[graph_len] = 0
    let graph_len = graph_len + 1
    return (graph_len)
end

# @notice adds a neighbor to the neighbors of a node
# @param node pointer to the current node
# @param neighbor the neighbor to add to the current node
# @return the updated vertex
func add_neighbor(
    vertex : Vertex,
    new_neighbor : Vertex,
    adj_vertices_coun_len : felt,
    adj_vertices_count : felt*,
    vertex_index_in_graph : felt,
    weight : felt,
) -> (adj_vertices_count : felt*):
    let current_len = adj_vertices_count[vertex_index_in_graph]
    assert vertex.adjacent_vertices[current_len] = new_neighbor
    # update neighbors_len
    let (new_adj_vertices_len : felt*) = update_adj_vertices_count(
        adj_vertices_coun_len, adj_vertices_count, vertex_index_in_graph
    )
    return (new_adj_vertices_len)
end

# @notice increments the neighbors_len of a node by re-writing the entire
func update_adj_vertices_count(
    adj_vertices_count_len : felt, adj_vertices_count : felt*, vertex_index_in_graph : felt
) -> (new_neighbors : felt*):
    alloc_locals
    let (__fp__, _) = get_fp_and_pc()
    let (local res : felt*) = alloc()
    local new_value = adj_vertices_count[vertex_index_in_graph] + 1
    memcpy(res, adj_vertices_count, vertex_index_in_graph)  # copy index elems from neighbors_len to res
    memcpy(res + vertex_index_in_graph, &new_value, 1)  # store updated_node at memory cell [res+member_index]

    # first memory address to copy in
    # first memory address to copy from
    # number of value to copy
    memcpy(
        res + vertex_index_in_graph + 1,
        adj_vertices_count + vertex_index_in_graph + 1,
        adj_vertices_count_len - vertex_index_in_graph - 1,
    )

    return (res)
end

# @notice Recursive function returning the index of the node in the graph
# @param graph_len
# @param graph_len
# @param identifier, The unique identifier of the vertex
# @returns -1 if it's not in the graph
# @returns its index in the graph data structure otherwise
func get_vertex_index(graph_len : felt, graph : Vertex*, identifier : felt) -> (index : felt):
    if graph_len == 0:
        return (-1)
    end

    let current_identifier : felt = [graph].identifier
    if current_identifier == identifier:
        return ([graph].index)
    end

    return get_vertex_index(graph_len - 1, graph + Vertex.SIZE, identifier)
end
