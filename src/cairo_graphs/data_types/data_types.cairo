// A vertex has an index (its position in the graph DS),
// a unique identifier and a list of adjacent vertices.
struct Vertex {
    index: felt,
    identifier: felt,
    adjacent_vertices: AdjacentVertex*,
}

// An edge is represented by its source and destination identifiers and a weight.
struct Edge {
    src_identifier: felt,
    dst_identifier: felt,
    weight: felt,
}

// dst represents the adjacent vertex in the graph
// weight is the distance from the current vertex to dst.
struct AdjacentVertex {
    dst: Vertex,
    weight: felt,
}
