from src.data_types.data_types import Vertex
from starkware.cairo.common.default_dict import default_dict_new, default_dict_finalize
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math_cmp import is_le, is_equal

from src.utils.array_utils import Stack, Array

from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.dict import dict_write, dict_update, dict_read

const MAX_FELT = 2 ** 251 - 1
const MAX_HOPS = 4

# @deprecated
func init_dict() -> (dict_ptr : DictAccess*):
    alloc_locals

    let (local dict_start) = default_dict_new(default_value=0)
    let dict_end = dict_start
    return (dict_end)
end

func set_array_to_max_felt(remaining_len : felt, current_index : felt*):
    if remaining_len == 0:
        return ()
    end
    assert [current_index] = MAX_FELT
    return set_array_to_max_felt(remaining_len - 1, current_index + 1)
end

# @notice startes a Dijkstra algorith to find the shortest route from the source to the destination vertex.
# @dev only works if all weights are positive.
# @param graph_len the number of vertices in the graph
# @param graph the graph
# TODO adapt it
func init_dijkstra{range_check_ptr}(
    graph_len : felt, graph : Vertex*, adjacent_vertices_count : felt*, start_node : Vertex
) -> (saved_paths_len : felt, saved_paths : felt*):
    alloc_locals

    #
    # Data structures
    #

    let (dict_ptr : DictAccess*) = init_dict()
    # stores all of the visited vertices
    let (visited_vertices : felt*) = alloc()
    # stores the predecessor of each node. at index i you have the predecessor of graph[i]
    let (predecessors : felt*) = alloc()
    # stores the distance from origin of each node. at index i you have the distance of graph[i] from origin.
    let (distances : felt*) = alloc()

    #
    # Initial state
    #

    # Set all initial distances to MAX_FELT
    set_array_to_max_felt(graph_len, distances)
    # predecessor = max_felt means that there is no predecessor
    set_array_to_max_felt(graph_len, predecessors)
    # Set initial node distance to 0
    let (distances) = Array.update_value_at_index(graph_len, distances, start_node.index, 0)
    # Set initial node as visited : pushed in the visited vertices, updates its value in the dict.
    let (visited_vertices_len) = DijsktraUtils.set_visited(start_node.index, 0, visited_vertices)
    let (distances) = DijsktraUtils.set_distance(start_node.index, graph_len, distances, 0)

    let (predecessors, distances) = visit_grey_vertices{
        dict_ptr, range_check_ptr, graph_len, graph, adjacent_vertices_count
    }(predecessors, visited_vertices_len, visited_vertices)

    # stores the token addresses instead of the indexes in the path
    let (token_paths : felt*) = alloc()
    get_tokens_from_path(
        graph_len, graph, saved_paths_len, saved_paths, current_index=0, token_paths=token_paths
    )
    return (saved_paths_len, token_paths)
end

func visit_grey_vertices{
    dict_ptr : DictAccess*, range_check_ptr, graph_len, graph, adjacent_vertices_count
}(predecessors : felt*, visited_vertices_len : felt, visited_vertices : felt) -> (
    predecessors : felt*, distances : felt*
):
    alloc_locals

    let (closest_distance, closest_vertex_index) = DijsktraUtils.get_closest_visited_vertex(
        graph_len, distances, visited_vertices_len, visited_vertices, MAX_FELT, MAX_FELT
    )

    if closest_distance == MAX_FELT:
        return ()  # done, it means that there are no more visited vertices to pending
    end

    # TODO loop over successors
    let current_vertex = graph[closest_vertex_index]
    let nb_adj_vertices = adjacent_vertices_count[closest_vertex_index]

    let (predecessors, distances) = visit_successors{
        dict_ptr=dict_ptr,
        graph_len=graph_len,
        graph=graph,
        adjacent_vertices_count=adjacent_vertices_count,
    }(
        current_node=current_node,
        successors_len=nb_adj_vertices,
        predecessors=predecessors,
        distances=distances,
    )

    let (visited_vertices_len, visited_vertices) = DijkstraUtils.set_finished(
        current_vertex.index, visited_vertices_len, visited_vertices
    )
    return visit_grey_vertices(predecessors, distances, visited_vertices_len, visited_vertices)
end

# func visit_loop(stop:felt,index:felt):
#     if index == stop:
#         return ()
#     end
#     return()
# end

