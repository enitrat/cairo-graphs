%lang starknet

from starkware.cairo.common.alloc import alloc

from cairo_graphs.graph.graph import add_neighbor, GraphMethods
from cairo_graphs.data_types.data_types import Edge, Vertex, AdjacentVertex, Graph

const TOKEN_A = 123;
const TOKEN_B = 456;
const TOKEN_C = 990;
const TOKEN_D = 982;

func build_graph_before_each() -> Graph {
    alloc_locals;
    let graph = GraphMethods.new_graph();

    let (vertex_a_neighbors: AdjacentVertex*) = alloc();
    let (vertex_b_neighbors: AdjacentVertex*) = alloc();
    let (vertex_c_neighbors: AdjacentVertex*) = alloc();

    local vertex_a: Vertex = Vertex(0, TOKEN_A, vertex_a_neighbors);
    local vertex_b: Vertex = Vertex(1, TOKEN_B, vertex_b_neighbors);
    local vertex_c: Vertex = Vertex(2, TOKEN_C, vertex_c_neighbors);

    // populate graph
    assert graph.vertices[0] = vertex_a;
    assert graph.adjacent_vertices_count[0] = 0;
    assert graph.vertices[1] = vertex_b;
    assert graph.adjacent_vertices_count[1] = 0;
    assert graph.vertices[2] = vertex_c;
    assert graph.adjacent_vertices_count[2] = 0;
    let graph_len = 3;
    tempvar res : Graph = Graph(graph_len,graph.vertices,graph.adjacent_vertices_count);
    return res;
}

@external
func test_add_node_to_graph() {
    let (vertices: Vertex*) = alloc();
    let (adj_vertices_count: felt*) = alloc();  // array that tracks the number of neighbor_nodes
    let graph_len: felt = 0;

    tempvar graph: Graph = Graph(graph_len, vertices, adj_vertices_count);
    let graph = GraphMethods.add_vertex_to_graph(graph, TOKEN_A);
    assert graph.graph_len = 1;
    assert vertices[0].identifier = TOKEN_A;
    assert adj_vertices_count[0] = 0;
    tempvar graph:Graph = Graph(graph.graph_len, graph.vertices, graph.adjacent_vertices_count);

    let graph = GraphMethods.add_vertex_to_graph(graph, TOKEN_B);
    assert graph.graph_len = 2;
    assert graph.vertices[1].identifier = TOKEN_B;
    assert graph.adjacent_vertices_count[1] = 0;

    return ();
}

@external
func test_add_neighbor() {
    alloc_locals;
    let graph = build_graph_before_each();
    assert graph.vertices[0].identifier = TOKEN_A;
    assert graph.vertices[1].identifier = TOKEN_B;
    assert graph.vertices[2].identifier = TOKEN_C;
    assert graph.graph_len = 3;  // graph_len is 3 because we have 3 nodes in our graph

    // add TOKEN_B as neighbor of TOKEN_A
    let (adj_vertices_count) = add_neighbor(
        graph.vertices[0], graph.vertices[1], graph.graph_len, graph.adjacent_vertices_count, 0, 0
    );
    tempvar graph:Graph = Graph(graph.graph_len, graph.vertices, adj_vertices_count);

    assert graph.vertices[0].adjacent_vertices[0].dst.identifier = TOKEN_B;
    assert adj_vertices_count[0] = 1;  // TOKEN_A has 1 neighbor, which is TOKEN_B
    assert adj_vertices_count[1] = 0;  // TOKEN_B still has 0 neighbors

    // now add TOKEN_A as neighbor of TOKEN_B
    let (adj_vertices_count) = add_neighbor(
        graph.vertices[1], graph.vertices[0], graph.graph_len, graph.adjacent_vertices_count, 1, 0
    );
    tempvar graph:Graph = Graph(graph.graph_len, graph.vertices, adj_vertices_count);
    assert graph.vertices[1].adjacent_vertices[0].dst.identifier = TOKEN_A;
    assert graph.adjacent_vertices_count[1] = 1;  // TOKEN_B now has 1 neighbor

    // add TOKEN_C as neighbor of TOKEN_A
    let (adj_vertices_count) = add_neighbor(
        graph.vertices[0], graph.vertices[2], graph.graph_len, graph.adjacent_vertices_count, 0, 0
    );
    tempvar graph:Graph = Graph(graph.graph_len, graph.vertices, adj_vertices_count);
    assert graph.vertices[0].adjacent_vertices[1].dst.identifier = TOKEN_C;
    assert adj_vertices_count[0] = 2;  // TOKEN_A now has 2 neighbors

    return ();
}

