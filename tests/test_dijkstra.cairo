%lang starknet
# from src.graph.graph import build_graph
from starkware.cairo.common.alloc import alloc

from src.graph.dijkstra import init_dijkstra, shortest_path
from src.data_types.data_types import Vertex

from tests.utils import Pair, build_graph_bidirected

const TOKEN_A = 123
const TOKEN_B = 456
const TOKEN_C = 990
const TOKEN_D = 982

func before_each_1() -> (graph_len : felt, graph : Vertex*, adj_vertices_count : felt*):
    alloc_locals
    let (local graph : Vertex*) = alloc()
    let (local adj_vertices_count : felt*) = alloc()
    let input_data : Pair* = alloc()
    assert input_data[0] = Pair(TOKEN_A, TOKEN_B)
    assert input_data[1] = Pair(TOKEN_A, TOKEN_C)
    assert input_data[2] = Pair(TOKEN_B, TOKEN_C)

    # let expected_paths: felt* = alloc()
    # assert expected_paths[0] = Pair(TOKEN_A, TOKEN_B)

    let (local graph_len, adj_vertices_count) = build_graph_bidirected(
        3, input_data, 0, graph, adj_vertices_count
    )

    return (graph_len, graph, adj_vertices_count)
end

func before_each_2() -> (graph_len : felt, graph : Vertex*, adj_vertices_count : felt*):
    alloc_locals
    let (local graph : Vertex*) = alloc()
    let (local adj_vertices_count : felt*) = alloc()
    let input_data : Pair* = alloc()
    assert input_data[0] = Pair(TOKEN_A, TOKEN_B)
    assert input_data[1] = Pair(TOKEN_A, TOKEN_C)
    assert input_data[2] = Pair(TOKEN_B, TOKEN_C)
    assert input_data[3] = Pair(TOKEN_D, TOKEN_C)
    assert input_data[4] = Pair(TOKEN_D, TOKEN_B)

    let (graph_len, adj_vertices_count) = build_graph_bidirected(
        5, input_data, 0, graph, adj_vertices_count
    )
    return (graph_len, graph, adj_vertices_count)
end

# works, 2 ways
@external
func test_dijkstra{range_check_ptr}():
    alloc_locals
    let (graph_len, graph, adj_vertices_count) = before_each_1()

    # graph is [node_a,node_b,noce_c]
    # neighbors : [2,2,2]
    let node_a = graph[0]
    let node_b = graph[1]
    let (graph_len, predecessors, distances) = init_dijkstra(
        graph_len, graph, adj_vertices_count, node_a
    )

    # %{
    #     print("returned : ")
    #     print(ids.graph_len)
    #     for i in range(ids.graph_len):
    #        print(f"Predecessor : {memory[ids.predecessors+i]}-- Distance : {memory[ids.distances+i]}")
    # %}

    return ()
end

# works, 2 ways
@external
func test_shortest_path_1{range_check_ptr}():
    alloc_locals
    let (graph_len, graph, adj_vertices_count) = before_each_1()

    # graph is [node_a,node_b,noce_c]
    # neighbors : [2,2,2]
    let node_a = graph[0]
    let node_b = graph[1]

    let (path_len, path, distance) = shortest_path(
        graph_len, graph, adj_vertices_count, node_a, node_b
    )

    %{
        print(f"Total distance : {ids.distance} ")    
        print(f"Total steps : {ids.path_len}")
        for i in range(ids.path_len):
           print(f" step n {i} : {memory[ids.path+i]}")
    %}

    return ()
end

# # works, 3 ways
@external
func test_dijkstra_2{range_check_ptr}():
    alloc_locals
    let (graph_len, graph, adj_vertices_count) = before_each_2()

    let node_a = graph[0]
    let node_d = graph[3]
    let (graph_len, predecessors, distances) = init_dijkstra(
        graph_len, graph, adj_vertices_count, node_a
    )
    return ()
end

# works, 2 ways
@external
func test_shortest_path_2{range_check_ptr}():
    alloc_locals
    let (graph_len, graph, adj_vertices_count) = before_each_2()

    # graph is [node_a,node_b,noce_c]
    # neighbors : [2,2,2]
    let node_a = graph[0]
    let node_d = graph[3]

    let (path_len, path, distance) = shortest_path(
        graph_len, graph, adj_vertices_count, node_a, node_d
    )

    %{
        print(f"Total distance : {ids.distance} ")    
        print(f"Total steps : {ids.path_len}")
        for i in range(ids.path_len):
            print(f" step n {i} : {memory[ids.path+i]}")
    %}

    return ()
end

# TODO test when unreachable

struct MyStruct:
    member a : felt
    member b : felt
end
@external
func test_test():
    let (struct_array : MyStruct*) = alloc()

    # Set the first three elements.
    assert struct_array[0] = MyStruct(a=1, b=2)
    assert struct_array[1] = MyStruct(a=3, b=4)
    assert struct_array[2] = MyStruct(a=5, b=6)

    %{ print(ids.struct_array) %}
    %{ print(ids.struct_array.a) %}
    return ()
end
