from src.data_types.data_types import Vertex
from starkware.cairo.common.default_dict import default_dict_new, default_dict_finalize
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math_cmp import is_le_felt, is_le

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
func init_dijkstra{range_check_ptr}(
    graph_len : felt, graph : Vertex*, adjacent_vertices_count : felt*, start_node : Vertex
) -> (graph_len : felt, predecessors : felt*, distances : felt*):
    alloc_locals

    #
    # Data structures
    #

    # stores all of the visited vertices being currently visited
    let (visited_vertices : felt*) = alloc()
    # stores the predecessor of each node. at index i you have the predecessor of graph[i]
    let (predecessors : felt*) = alloc()
    # stores the distance from origin of each node. at index i you have the distance of graph[i] from origin.
    let (distances : felt*) = alloc()

    #
    # Initial state
    #

    # Set all nodes to unvisited state
    let (dict_ptr : DictAccess*) = init_dict()
    # Set all initial distances to MAX_FELT
    set_array_to_max_felt(graph_len, distances)
    # predecessor = max_felt means that there is no predecessor
    set_array_to_max_felt(graph_len, predecessors)
    # Set initial node as visited : pushed in the visited vertices, updates its value in the dict.
    let (visited_vertices_len) = DijkstraUtils.set_visited{dict_ptr=dict_ptr}(
        start_node.index, 0, visited_vertices
    )
    # Set initial node distance to 0
    let (distances) = DijkstraUtils.set_distance(start_node.index, graph_len, distances, 0)

    let (predecessors, distances) = visit_grey_vertices{
        dict_ptr=dict_ptr,
        range_check_ptr=range_check_ptr,
        graph_len=graph_len,
        graph=graph,
        adjacent_vertices_count=adjacent_vertices_count,
    }(predecessors, distances, visited_vertices_len, visited_vertices)

    # # stores the token addresses instead of the indexes in the path
    # let (identifiers : felt*) = alloc()
    # let (identifiers_predecessors) = get_identifiers_from_indexes(
    #     graph, graph_len, predecessors, res=identifiers
    # )
    return (graph_len, predecessors, distances)
end

func visit_grey_vertices{
    dict_ptr : DictAccess*,
    range_check_ptr,
    graph_len,
    graph : Vertex*,
    adjacent_vertices_count : felt*,
}(
    predecessors : felt*, distances : felt*, visited_vertices_len : felt, visited_vertices : felt*
) -> (predecessors : felt*, distances : felt*):
    alloc_locals

    let (closest_distance, closest_vertex_index) = DijkstraUtils.get_closest_visited_vertex(
        graph_len, distances, visited_vertices_len, visited_vertices, MAX_FELT, MAX_FELT
    )

    if closest_distance == MAX_FELT:
        return (predecessors, distances)  # done, it means that there are no more visited vertices to pending
    end

    let current_vertex = graph[closest_vertex_index]
    let nb_adj_vertices = adjacent_vertices_count[closest_vertex_index]

    let (predecessors, distances) = visit_successors{
        dict_ptr=dict_ptr,
        graph_len=graph_len,
        graph=graph,
        adjacent_vertices_count=adjacent_vertices_count,
        visited_vertices_len=visited_vertices_len,
        visited_vertices=visited_vertices,
    }(
        current_vertex=current_vertex,
        successors_len=nb_adj_vertices,
        predecessors=predecessors,
        distances=distances,
    )

    let (visited_vertices_len, visited_vertices) = DijkstraUtils.set_finished(
        current_vertex.index, visited_vertices_len, visited_vertices
    )
    return visit_grey_vertices(predecessors, distances, visited_vertices_len, visited_vertices)
end