@external
func test_add_edge() {
    alloc_locals;
    let graph = build_graph_before_each();
    let token_c = TOKEN_C;
    let token_d = TOKEN_D;

    assert graph.graph_len = 3;
    assert graph.vertices[0].identifier = TOKEN_A;
    // add C<>D
    let graph = GraphMethods.add_edge(graph, Edge(TOKEN_C, TOKEN_D, 0));

    let res = GraphMethods.get_vertex_index{graph=graph, identifier=token_c}(0);
    assert res = 2;
    let res = GraphMethods.get_vertex_index{graph=graph, identifier=token_d}(0);
    assert res = 3;

    assert graph.vertices[3].adjacent_vertices[0].dst.identifier = TOKEN_C;

    return ();
}

@external
func test_get_node_index() {
    alloc_locals;
    let graph = build_graph_before_each();
    let token_a = TOKEN_A;
    let token_b = TOKEN_B;

    let res = GraphMethods.get_vertex_index{graph=graph, identifier=token_a}(0);
    assert res = 0;
    let res = GraphMethods.get_vertex_index{graph=graph, identifier=token_b}(0);
    assert res = 1;

    return ();
}

@external
func test_build_graph_undirected() {
    alloc_locals;
    let input_data: Edge* = alloc();
    assert input_data[0] = Edge(TOKEN_A, TOKEN_B, 1);
    assert input_data[1] = Edge(TOKEN_A, TOKEN_C, 1);
    assert input_data[2] = Edge(TOKEN_B, TOKEN_C, 1);

    // the node at graph[i] has adj_vertices_count[i] adjacent vertices.
    // that allows us to dynamically modify the number of neighbors to a vertex, without the need
    // to rebuild the graph (since memory is write-once, we can't update a property of a struct already stored.)
    let graph = GraphMethods.build_undirected_graph_from_edges(
        3, input_data
    );

    assert graph.graph_len = 3;
    assert graph.vertices[0].identifier = TOKEN_A;
    assert graph.vertices[1].identifier = TOKEN_B;
    assert graph.vertices[2].identifier = TOKEN_C;
    assert graph.adjacent_vertices_count[0] = 2;
    assert graph.adjacent_vertices_count[1] = 2;
    assert graph.adjacent_vertices_count[2] = 2;
    return ();
}

@external
func test_generate_graphviz() {
    alloc_locals;
    let input_data: Edge* = alloc();
    assert input_data[0] = Edge(TOKEN_A, TOKEN_B, 1);
    assert input_data[1] = Edge(TOKEN_A, TOKEN_C, 1);
    assert input_data[2] = Edge(TOKEN_B, TOKEN_C, 1);

    let graph = GraphMethods.build_undirected_graph_from_edges(
        3, input_data
    );
    let graph_len = graph.graph_len;
    let vertices = graph.vertices;
    let adjacent_vertices_count = graph.adjacent_vertices_count;

    %{
        IDENTIFIER_INDEX = 1
        ADJACENT_VERTICES_INDEX = 2
        for i in range(ids.graph_len):
            neighbours_len = memory[ids.adjacent_vertices_count+i]
            vertex_id = memory[ids.vertices.address_+i*ids.Vertex.SIZE+IDENTIFIER_INDEX]
            adjacent_vertices_pointer = memory[ids.vertices.address_+i*ids.Vertex.SIZE+ADJACENT_VERTICES_INDEX]
            print(f"{vertex_id} -> {{",end='')
            for j in range (neighbours_len):
                adjacent_vertex = memory[adjacent_vertices_pointer+j*ids.AdjacentVertex.SIZE+IDENTIFIER_INDEX]
                print(f"{adjacent_vertex} ",end='')
            print('}',end='')
            print()
    %}

    assert graph_len = 3;
    assert vertices[0].identifier = TOKEN_A;
    assert vertices[1].identifier = TOKEN_B;
    assert vertices[2].identifier = TOKEN_C;
    assert adjacent_vertices_count[0] = 2;
    assert adjacent_vertices_count[1] = 2;
    assert adjacent_vertices_count[2] = 2;
    return ();
}
