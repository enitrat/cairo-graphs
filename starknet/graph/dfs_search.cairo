from starknet.data_types.data_types import Node
from starkware.cairo.common.default_dict import default_dict_new, default_dict_finalize
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math_cmp import is_le

from starknet.utils.array_utils import Stack

from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.dict import dict_write, dict_update, dict_read

const MAX_FELT = 2 ** 251 - 1
const MAX_HOPS = 4

func init_dict() -> (dict_ptr : DictAccess*):
    alloc_locals

    let (local dict_start) = default_dict_new(default_value=0)
    let dict_end = dict_start
    return (dict_end)
end

func init_dfs{range_check_ptr}(
    graph_len : felt,
    graph : Node*,
    neighbors : felt*,
    start_node : Node,
    destination_node : Node,
    max_hops : felt,
) -> (saved_paths_len : felt, saved_paths : felt*):
    alloc_locals
    let (dict_ptr : DictAccess*) = init_dict()
    let (saved_paths : felt*) = alloc()
    let (current_path : felt*) = alloc()
    # current_path[0] = start_node.index

    let (saved_paths_len, _, _) = DFS_rec{dict_ptr=dict_ptr}(
        graph_len=graph_len,
        graph=graph,
        neighbors=neighbors,
        current_node=start_node,
        destination_node=destination_node,
        max_hops=max_hops,
        current_path_len=0,
        current_path=current_path,
        saved_paths_len=0,
        saved_paths=saved_paths,
    )

    # stores the token addresses instead of the indexes in the path
    let (token_paths : felt*) = alloc()
    get_tokens_from_path(
        graph_len, graph, saved_paths_len, saved_paths, current_index=0, token_paths=token_paths
    )
    return (saved_paths_len, token_paths)
end

func DFS_rec{dict_ptr : DictAccess*, range_check_ptr}(
    graph_len : felt,
    graph : Node*,
    neighbors : felt*,
    current_node : Node,
    destination_node : Node,
    max_hops : felt,
    current_path_len : felt,
    current_path : felt*,
    saved_paths_len : felt,
    saved_paths : felt*,
) -> (saved_paths_len : felt, current_path_len : felt, current_path : felt*):
    alloc_locals
    dict_write{dict_ptr=dict_ptr}(key=current_node.index, new_value=1)

    let (current_path_len, current_path) = Stack.put(
        current_path_len, current_path, current_node.index
    )

    # When we return from this recursive function, we want to:
    # 1. Update the saved_paths array with the current path if it is a valid path. Since we're working with a pointer
    # to the saved_paths array that never changes, we just need to update its length
    # 2. Update the current_path array, after trimming the last elem.
    # 3. Update the current_path_len, after trimming the last elem.
    # 5. Incrementing the remaining_hops since we're going up in the recursion stack

    if current_node.identifier == destination_node.identifier:
        # store current path length inside saved_paths
        assert saved_paths[saved_paths_len] = current_path_len
        let (saved_paths_len) = save_path(
            current_path_len, current_path, saved_paths_len + 1, saved_paths
        )
        tempvar current_path_len = current_path_len
        tempvar current_path = current_path
        tempvar saved_paths_len = saved_paths_len
    else:
        tempvar current_path_len = current_path_len
        tempvar current_path = current_path
        tempvar saved_paths_len = saved_paths_len
    end

    let (saved_paths_len, current_path_len, current_path, _, _) = visit_successors{
        dict_ptr=dict_ptr
    }(
        graph_len=graph_len,
        graph=graph,
        neighbors=neighbors,
        current_node=current_node,
        destination_node=destination_node,
        remaining_hops=max_hops,
        successors_len=neighbors[current_node.index],
        current_path_len=current_path_len,
        current_path=current_path,
        saved_paths_len=saved_paths_len,
        saved_paths=saved_paths,
    )
    return (saved_paths_len, current_path_len, current_path)
end

