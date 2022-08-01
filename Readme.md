# Cairo-graphs: A graph library in Cairo

## Introduction [WIP]

Cairo-Graphs is a graph library written in Cairo that allows you to create and interact with graphs, entirely in Cairo, without state persistence.

## Graph implementation

The graph is implemented as an array of `Vertex`. A vertex is composed of three elements :
- Its index in the graph array.
- Its identifier (it can be a token address, a hash, a number, a string, etc.)
- An array of adjacent vertices.

Since the memory is immutable in cairo, I had to make a choice when building the graph.
Since I store in each vertex an array containing the neighboring vertices, I had to track how many neighbors each vertex had (`adj_vertices_count[i]`).
But since the memory is immutable in cairo, to avoid having complex operations requiring rebuilding the whole graph on each change
I introduced an external array that tracks how many neighbors each vertex has.
That way, when I add a neighbor to a vertex, I can just append it to the `adj_vertices` array of the current vertex, and I can update the number of neighbors it has by
rebuilding the `adj_vertices_count` array.

This implementation is probably not the most efficient, and one should expect modifications -
I have to study the benefits of using another data structure, for example, a dict, to track how many neighbors each vertex has.

So a graph is essentially represented by 2 data structures :
-  `graph`, an array of vertices.
-  `adj_vertices_count`, an array of integers, tracking how many neighbors each vertex has.
## How to use it

### Create a graph

To create a graph, import the `Graph` from `src.graph.graph` that exposes several methods :

- `new_graph` returns an empty graph that you can fill manually
- `build_undirected_graph_from_edges` : Given an array of Edges (Represented by a src_identifier, dst_identifier and weight), returns an undirected graph built from the edges.
- `build_directed_graph_from_edges` : Given an array of Edges (Represented by a src_identifier, dst_identifier and weight), returns a directed graph built from the edges.
- `add_edge`: Given an existing graph and an edge to add, updates the graph and returns the updated data.
- `add_vertex_to_graph` : Given an existing graph, adds a new vertex with a specific identifier.

The easiest way is to have an array of `Edge`, Edge being a struct with the following fields :

- `src_identifier` : The identifier of the source vertex.
- `dst_identifier` : The identifier of the destination vertex.
- `weight` : The weight of the edge.

You can for example simply call `build_directed_graph_from_edges(edges_len,edges)` to create a directed graph from an array of edges.

### Graph algorithms

For now, only the Dijkstra algorithm is implemented. You can use it once you have built a valid graph.
To do so, import `Dijkstra` from `src.graph.dijkstra` and call `Dijkstra.shortest_path`, which will return the distance between the two vertices as well as the path itself.
You will need to provide the actual `graph` as well as `adj_vertices_count` as parameters.
## Testing

To run the tests, install protostar and run :

```
protostar test
```
