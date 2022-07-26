from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.alloc import alloc
from starkware.cairo.lang.compiler.lib.registers import get_fp_and_pc
from starkware.cairo.common.math import assert_not_equal
from src.data_types.data_types import Vertex, Edge
from src.utils.array_utils import Array

# # Adjancency list graph implementation
# # Meant to build a graph from AMM pairs

# @notice Adds an edge between two graph vertices
# @dev if the vertices don't exist yet, adds them to the graph
# @param graph_len : The length of the graph
# @param graph : The graph
# @param adj_vertices_count : The array of adjacent vertices counts
# @param vertex0 : The first vertex
# @param vertex1 : The second vertex
# @returns graph_len : The new length of the graph
# @returns adj_vertices_count : The new array of adjacent vertices counts
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
    let current_count = adj_vertices_count[vertex_index_in_graph]
    assert vertex.adjacent_vertices[current_count] = new_neighbor
    # update neighbors_len
    let new_count = current_count + 1
    let (new_adj_vertices_count : felt*) = Array.update_value_at_index(
        adj_vertices_coun_len, adj_vertices_count, vertex_index_in_graph, new_count
    )
    return (new_adj_vertices_count)
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
