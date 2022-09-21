from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_not_equal

from cairo_graphs.data_types.data_types import Vertex, Edge, AdjacentVertex
from cairo_graphs.utils.array_utils import Array

// # Adjancency list graph implementation

namespace Graph {
    // @notice Creates a new empty graph.
    func new_graph() -> (graph_len: felt, graph: Vertex*, adj_vertices_count: felt*) {
        let (graph: Vertex*) = alloc();
        let (adj_vertices_count: felt*) = alloc();
        return (0, graph, adj_vertices_count);
    }

    // @notice Builds an undirected graph
    // @param edges_len : The length of the array of edges
    // @param edges : The array of edges
    // @returns graph_len : The length of the graph array
    // @returns graph : The graph array
    // @returns adj_vertices_count : Array that tracks how many adjacent vertices each vertex has.
    func build_undirected_graph_from_edges(edges_len: felt, edges: Edge*) -> (
        graph_len: felt, graph: Vertex*, adj_vertices_count: felt*
    ) {
        alloc_locals;
        let (graph_len, graph, adj_vertices_count) = Graph.new_graph();
        return build_undirected_graph_from_edges_internal(
            edges_len, edges, graph_len, graph, adj_vertices_count
        );
    }

    // @notice Builds a directed graph
    // @param edges_len : The length of the array of edges
    // @param edges : The array of edges
    // @returns graph_len : The length of the graph array
    // @returns graph : The graph array
    // @returns adj_vertices_count : Array that tracks how many adjacent vertices each vertex has.
    func build_directed_graph_from_edges(edges_len: felt, edges: Edge*) -> (
        graph_len: felt, graph: Vertex*, adj_vertices_count: felt*
    ) {
        let (graph_len, graph, adj_vertices_count) = Graph.new_graph();
        return build_directed_graph_from_edges_internal(
            edges_len, edges, graph_len, graph, adj_vertices_count
        );
    }

    // @notice Adds an edge between two graph vertices
    // @dev if the vertices don't exist yet, adds them to the graph
    // @param graph_len : The length of the graph
    // @param graph : Graph represented as an array of Vertices.
    // @param adj_vertices_count : Array that tracks how many adjacent vertices each vertex has.
    // adj_vertices_count[i] representes the length of graph[i].adj_vertices.
    // @param edge : Edge to add to the graph. Holds the info about the src_identifier, dst_identifier and weight.
    // @returns graph_len : The new length of the graph
    // @returns adj_vertices_count : Updated adj_vertices_count array with updated length for adj_vertices_count[source.index]
    func add_edge(graph: Vertex*, graph_len: felt, adj_vertices_count: felt*, edge: Edge) -> (
        graph_len: felt, adj_vertices_count: felt*
    ) {
        alloc_locals;
        let src_identifier = edge.src_identifier;
        let dst_identifier = edge.dst_identifier;
        let weight = edge.weight;
        assert_not_equal(src_identifier, dst_identifier);  // can't add two nodes with the same identifier
        let (src_vertex_index) = get_vertex_index(graph_len, graph, src_identifier);
        let (dst_vertex_index) = get_vertex_index(graph_len, graph, dst_identifier);

        // Add both vertices to the graph if they aren't already there
        if (src_vertex_index == -1) {
            let (local new_graph_len) = add_vertex_to_graph(
                graph_len, graph, adj_vertices_count, src_identifier
            );
            tempvar src_vertex_index = new_graph_len - 1;
            tempvar graph_len = new_graph_len;
        } else {
            tempvar src_vertex_index = src_vertex_index;
            tempvar graph_len = graph_len;
        }

        tempvar src_vertex_index = src_vertex_index;

        if (dst_vertex_index == -1) {
            let (local new_graph_len) = add_vertex_to_graph(
                graph_len, graph, adj_vertices_count, dst_identifier
            );
            tempvar dst_vertex_index = new_graph_len - 1;
            tempvar graph_len = new_graph_len;
        } else {
            tempvar dst_vertex_index = dst_vertex_index;
            tempvar graph_len = graph_len;
        }

        tempvar dst_vertex_index = dst_vertex_index;
        tempvar graph_len = graph_len;

        // Add the edge from src to dst to the graph, stored as an adjacent vertex in the adjacency lists of the source.
        let (adj_vertices_count: felt*) = add_neighbor(
            graph[src_vertex_index],
            graph[dst_vertex_index],
            graph_len,
            adj_vertices_count,
            src_vertex_index,
            weight,
        );
        tempvar dst_vertex_index = dst_vertex_index;

        return (graph_len, adj_vertices_count);
    }

