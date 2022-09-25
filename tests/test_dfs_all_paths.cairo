%lang starknet

from starkware.cairo.common.alloc import alloc

from cairo_graphs.graph.graph import GraphMethods
from cairo_graphs.data_types.data_types import Edge, Vertex
from cairo_graphs.graph.dfs_all_paths import init_dfs

const TOKEN_A = 123;
const TOKEN_B = 456;
const TOKEN_C = 990;
const TOKEN_D = 982;

@external
func test_dfs{range_check_ptr}() {
    let edges: Edge* = alloc();
    assert edges[0] = Edge(TOKEN_A, TOKEN_B, 1);
    assert edges[1] = Edge(TOKEN_A, TOKEN_C, 1);
    assert edges[2] = Edge(TOKEN_B, TOKEN_C, 1);

    let graph = GraphMethods.build_undirected_graph_from_edges(3, edges);
    assert graph.length = 3;

    // graph is [vertex_a,vertex_b,noce_c]
    // neighbors : [2,2,2]
    // we run dfs like this : vertex_a -> vertex_c -> vertex_b => save path
    // then we pop back to vertex_a and find vertex_a -> vertex_b => save_path
    // so we have 2 possible paths.
    // The length of the saved_paths array is : 1(length of path_1) + path_1_len + 1(length of path_2) + path_2_len = 1+3+2+1 = 7
    let (saved_paths_len, saved_paths) = init_dfs(graph, TOKEN_A, TOKEN_B, 4);
    // %{
    //     print(ids.saved_paths_len)
    //     for i in range(ids.saved_paths_len):
    //         print(memory[ids.saved_paths+i])
    // %}
    assert saved_paths_len = 7;
    assert saved_paths[0] = 3;  // path 1 length
    assert saved_paths[4] = 2;  // path 2 length
    assert saved_paths[1] = TOKEN_A;
    assert saved_paths[2] = TOKEN_C;
    assert saved_paths[3] = TOKEN_B;
    assert saved_paths[5] = TOKEN_A;
    assert saved_paths[6] = TOKEN_B;

    return ();
}

@external
func test_dfs_2{range_check_ptr}() {
    let edges: Edge* = alloc();
    assert edges[0] = Edge(TOKEN_A, TOKEN_B, 1);
    assert edges[1] = Edge(TOKEN_A, TOKEN_C, 1);
    assert edges[2] = Edge(TOKEN_B, TOKEN_C, 1);
    assert edges[3] = Edge(TOKEN_D, TOKEN_C, 1);
    assert edges[4] = Edge(TOKEN_D, TOKEN_B, 1);
    // graph is [vertex_a,vertex_b,noce_c,vertex_d]
    // neighbors : [2,3,3,2]
    // we want all paths from TOKEN_A to TOKEN_C
    // we run dfs like this : vertex_a -> vertex_c => save path
    // then we pop back to vertex_a and find vertex_a -> vertex_b -> vertex_d -> vertex_c => save_path
    // then we pop back to vertex_b and find vertex_a -> vertex_b -> vertex_c => save_path
    // so we have 3 possible paths.
    // The length of the saved_paths array is 1 + 2 + 1 + 4 + 1 + 3 = 12

    let graph = GraphMethods.build_undirected_graph_from_edges(5, edges);

    let (saved_paths_len, saved_paths) = init_dfs(graph, TOKEN_A, TOKEN_C, 4);
    // %{
    //     print(ids.saved_paths_len)
    //     for i in range(ids.saved_paths_len):
    //         print(memory[ids.saved_paths+i])
    // %}
    assert saved_paths_len = 12;
    assert saved_paths[0] = 2;  // path 1 length
    assert saved_paths[3] = 4;  // path 2 length
    assert saved_paths[8] = 3;  // path 3 length
    assert saved_paths[1] = TOKEN_A;
    assert saved_paths[2] = TOKEN_C;
    assert saved_paths[4] = TOKEN_A;
    assert saved_paths[5] = TOKEN_B;
    assert saved_paths[6] = TOKEN_D;
    assert saved_paths[7] = TOKEN_C;
    assert saved_paths[9] = TOKEN_A;
    assert saved_paths[10] = TOKEN_B;
    assert saved_paths[11] = TOKEN_C;

    return ();
}