func visit_successors{
    dict_ptr : DictAccess*,
    range_check_ptr,
    graph_len,
    graph : Vertex*,
    adjacent_vertices_count : felt*,
    visited_vertices_len,
    visited_vertices : felt*,
}(current_vertex : Vertex, successors_len : felt, predecessors : felt*, distances : felt*) -> (
    predecessors : felt*, distances : felt*
):
    alloc_locals

    # No more successors -> stop current successor loop
    if successors_len == 0:
        return (predecessors, distances)
    end

    # We release the current edge if s[j] is not finished
    let successor_edge = current_vertex.adjacent_vertices[successors_len - 1]
    let successor = successor_edge.dst
    let weight = successor_edge.weight
    let (is_successor_finished) = DijkstraUtils.is_finished(successor.index)

    # Visit next node if the successor is finished
    if is_successor_finished == 1:
        return visit_successors(current_vertex, successors_len - 1, predecessors, distances)
    end

    # let (predecessors, distances) = relax_edge(current_vertex, successor, weight)
    relax_edge{predecessors=predecessors, distances=distances}(current_vertex, successor, weight)

    let (is_not_visited) = DijkstraUtils.is_not_visited(successor.index)

    if is_not_visited == 1:
        let (visited_vertices_len) = DijkstraUtils.set_visited(
            successor.index, visited_vertices_len, visited_vertices
        )
        tempvar dict_ptr = dict_ptr
        tempvar visited_vertices_len = visited_vertices_len
    else:
        tempvar dict_ptr = dict_ptr
        tempvar visited_vertices_len = visited_vertices_len
    end

    return visit_successors(current_vertex, successors_len - 1, predecessors, distances)
end

func relax_edge{
    dict_ptr : DictAccess*,
    graph_len : felt,
    predecessors : felt*,
    distances : felt*,
    range_check_ptr,
}(src : Vertex, dst : Vertex, weight : felt):
    alloc_locals
    let current_disctance = distances[dst.index]
    let new_distance = distances[src.index] + weight
    let (is_new_distance_better) = is_le_felt(new_distance, current_disctance)
    if is_new_distance_better == 1:
        let (distances) = DijkstraUtils.set_distance(dst.index, graph_len, distances, new_distance)
        let (predecessors) = DijkstraUtils.set_predecessor(
            dst.index, graph_len, predecessors, src.index
        )
        return ()
    end
    return ()
end

func shortest_path{range_check_ptr}(
    graph_len : felt,
    graph : Vertex*,
    adjacent_vertices_count : felt*,
    start_vertex : Vertex,
    end_vertex : Vertex,
) -> (path_len : felt, path : felt*, distance : felt):
    alloc_locals
    let (graph_len, predecessors, distances) = init_dijkstra(
        graph_len, graph, adjacent_vertices_count, start_vertex
    )

    let (shortest_path_indexes : felt*) = alloc()
    let total_distance = distances[end_vertex.index]

    # populate with end vertex first
    assert [shortest_path_indexes] = end_vertex.index
    let (shortest_path_len) = build_shortest_path{
        graph_len=graph_len, graph=graph, predecessors=predecessors, start_vertex=start_vertex
    }(
        current_vertex=end_vertex,
        shortest_path_len=1,
        shortest_path_indexes=shortest_path_indexes + 1,
    )

    let (correct_order_path) = Array.inverse(shortest_path_len, shortest_path_indexes)
    # stores the token addresses instead of the indexes in the path
    let (identifiers : felt*) = alloc()
    get_identifiers_from_indexes(graph, shortest_path_len, correct_order_path, identifiers)

    return (shortest_path_len, identifiers, total_distance)
end

func build_shortest_path{
    graph_len : felt, graph : Vertex*, predecessors : felt*, start_vertex : Vertex
}(current_vertex : Vertex, shortest_path_len : felt, shortest_path_indexes : felt*) -> (
    shortest_path_len : felt
):
    let prev_vertex_index = predecessors[current_vertex.index]
    assert [shortest_path_indexes] = prev_vertex_index
    if prev_vertex_index == start_vertex.index:
        return (shortest_path_len + 1)
    end
    return build_shortest_path(
        current_vertex=graph[prev_vertex_index],
        shortest_path_len=shortest_path_len + 1,
        shortest_path_indexes=shortest_path_indexes + 1,
    )
end

# @notice Return with an array composed by (path_len,path) subarrays identified by token addresses.
func get_identifiers_from_indexes(
    graph : Vertex*, source_array_len : felt, source_array : felt*, res : felt*
) -> (identifiers_predecessors : felt*):
    alloc_locals
    if source_array_len == 0:
        return (res)
    end
    local current_vertex_index = source_array[source_array_len - 1]
    if current_vertex_index == MAX_FELT:
        assert res[source_array_len - 1] = MAX_FELT
    else:
        assert res[source_array_len - 1] = graph[current_vertex_index].identifier
    end

    return get_identifiers_from_indexes(
        graph=graph, source_array_len=source_array_len - 1, source_array=source_array, res=res
    )