func visit_successors{dict_ptr : DictAccess*, range_check_ptr}(
    graph_len : felt,
    graph : Node*,
    neighbors : felt*,
    current_node : Node,
    destination_node : Node,
    remaining_hops : felt,
    successors_len : felt,
    current_path_len : felt,
    current_path : felt*,
    saved_paths_len : felt,
    saved_paths : felt*,
) -> (
    saved_paths_len : felt,
    current_path_len : felt,
    current_path : felt*,
    successors_len : felt,
    remaining_hops : felt,
):
    alloc_locals

    # When we return from this recursive function, we want to:
    # 1. Update the saved_paths array with the current path if it is a valid path. Since we're working with a pointer
    # to the saved_paths array that never changes, we just need to update its length
    # 2. Update the current_path array, after trimming the last elem.
    # 3. Update the current_path_len, after trimming the last elem.
    # 4. Update the successors_len
    # 5. Incrementing the remaining_hops since we're going up in the stack

    #
    # Return conditions
    #

    # No more successors
    if successors_len == 0:
        # dict_write{dict_ptr=dict_ptr}(key=current_node.index, new_value=2)
        let (current_path_len, current_path, _) = Stack.pop(current_path_len, current_path)
        # explore previous_node's next_successor
        return (saved_paths_len, current_path_len, current_path, successors_len - 1, remaining_hops)
    end

    # Hops greater than limit
    if remaining_hops == 0:
        let (current_path_len, current_path, _) = Stack.pop(current_path_len, current_path)
        # explore previous_node's next_successor
        return (saved_paths_len, current_path_len, current_path, successors_len - 1, remaining_hops)
    end

    # Already visited successor, avoid cycles
    let successor = current_node.neighbor_nodes[successors_len - 1]
    let successor_index = successor.index
    let (is_already_visited) = is_in_path(current_path_len, current_path, successor_index)
    if is_already_visited == 1:
        return visit_successors(
            graph_len=graph_len,
            graph=graph,
            neighbors=neighbors,
            current_node=current_node,
            destination_node=destination_node,
            remaining_hops=remaining_hops,
            successors_len=successors_len - 1,
            current_path_len=current_path_len,
            current_path=current_path,
            saved_paths_len=saved_paths_len,
            saved_paths=saved_paths,
        )
    end

    #
    # Go deeper in the recursion (do DFSrec from current node)
    #

    let (successor_visit_state) = dict_read{dict_ptr=dict_ptr}(key=successor_index)

    local saved_paths_len_updated : felt
    local current_path_updated : felt*
    local current_path_len_updated : felt

    let (is_state_1_or_0) = is_le(successor_visit_state, 1)
    if is_state_1_or_0 == 1:
        # assert current_path[current_path_len] = successor_index
        let (saved_paths_len, current_path_len, current_path) = DFS_rec(
            graph_len=graph_len,
            graph=graph,
            neighbors=neighbors,
            current_node=successor,
            destination_node=destination_node,
            max_hops=remaining_hops - 1,
            current_path_len=current_path_len,
            current_path=current_path,
            saved_paths_len=saved_paths_len,
            saved_paths=saved_paths,
        )
        saved_paths_len_updated = saved_paths_len
        current_path_len_updated = current_path_len
        current_path_updated = current_path
        tempvar dict_ptr = dict_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        saved_paths_len_updated = saved_paths_len
        current_path_len_updated = current_path_len
        current_path_updated = current_path
        tempvar dict_ptr = dict_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    #
    # Visit next successor (decrement successors_len)
    #

    return visit_successors(
        graph_len=graph_len,
        graph=graph,
        neighbors=neighbors,
        current_node=current_node,
        destination_node=destination_node,
        remaining_hops=remaining_hops,
        successors_len=successors_len - 1,
        current_path_len=current_path_len_updated,
        current_path=current_path_updated,
        saved_paths_len=saved_paths_len_updated,
        saved_paths=saved_paths,
    )

end

# @notice returns the index of the node in the graph
# @returns -1 if it's not in the graph
# @returns array index otherwise
func is_in_path(current_path_len : felt, current_path : felt*, index : felt) -> (boolean : felt):
    if current_path_len == 0:
        return (0)
    end

    let current_index : felt = [current_path]
    if current_index == index:
        return (1)
    end

    return is_in_path(current_path_len - 1, current_path + 1, index)
end

func save_path(
    current_path_len : felt, current_path : felt*, saved_paths_len : felt, saved_paths : felt*
) -> (new_saved_paths_len):
    let new_saved_paths_len = saved_paths_len + current_path_len
    memcpy(saved_paths + saved_paths_len, current_path, current_path_len)
    return (new_saved_paths_len)
end

# @notice Return with an array composed by (path_len,path) subarrays identified by token addresses.
func get_tokens_from_path(
    graph_len : felt,
    graph : Node*,
    saved_paths_len : felt,
    saved_paths : felt*,
    current_index : felt,
    token_paths : felt*,
):
    if current_index == saved_paths_len:
        return ()
    end
    let subarray_length = saved_paths[current_index]
    assert [token_paths] = subarray_length

    parse_array_segment(
        graph_len=graph_len,
        graph=graph,
        saved_paths=saved_paths,
        i=current_index + 1,
        j=current_index + 1 + subarray_length,
        token_paths=token_paths + 1,
    )
    return get_tokens_from_path(
        graph_len=graph_len,
        graph=graph,
        saved_paths_len=saved_paths_len,
        saved_paths=saved_paths,
        current_index=current_index + subarray_length + 1,
        token_paths=token_paths + 1 + subarray_length,
    )
end

# @notice parses the token addresses for all tokens between indexes i and j in the indexes array
func parse_array_segment(
    graph_len : felt, graph : Node*, saved_paths : felt*, i : felt, j : felt, token_paths : felt*
):
    if i == j:
        return ()
    end
    let index_in_graph = saved_paths[i]
    assert [token_paths] = graph[index_in_graph].identifier
    return parse_array_segment(graph_len, graph, saved_paths, i + 1, j, token_paths + 1)
end