    // @notice Adds a vertex to the graph
    // @dev Creates a new vertex stored at graph[graph_len].
    // @param graph_len : The length of the graph
    // @param graph : Graph represented as an array of Vertices.
    // @param adj_vertices_count : Array that tracks how many adjacent vertices each vertex has.
    // @param identifier : Unique identifier of the vertex to add
    // @returns graph_len : The new length of the graph
    func add_vertex_to_graph(
        graph_len: felt, graph: Vertex*, adj_vertices_count: felt*, identifier: felt
    ) -> (new_graph_len: felt) {
        let adj_vertices: AdjacentVertex* = alloc();
        tempvar vertex: Vertex = Vertex(graph_len, identifier, adj_vertices);
        assert graph[graph_len] = vertex;
        assert adj_vertices_count[graph_len] = 0;
        let graph_len = graph_len + 1;
        return (graph_len,);
    }

    // @notice Recursive function returning the index of the node in the graph
    // @param graph_len : The length of the graph
    // @param graph : Graph represented as an array of Vertices.
    // @param identifier, The unique identifier of the vertex.
    // @returns -1 if it's not in the graph, the index in the graph data structure otherwise
    func get_vertex_index(graph_len: felt, graph: Vertex*, identifier: felt) -> (index: felt) {
        if (graph_len == 0) {
            return (-1,);
        }

        let current_identifier: felt = [graph].identifier;
        if (current_identifier == identifier) {
            return ([graph].index,);
        }

        return get_vertex_index(graph_len - 1, graph + Vertex.SIZE, identifier);
    }
}

// @notice adds a neighbor to the adjacent vertices of a vertex
// @param vertex : The vertex to add the neighbor to.
// @param new_neighbor : The neighbor to add to the vertex.
// @param adj_vertices_count_len : The length of the adj_vertices_count array.
// @param adj_vertices_count : Array that tracks how many adjacent vertices each vertex has.
// @param vertex_index_in_graph : The index of the vertex in the graph.
// @return the updated adj_vertices_count
func add_neighbor(
    vertex: Vertex,
    new_neighbor: Vertex,
    adj_vertices_coun_len: felt,
    adj_vertices_count: felt*,
    vertex_index_in_graph: felt,
    weight: felt,
) -> (adj_vertices_count: felt*) {
    let current_count = adj_vertices_count[vertex_index_in_graph];
    tempvar adjacent_vertex = AdjacentVertex(new_neighbor, weight);
    assert vertex.adjacent_vertices[current_count] = adjacent_vertex;
    // update neighbors_len
    let new_count = current_count + 1;
    let (new_adj_vertices_count: felt*) = Array.update_value_at_index(
        adj_vertices_coun_len, adj_vertices_count, vertex_index_in_graph, new_count
    );
    return (new_adj_vertices_count,);
}

// @notice internal function to build the graph recursively
// @dev
// @param pairs_len : The length of the pairs edges_len
// @param edges : The edges array
// @param graph_len : The length of the graph
// @param graph : The graph
// @param neighbors : The array of neighbors
func build_undirected_graph_from_edges_internal(
    edges_len: felt, edges: Edge*, graph_len: felt, graph: Vertex*, adj_vertices_count: felt*
) -> (graph_len: felt, graph: Vertex*, adj_vertices_count: felt*) {
    alloc_locals;

    if (edges_len == 0) {
        return (graph_len, graph, adj_vertices_count);
    }

    let (graph_len, adj_vertices_count) = Graph.add_edge(
        graph, graph_len, adj_vertices_count, [edges]
    );

    let (graph_len, adj_vertices_count) = Graph.add_edge(
        graph,
        graph_len,
        adj_vertices_count,
        Edge([edges].dst_identifier, [edges].src_identifier, [edges].weight),
    );

    return build_undirected_graph_from_edges_internal(
        edges_len - 1, edges + Edge.SIZE, graph_len, graph, adj_vertices_count
    );
}

// @notice internal function to build the graph recursively
// @dev
// @param pairs_len : The length of the pairs array
// @param pairs : The pairs array
// @param graph_len : The length of the graph
// @param graph : The graph
// @param neighbors : The array of neighbors
func build_directed_graph_from_edges_internal(
    edges_len: felt, edges: Edge*, graph_len: felt, graph: Vertex*, adj_vertices_count: felt*
) -> (graph_len: felt, graph: Vertex*, adj_vertices_count: felt*) {
    alloc_locals;

    if (edges_len == 0) {
        return (graph_len, graph, adj_vertices_count);
    }

    let (graph_len, adj_vertices_count) = Graph.add_edge(
        graph, graph_len, adj_vertices_count, [edges]
    );

    return build_directed_graph_from_edges_internal(
        edges_len - 1, edges + Edge.SIZE, graph_len, graph, adj_vertices_count
    );
}