end

namespace DijkstraUtils:
    func get_state{dict_ptr : DictAccess*}(vertex_index : felt):
        let (state) = dict_read{dict_ptr=dict_ptr}(key=vertex_index)
        return (state)
    end

    func is_not_visited{dict_ptr : DictAccess*}(vertex_index : felt) -> (visited : felt):
        let (state) = dict_read{dict_ptr=dict_ptr}(key=vertex_index)
        if state == 0:
            return (1)
        end
        return (0)
    end

    func set_visited{dict_ptr : DictAccess*}(
        vertex_index : felt, visited_vertices_len : felt, visited_vertices : felt*
    ) -> (visited_vertices_len : felt):
        dict_write{dict_ptr=dict_ptr}(key=vertex_index, new_value=1)
        assert visited_vertices[visited_vertices_len] = vertex_index
        return (visited_vertices_len + 1)
    end

    func is_visited{dict_ptr : DictAccess*}(vertex) -> (visited : felt):
        let (state) = dict_read{dict_ptr=dict_ptr}(key=vertex.index)
        if state - 1 == 0:
            return (1)
        end
        return (0)
    end

    func set_finished{dict_ptr : DictAccess*}(
        vertex_index : felt, visited_vertices_len : felt, visited_vertices : felt*
    ) -> (visited_vertices_len : felt, visited_vertices : felt*):
        alloc_locals
        dict_write{dict_ptr=dict_ptr}(key=vertex_index, new_value=2)
        let (index_to_remove) = Array.get_value_index(
            visited_vertices_len, visited_vertices, vertex_index, current_index=0
        )
        let (visited_vertices_len, visited_vertices) = Array.remove_value_at_index(
            visited_vertices_len, visited_vertices, index_to_remove
        )
        return (visited_vertices_len, visited_vertices)
    end

    func is_finished{dict_ptr : DictAccess*}(vertex_index : felt) -> (finished : felt):
        let (state) = dict_read{dict_ptr=dict_ptr}(key=vertex_index)
        if state - 2 == 0:
            return (1)
        end
        return (0)
    end

    func set_distance(
        vertex_index : felt, distances_len : felt, distances : felt*, new_distance
    ) -> (new_distances : felt*):
        let (new_distances) = Array.update_value_at_index(
            distances_len, distances, vertex_index, new_distance
        )
        return (new_distances)
    end

    func set_predecessor{dict_ptr : DictAccess*}(
        vertex_index : felt,
        predecessors_len : felt,
        predecessors : felt*,
        new_predecessor_index : felt,
    ) -> (new_predecessors : felt*):
        let (new_predecessors) = Array.update_value_at_index(
            predecessors_len, predecessors, vertex_index, new_predecessor_index
        )
        return (new_predecessors)
    end

    # Returns the distance of index of the closest vertex
    # TODO test
    func get_closest_visited_vertex{range_check_ptr}(
        distances_len : felt,
        distances : felt*,
        visited_vertices_len : felt,
        visited_vertices : felt*,
        closest_distance : felt,
        closest_vertex : felt,
    ) -> (closest_distance : felt, closest_vertex_index : felt):
        alloc_locals
        if visited_vertices_len == 0:
            return (closest_distance, closest_vertex)
        end
        tempvar current_vertex_index = [visited_vertices]
        tempvar current_distance = distances[current_vertex_index]

        let (is_new_distance_better) = is_le_felt(current_distance, closest_distance)
        if is_new_distance_better == 1:
            return get_closest_visited_vertex(
                distances_len,
                distances,
                visited_vertices_len - 1,
                visited_vertices + 1,
                current_distance,
                current_vertex_index,
            )
        end

        return get_closest_visited_vertex(
            distances_len,
            distances,
            visited_vertices_len - 1,
            visited_vertices + 1,
            closest_distance,
            closest_vertex,
        )
    end
end
