%lang starknet
from starknet.graph.graph import build_graph
from starknet.graph.dfs_search import init_dfs

from starknet.data_types.data_types import Pair, Node
from starkware.cairo.common.alloc import alloc

const TOKEN_A = 123
const TOKEN_B = 456
const TOKEN_C = 990
const TOKEN_D = 982

# works, 2 ways
@external
func test_dfs{range_check_ptr}():
    let pairs : Pair* = alloc()
    assert pairs[0] = Pair(TOKEN_A, TOKEN_B)
    assert pairs[1] = Pair(TOKEN_A, TOKEN_C)
    assert pairs[2] = Pair(TOKEN_B, TOKEN_C)

    # let expected_paths: felt* = alloc()
    # assert expected_paths[0] = Pair(TOKEN_A, TOKEN_B)

    let (graph_len, graph, neighbors) = build_graph(pairs_len=3, pairs=pairs)

    # graph is [node_a,node_b,noce_c]
    # neighbors : [2,2,2]
    # we run dfs like this : node_a -> node_c -> node_b => save path
    # then we pop back to node_a and find node_a -> node_b => save_path
    # so we have 2 possible paths.
    # The length of the saved_paths array is : 1(length of path_1) + path_1_len + 1(length of path_2) + path_2_len = 1+3+2+1 = 7
    let node_a = graph[0]
    let node_b = graph[1]
    let (saved_paths_len, saved_paths) = init_dfs(graph_len, graph, neighbors, node_a, node_b, 4)
    # %{
    #     print(ids.saved_paths_len)
    #     for i in range(ids.saved_paths_len):
    #         print(memory[ids.saved_paths+i])
    # %}
    assert saved_paths_len = 7
    assert saved_paths[0] = 3  # path 1 length
    assert saved_paths[4] = 2  # path 2 length
    assert saved_paths[1] = TOKEN_A
    assert saved_paths[2] = TOKEN_C
    assert saved_paths[3] = TOKEN_B
    assert saved_paths[5] = TOKEN_A
    assert saved_paths[6] = TOKEN_B

    return ()
end

# works, 3 ways
@external
func test_dfs_2{range_check_ptr}():
    let pairs : Pair* = alloc()
    assert pairs[0] = Pair(TOKEN_A, TOKEN_B)
    assert pairs[1] = Pair(TOKEN_A, TOKEN_C)
    assert pairs[2] = Pair(TOKEN_B, TOKEN_C)
    assert pairs[3] = Pair(TOKEN_D, TOKEN_C)
    assert pairs[4] = Pair(TOKEN_D, TOKEN_B)
    # graph is [node_a,node_b,noce_c,node_d]
    # neighbors : [2,3,3,2]
    # we want all paths from TOKEN_A to TOKEN_C
    # we run dfs like this : node_a -> node_c => save path
    # then we pop back to node_a and find node_a -> node_b -> node_d -> node_c => save_path
    # then we pop back to node_b and find node_a -> node_b -> node_c => save_path
    # so we have 3 possible paths.
    # The length of the saved_paths array is 1 + 2 + 1 + 4 + 1 + 3 = 12

    let (graph_len, graph, neighbors) = build_graph(pairs_len=5, pairs=pairs)

    let node_a = graph[0]
    let node_c = graph[2]
    let (saved_paths_len, saved_paths) = init_dfs(graph_len, graph, neighbors, node_a, node_c, 4)
    # %{
    #     print(ids.saved_paths_len)
    #     for i in range(ids.saved_paths_len):
    #         print(memory[ids.saved_paths+i])
    # %}
    assert saved_paths_len = 12
    assert saved_paths[0] = 2  # path 1 length
    assert saved_paths[3] = 4  # path 2 length
    assert saved_paths[8] = 3  # path 3 length
    assert saved_paths[1] = TOKEN_A
    assert saved_paths[2] = TOKEN_C
    assert saved_paths[4] = TOKEN_A
    assert saved_paths[5] = TOKEN_B
    assert saved_paths[6] = TOKEN_D
    assert saved_paths[7] = TOKEN_C
    assert saved_paths[9] = TOKEN_A
    assert saved_paths[10] = TOKEN_B
    assert saved_paths[11] = TOKEN_C

    return ()
end
