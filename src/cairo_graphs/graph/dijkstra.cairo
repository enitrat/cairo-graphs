from starkware.cairo.common.default_dict import default_dict_new, default_dict_finalize
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math_cmp import is_le_felt
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.dict import dict_write, dict_read

from cairo_graphs.data_types.data_types import Vertex, Graph
from cairo_graphs.graph.graph import GraphMethods
from cairo_graphs.utils.array_utils import Array

const MAX_FELT = 2 ** 251 - 1;

// Glossary :
// Unvisited vertices = white vertices. It means that they have never been visited.
// Visited vertices = grey vertices. It means that they have been visited once, but they are not in their final state yet.
// Finished vertices = black vertices. It means that we have found the shortest path to them.

// @notice creates a new dictionary with a default value set to 0.
func init_dict() -> (dict_ptr: DictAccess*) {
    alloc_locals;

    let (local dict_start) = default_dict_new(default_value=0);
    let dict_end = dict_start;
    return (dict_end,);
}

// @notice Sets all the values in the array to MAX_FELT.
// @param remaining_len : remaining array length.
// @param current_index : pointer to the current array address.
func set_array_to_max_felt(remaining_len: felt, current_index: felt*) {
    if (remaining_len == 0) {
        return ();
    }
    assert [current_index] = MAX_FELT;
    return set_array_to_max_felt(remaining_len - 1, current_index + 1);
}

namespace Dijkstra {
    // @notice starts a Dijkstra algorith to find the shortest path from the source to the destination vertex.
    // @dev only works if all weights are positive.
    // @param graph the graph
    // @param start_identifier identifier of the starting vertex of the algorithm
    func run{range_check_ptr}(graph: Graph, start_identifier: felt) -> (
        graph: Graph, predecessors: felt*, distances: felt*
    ) {
        alloc_locals;

        let start_vertex_index = GraphMethods.get_vertex_index{
            graph=graph, identifier=start_identifier
        }(0);

        //
        // Data structures
        //

        // stores all of the vertices being currently visited
        let (grey_vertices: felt*) = alloc();
        // stores the predecessor of each node. at index i you have the predecessor of graph[i]
        let (predecessors: felt*) = alloc();
        // stores the distance from origin of each node. at index i you have the distance of graph[i] from origin.
        let (distances: felt*) = alloc();

        //
        // Initial state
        //

        // Set all nodes to unvisited state
        let (dict_ptr: DictAccess*) = init_dict();
        tempvar dict_ptr_start = dict_ptr;
        // Set all initial distances to MAX_FELT
        set_array_to_max_felt(graph.length, distances);
        // predecessor = max_felt means that there is no predecessor
        set_array_to_max_felt(graph.length, predecessors);
        // Set initial node as visited : pushed in the visited vertices, updates its value in the dict.
        let (grey_vertices_len) = DijkstraUtils.set_visited{dict_ptr=dict_ptr}(
            start_vertex_index, 0, grey_vertices
        );
        // Set initial vertex distance to 0
        let (distances) = DijkstraUtils.set_distance(
            start_vertex_index, graph.length, distances, 0
        );

        // cant use the values as implicit args without binding them to an identifier
        let (predecessors, distances) = visit_grey_vertices{
            dict_ptr=dict_ptr, range_check_ptr=range_check_ptr, graph=graph
        }(predecessors, distances, grey_vertices_len, grey_vertices);

        default_dict_finalize(dict_ptr_start, dict_ptr, 0);

        return (graph, predecessors, distances);
    }

    func shortest_path{range_check_ptr}(
        graph: Graph, start_vertex_id: felt, end_vertex_id: felt
    ) -> (path_len: felt, path: felt*, distance: felt) {
        alloc_locals;
        let (graph, predecessors, distances) = run(graph, start_vertex_id);

        let end_vertex_index = GraphMethods.get_vertex_index{graph=graph, identifier=end_vertex_id}(
            0
        );
        let start_vertex_index = GraphMethods.get_vertex_index{
            graph=graph, identifier=start_vertex_id
        }(0);

        let (shortest_path_indexes: felt*) = alloc();
        let total_distance = distances[end_vertex_index];

        // Read all the predecessors from end_vertex to start_vertex
        // and store the path in an array
        // TODO optimize these steps.
        assert [shortest_path_indexes] = end_vertex_index;
        let (shortest_path_len) = build_shortest_path{
            graph=graph,
            predecessors=predecessors,
            start_vertex_index=start_vertex_index,
        }(
            current_vertex_index=end_vertex_index,
            shortest_path_len=1,
            shortest_path_indexes=shortest_path_indexes + 1,
        );

        let (correct_order_path) = Array.inverse(shortest_path_len, shortest_path_indexes);
        // stores the token addresses instead of the graph indexes in the path
        let (identifiers: felt*) = alloc();
        get_identifiers_from_indexes(
            graph.vertices, shortest_path_len, correct_order_path, identifiers
        );

        return (shortest_path_len, identifiers, total_distance);
    }
}

