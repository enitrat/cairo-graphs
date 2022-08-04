from src.cairo_graphs.data_types.data_types import Edge, Vertex
from src.cairo_graphs.graph.graph import Graph

# @notice internal function to build the graph recursively
# @dev
# @param pairs_len : The length of the pairs edges_len
# @param edges : The edges array
# @param graph_len : The length of the graph
# @param graph : The graph
# @param neighbors : The array of neighbors
func build_undirected_graph_from_edges(
    edges_len : felt, edges : Edge*, graph_len : felt, graph : Vertex*, adj_vertices_count : felt*
) -> (graph_len : felt, adj_vertices_count : felt*):
    alloc_locals

    if edges_len == 0:
        return (graph_len, adj_vertices_count)
    end

    let (graph_len, adj_vertices_count) = Graph.add_edge(
        graph, graph_len, adj_vertices_count, [edges]
    )

    let (graph_len, adj_vertices_count) = Graph.add_edge(
        graph,
        graph_len,
        adj_vertices_count,
        Edge([edges].dst_identifier, [edges].src_identifier, [edges].weight),
    )

    return build_undirected_graph_from_edges(
        edges_len - 1, edges + Edge.SIZE, graph_len, graph, adj_vertices_count
    )
end

# @notice internal function to build the graph recursively
# @dev
# @param pairs_len : The length of the pairs array
# @param pairs : The pairs array
# @param graph_len : The length of the graph
# @param graph : The graph
# @param neighbors : The array of neighbors
func build_directed_graph_from_edges(
    edges_len : felt, edges : Edge*, graph_len : felt, graph : Vertex*, adj_vertices_count : felt*
) -> (graph_len : felt, adj_vertices_count : felt*):
    alloc_locals

    if edges_len == 0:
        return (graph_len, adj_vertices_count)
    end

    let (graph_len, adj_vertices_count) = Graph.add_edge(
        graph, graph_len, adj_vertices_count, [edges]
    )

    return build_directed_graph_from_edges(
        edges_len - 1, edges + Edge.SIZE, graph_len, graph, adj_vertices_count
    )
end
