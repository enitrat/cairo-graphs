# A vertex has an index (its position in the graph DS),
# a unique identifier and a list of adjacent vertices.
struct Vertex:
    member index : felt
    member identifier : felt
    member adjacent_vertices : AdjacentVertex*
end

# An edge is represented by its source and destination identifiers and a weight.
struct Edge:
    member src_identifier : felt
    member dst_identifier : felt
    member weight : felt
end

# dst represents the adjacent vertex in the graph
# weight is the distance from the current vertex to dst.
struct AdjacentVertex:
    member dst : Vertex
    member weight : felt
end