func visit_grey_vertices{dict_ptr: DictAccess*, range_check_ptr, graph: Graph}(
    predecessors: felt*, distances: felt*, grey_vertices_len: felt, grey_vertices: felt*
) -> (predecessors: felt*, distances: felt*) {
    alloc_locals;

    let (closest_distance, closest_vertex_index) = DijkstraUtils.get_closest_visited_vertex(
        graph.length, distances, grey_vertices_len, grey_vertices, MAX_FELT, MAX_FELT
    );

    if (closest_distance == MAX_FELT) {
        return (predecessors, distances);
        // done, it means that there are no more grey vertices pending.
    }

    let current_vertex = graph.vertices[closest_vertex_index];
    let nb_adj_vertices = graph.adjacent_vertices_count[closest_vertex_index];
    let (predecessors, distances) = visit_successors{
        dict_ptr=dict_ptr,
        graph=graph,
        grey_vertices_len=grey_vertices_len,
        grey_vertices=grey_vertices,
    }(
        current_vertex=current_vertex,
        successors_len=nb_adj_vertices,
        predecessors=predecessors,
        distances=distances,
    );

    let (grey_vertices_len, grey_vertices) = DijkstraUtils.set_finished(
        current_vertex.index, grey_vertices_len, grey_vertices
    );
    return visit_grey_vertices(predecessors, distances, grey_vertices_len, grey_vertices);
}

// @notice Visits the successors of a vertex.
func visit_successors{
    dict_ptr: DictAccess*, range_check_ptr, graph: Graph, grey_vertices_len, grey_vertices: felt*
}(current_vertex: Vertex, successors_len: felt, predecessors: felt*, distances: felt*) -> (
    predecessors: felt*, distances: felt*
) {
    alloc_locals;

    // No more successors -> stop current successor loop
    if (successors_len == 0) {
        return (predecessors, distances);
    }

    // We release the current edge if s[j] is not black
    let successor_edge = current_vertex.adjacent_vertices[successors_len - 1];
    let successor = successor_edge.dst;
    let weight = successor_edge.weight;
    let (is_successor_finished) = DijkstraUtils.is_finished(successor.index);

    // Visit next node if the successor is black
    if (is_successor_finished == 1) {
        return visit_successors(current_vertex, successors_len - 1, predecessors, distances);
    }

    relax_edge{predecessors=predecessors, distances=distances}(current_vertex, successor, weight);

    let (is_not_visited) = DijkstraUtils.is_not_visited(successor.index);

    if (is_not_visited == 1) {
        let (grey_vertices_len) = DijkstraUtils.set_visited(
            successor.index, grey_vertices_len, grey_vertices
        );
        tempvar dict_ptr = dict_ptr;
        tempvar grey_vertices_len = grey_vertices_len;
    } else {
        tempvar dict_ptr = dict_ptr;
        tempvar grey_vertices_len = grey_vertices_len;
    }

    return visit_successors(current_vertex, successors_len - 1, predecessors, distances);
}

func relax_edge{
    dict_ptr: DictAccess*, graph: Graph, predecessors: felt*, distances: felt*, range_check_ptr
}(src: Vertex, dst: Vertex, weight: felt) {
    alloc_locals;
    let current_disctance = distances[dst.index];
    let new_distance = distances[src.index] + weight;
    let is_new_distance_better = is_le_felt(new_distance, current_disctance);
    if (is_new_distance_better == 1) {
        let (distances) = DijkstraUtils.set_distance(
            dst.index, graph.length, distances, new_distance
        );
        let (predecessors) = DijkstraUtils.set_predecessor(
            dst.index, graph.length, predecessors, src.index
        );
        return ();
    }
    return ();
}

// @notice: This function is called recursively. It reads the predecessor from the current vertex and
// stores it in the path array.
// @param currrent_vertex_index : currently analysed vertex index.
// @param shortest_path_len : length of the array that holds the path.
// @param shortest_path_indexes : array that holds the indexes of the vertices in the shortes path.
// @returns shortest_path_len : length of the array that holds the shortest path.
func build_shortest_path{
    graph:Graph, predecessors: felt*, start_vertex_index: felt
}(current_vertex_index: felt, shortest_path_len: felt, shortest_path_indexes: felt*) -> (
    shortest_path_len: felt
) {
    let prev_vertex_index = predecessors[current_vertex_index];
    if (prev_vertex_index == MAX_FELT) {
        return (0,);
    }
    assert [shortest_path_indexes] = prev_vertex_index;
    if (prev_vertex_index == start_vertex_index) {
        return (shortest_path_len + 1,);
    }

    return build_shortest_path(
        current_vertex_index=graph.vertices[prev_vertex_index].index,
        shortest_path_len=shortest_path_len + 1,
        shortest_path_indexes=shortest_path_indexes + 1,
    );
}

