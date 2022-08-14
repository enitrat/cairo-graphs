%lang starknet
# from cairo_graphs.graph.graph import build_graph
from starkware.cairo.common.alloc import alloc

from cairo_graphs.graph.graph import Graph
from cairo_graphs.data_types.data_types import Edge
from cairo_graphs.graph.dijkstra import Dijkstra
from cairo_graphs.data_types.data_types import Vertex

func before_undirected_weighted() -> (
    graph_len : felt, graph : Vertex*, adj_vertices_count : felt*
):
    alloc_locals
    let input_data : Edge* = alloc()
    assert input_data[0] = Edge(1, 2, 1)
    assert input_data[1] = Edge(1, 3, 3)
    assert input_data[2] = Edge(1, 4, 4)
    assert input_data[3] = Edge(2, 3, 1)
    assert input_data[4] = Edge(3, 4, 1)
    assert input_data[5] = Edge(4, 5, 1)
    assert input_data[6] = Edge(5, 6, 1)
    assert input_data[7] = Edge(5, 8, 3)
    assert input_data[8] = Edge(6, 7, 1)
    assert input_data[9] = Edge(7, 8, 7)
    assert input_data[10] = Edge(8, 9, 1)
    assert input_data[11] = Edge(12, 9, 1)

    let (graph_len, graph, adj_vertices_count) = Graph.build_undirected_graph_from_edges(
        12, input_data
    )
    return (graph_len, graph, adj_vertices_count)
end

func before_directed_weighted() -> (graph_len : felt, graph : Vertex*, adj_vertices_count : felt*):
    alloc_locals
    let input_data : Edge* = alloc()

    # 0, 0, 3, 0, 0, 3, 0, 0, 0, 0,
    # 0, 0, 0, 1, 0, 0, 0, 0, 0, 0,
    # 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    # 0, 1, 0, 0, 0, 0, 3, 0, 1, 0,
    # 3, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    # 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    # 1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    # 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
    # 0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
    # 0, 0, 0, 0, 0, 3, 1, 0, 0, 0,
    assert input_data[0] = Edge(1, 3, 3)
    assert input_data[1] = Edge(1, 6, 3)
    assert input_data[2] = Edge(3, 2, 2)
    assert input_data[3] = Edge(2, 4, 1)
    assert input_data[4] = Edge(4, 7, 3)
    assert input_data[5] = Edge(4, 9, 1)
    assert input_data[6] = Edge(5, 1, 3)
    assert input_data[7] = Edge(7, 1, 1)
    assert input_data[8] = Edge(8, 12, 1)
    assert input_data[9] = Edge(9, 5, 1)
    assert input_data[10] = Edge(12, 7, 1)

    let (graph_len, graph, adj_vertices_count) = Graph.build_directed_graph_from_edges(
        11, input_data
    )
    return (graph_len, graph, adj_vertices_count)
end

@external
func test_dijkstra_undirected_weighted{range_check_ptr}():
    alloc_locals
    let (graph_len, graph, adj_vertices_count) = before_undirected_weighted()

    # Test 1 : from 1 to 9

    let (path_len, path, distance) = Dijkstra.shortest_path(
        graph_len, graph, adj_vertices_count, start_vertex_id=1, end_vertex_id=9
    )

    assert path_len = 7
    assert distance = 8
    assert path[0] = 1
    assert path[1] = 2
    assert path[2] = 3
    assert path[3] = 4
    assert path[4] = 5
    assert path[5] = 8
    assert path[6] = 9

    # Test 1 : from 8 to 7

    let (path_len, path, distance) = Dijkstra.shortest_path(
        graph_len, graph, adj_vertices_count, start_vertex_id=8, end_vertex_id=7
    )

    assert path_len = 4
    assert distance = 5
    assert path[0] = 8
    assert path[1] = 5
    assert path[2] = 6
    assert path[3] = 7
    return ()
end

@external
func test_dijkstra_directed_weighted{range_check_ptr}():
    alloc_locals
    let (graph_len, local graph, adj_vertices_count) = before_directed_weighted()

    # Test 1 : from 1 to 5

    let (path_len, path, distance) = Dijkstra.shortest_path(
        graph_len, graph, adj_vertices_count, start_vertex_id=1, end_vertex_id=5
    )

    assert path_len = 6
    assert distance = 8
    assert path[0] = 1
    assert path[1] = 3
    assert path[2] = 2
    assert path[3] = 4
    assert path[4] = 9
    assert path[5] = 5

    # Test 2 : from 5 to 1 is different than 1 to 5
    let (path_len, path, distance) = Dijkstra.shortest_path(
        graph_len, graph, adj_vertices_count, start_vertex_id=5, end_vertex_id=1
    )

    assert path_len = 2
    assert distance = 3
    assert path[0] = 5
    assert path[1] = 1

    # Test 3 : from 1 to 12 is unreachable
    let (path_len, path, distance) = Dijkstra.shortest_path(
        graph_len, graph, adj_vertices_count, start_vertex_id=1, end_vertex_id=12
    )

    assert path_len = 0
    assert distance = 2 ** 251 - 1

    # Test 3 : from 12 to 1 is reachable
    let (path_len, path, distance) = Dijkstra.shortest_path(
        graph_len, graph, adj_vertices_count, start_vertex_id=12, end_vertex_id=1
    )

    assert path_len = 3
    assert distance = 2
    assert path[0] = 12
    assert path[1] = 7
    assert path[2] = 1
    return ()
end
