from src.data_types.data_types import Edge, Vertex
from src.graph.graph import add_edge

struct Pair:
    member token_0 : felt
    member token_1 : felt
end

# @notice internal function to build the graph recursively
# @dev
# @param pairs_len : The length of the pairs array
# @param pairs : The pairs array
# @param graph_len : The length of the graph
# @param graph : The graph
# @param neighbors : The array of neighbors
func build_graph_bidirected(
    pairs_len : felt, pairs : Pair*, graph_len : felt, graph : Vertex*, adj_vertices_count : felt*
) -> (graph_len : felt, adj_vertices_count : felt*):
    alloc_locals

    if pairs_len == 0:
        return (graph_len, adj_vertices_count)
    end

    let token_0 = [pairs].token_0
    let token_1 = [pairs].token_1

    let (graph_len, adj_vertices_count) = add_edge(
        graph, graph_len, adj_vertices_count, Edge(token_0, token_1, 0)
    )

    let (graph_len, adj_vertices_count) = add_edge(
        graph, graph_len, adj_vertices_count, Edge(token_1, token_0, 0)
    )

    return build_graph_bidirected(
        pairs_len - 1, pairs + Pair.SIZE, graph_len, graph, adj_vertices_count
    )
end