// @notice Returns an array composed by graph identifiers instead of graph indexes.
func get_identifiers_from_indexes(
    vertices: Vertex*, source_array_len: felt, source_array: felt*, res: felt*
) -> (identifiers_predecessors: felt*) {
    alloc_locals;
    if (source_array_len == 0) {
        return (res,);
    }
    local current_vertex_index = source_array[source_array_len - 1];

    // origin vertex has MAX_FELT as predecessor, which is not a valid graph index.
    if (current_vertex_index == MAX_FELT) {
        assert res[source_array_len - 1] = MAX_FELT;
    } else {
        assert res[source_array_len - 1] = vertices[current_vertex_index].identifier;
    }

    return get_identifiers_from_indexes(
        vertices=vertices, source_array_len=source_array_len - 1, source_array=source_array, res=res
    );
}

// Util functions used in our algorithm.
namespace DijkstraUtils {
    func get_state{dict_ptr: DictAccess*}(vertex_index: felt) {
        let (state) = dict_read{dict_ptr=dict_ptr}(key=vertex_index);
        return (state,);
    }

    func is_not_visited{dict_ptr: DictAccess*}(vertex_index: felt) -> (visited: felt) {
        let (state) = dict_read{dict_ptr=dict_ptr}(key=vertex_index);
        if (state == 0) {
            return (1,);
        }
        return (0,);
    }

    func set_visited{dict_ptr: DictAccess*}(
        vertex_index: felt, grey_vertices_len: felt, grey_vertices: felt*
    ) -> (grey_vertices_len: felt) {
        dict_write{dict_ptr=dict_ptr}(key=vertex_index, new_value=1);
        assert grey_vertices[grey_vertices_len] = vertex_index;
        return (grey_vertices_len + 1,);
    }

    func is_visited{dict_ptr: DictAccess*}(vertex) -> (visited: felt) {
        let (state) = dict_read{dict_ptr=dict_ptr}(key=vertex.index);
        if (state - 1 == 0) {
            return (1,);
        }
        return (0,);
    }

    func set_finished{dict_ptr: DictAccess*}(
        vertex_index: felt, grey_vertices_len: felt, grey_vertices: felt*
    ) -> (grey_vertices_len: felt, grey_vertices: felt*) {
        alloc_locals;
        dict_write{dict_ptr=dict_ptr}(key=vertex_index, new_value=2);
        let (index_to_remove) = Array.get_value_index(
            grey_vertices_len, grey_vertices, vertex_index, current_index=0
        );
        let (grey_vertices_len, grey_vertices) = Array.remove_value_at_index(
            grey_vertices_len, grey_vertices, index_to_remove
        );
        return (grey_vertices_len, grey_vertices);
    }

    func is_finished{dict_ptr: DictAccess*}(vertex_index: felt) -> (finished: felt) {
        let (state) = dict_read{dict_ptr=dict_ptr}(key=vertex_index);
        if (state - 2 == 0) {
            return (1,);
        }
        return (0,);
    }

    func set_distance(vertex_index: felt, distances_len: felt, distances: felt*, new_distance) -> (
        new_distances: felt*
    ) {
        let (new_distances) = Array.update_value_at_index(
            distances_len, distances, vertex_index, new_distance
        );
        return (new_distances,);
    }

    func set_predecessor{dict_ptr: DictAccess*}(
        vertex_index: felt, predecessors_len: felt, predecessors: felt*, new_predecessor_index: felt
    ) -> (new_predecessors: felt*) {
        let (new_predecessors) = Array.update_value_at_index(
            predecessors_len, predecessors, vertex_index, new_predecessor_index
        );
        return (new_predecessors,);
    }

    // Returns the distance of index of the closest vertex
    func get_closest_visited_vertex{range_check_ptr}(
        distances_len: felt,
        distances: felt*,
        grey_vertices_len: felt,
        grey_vertices: felt*,
        closest_distance: felt,
        closest_vertex: felt,
    ) -> (closest_distance: felt, closest_vertex_index: felt) {
        alloc_locals;
        if (grey_vertices_len == 0) {
            return (closest_distance, closest_vertex);
        }
        tempvar current_vertex_index = [grey_vertices];
        tempvar current_distance = distances[current_vertex_index];

        let is_new_distance_better = is_le_felt(current_distance, closest_distance);
        if (is_new_distance_better == 1) {
            return get_closest_visited_vertex(
                distances_len,
                distances,
                grey_vertices_len - 1,
                grey_vertices + 1,
                current_distance,
                current_vertex_index,
            );
        }

        return get_closest_visited_vertex(
            distances_len,
            distances,
            grey_vertices_len - 1,
            grey_vertices + 1,
            closest_distance,
            closest_vertex,
        );
    }
}