func visit_successors{
    dict_ptr : DictAccess*, range_check_ptr, graph_len, graph, adjacent_vertices_count
}(current_node : Vertex, successors_len : felt, predecessors : felt*, distances : felt*) -> (
    predecessors : felt*, distances : felt*
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

    # No more successors -> stop current successor loop
    if successors_len == 0:
        # dict_write{dict_ptr=dict_ptr}(key=current_node.index, new_value=2)
        # explore previous_node's next_successor
        return (predecessors, distances)
    end

    # We release the current edge if s[j] is not finished
    let successor = current_node.adjacent_vertices[successors_len - 1]
    let (is_successor_finished) = DijkstraUtils.is_finished(successor)

    # Visit next node if the successor is finished
    if is_successor_finished == 1:
        return visit_successors(current_node, successors_len - 1, predecessors, distances)
    end

    # todo relax current edge

    let (is_not_visited) = DijsktraUtils.is_not_visited(successor)

    if is_not_visited == 1:
        let (visited_vertices_len) = DijsktraUtils.set_visited(
            successor.index, visited_vertices_len, visited_vertices
        )
        tempvar visited_vertices_len = visited_vertices_len
    else:
        tempvar visited_vertices_len = visited_vertices_len
    end

    return visit_successors(current_node, successors_len - 1, predecessors, distances)
end

func relax_edge()->(predecessors:felt*,distances:felt*):
    alloc_locals
    
    return (predecessors,distances)
end

# @notice Return with an array composed by (path_len,path) subarrays identified by token addresses.
func get_tokens_from_path(
    graph_len : felt,
    graph : Vertex*,
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
    graph_len : felt, graph : Vertex*, saved_paths : felt*, i : felt, j : felt, token_paths : felt*
):
    if i == j:
        return ()
    end
    let index_in_graph = saved_paths[i]
    assert [token_paths] = graph[index_in_graph].identifier
    return parse_array_segment(graph_len, graph, saved_paths, i + 1, j, token_paths + 1)
end

namespace DijsktraUtils:
    func get_state{dict_ptr}(vertex_index : felt):
        let (state) = dict_read{dict_ptr=dict_ptr}(key=vertex_index)
        return (state)
    end

    func is_not_visited{dict_ptr}(vertex) -> (visited : felt):
        let (state) = dict_read{dict_ptr=dict_ptr}(key=vertex.index)
        if state == 0:
            return (1)
        end
        return (0)
    end

    func set_visited{dict_ptr}(
        vertex_index : felt, visited_vertices_len : felt, visited_vertices : felt*
    ) -> (visited_vertices_len : felt):
        dict_write{dict_ptr=dict_ptr}(key=vertex_index, new_value=1)
        assert visited_vertices[visited_vertices_len] = vertex_index
        return (visited_vertices_len + 1)
    end

    func is_visited{dict_ptr}(vertex) -> (visited : felt):
        let (state) = dict_read{dict_ptr=dict_ptr}(key=vertex.index)
        if state - 1 == 0:
            return (1)
        end
        return (0)
    end

    func set_finished{dict_ptr}(
        vertex_index : felt, visited_vertices_len : felt, visited_vertices : felt*
    ) -> (visited_vertices_len : felt, visited_vertices : felt*):
        dict_write{dict_ptr=dict_ptr}(key=current_node.index, new_value=2)
        let (index_to_remove) = Array.get_value_index(
            visited_vertices_len, visited_vertices, current_node.index
        )
        let (visited_vertices_len, visited_vertices) = Array.remove_value_at_index(
            visited_vertices_len, visited_vertices, index_to_remove
        )
        return (visited_vertices_len, visited_vertices)
    end

    func is_finished{dict_ptr}(vertex) -> (finished : felt):
        let (state) = dict_read{dict_ptr=dict_ptr}(key=vertex.index)
        if state - 2 == 0:
            return (1)
        end
        return (0)
    end

    func set_distance{dict_ptr}(
        vertex_index : felt, distances_len : felt, distances : felt*, current_distance
    ) -> (new_distances : felt*):
        let (new_distances) = Array.set_value_at_index(
            distances_len, distances, vertex_index, current_distance
        )
        return (new_distances)
    end

    # Returns the distance of index of the closest vertex
    # TODO test
    func get_closest_visited_vertex(
        distances_len : felt,
        distances : felt*,
        visited_vertices_len : felt,
        visited_vertices : felt*,
        closest_distance : felt,
        closest_vertex : felt,
    ) -> (closest_distance : felt, closest_vertex_index : felt):
        if visited_vertices_len == 0:
            return (closest_distance, closest_vertex)
        end
        let current_vertex_index = [visited_vertices]
        let current_distance = distances[current_vertex_index]

        let (is_new_distance_better) = is_le(current_distance, closest_distance)
        if is_new_distance_better == 1:
            tempvar closest_distance = current_distance
            tempvar closest_vertex = current_vertex_index
        end

        return get_closest_visited_vertex(
            distances_len,
            distances,
            visited_vertices_len,
            visited_vertices,
            closest_distance,
            closest_vertex,
        )
    end
end
