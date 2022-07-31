# Cairo-graphs : A graph library in Cairo

## Introduction [WIP]

Cairo-Graphs is a graph library written in Cairo that allows you to create and interact with graphs, entirely in Cairo, without state persistence.

## How to use it

### Create a graph

To create a graph, easily, import the `Graph` namespace that exposes several methods :

- `new_graph` returns an empty graph that you can fill manually
- `build_undirected_graph_from_edges` : Given an array of Edges (Represented by a src_identifier, dst_identifier and weight), returns an undirected graph built from the edges.
- `build_directed_graph_from_edges` : Given an array of Edges (Represented by a src_identifier, dst_identifier and weight), returns a directed graph built from the edges.
- `add_edge` : Given an existing graph and an edge to add, updates the graph and returns the updated data.
- `add_vertex_to_graph` : Given an existing graph, adds a new vertex with a specific identifier.

### Run the algorithms

For now, only the Dijkstra algorithm is implemented. You can use it once you have built a valid graph.
To do so, import `Dijkstra` from `src.graph.dijkstra` and call `Dijkstra.shortest_path`, which will return the distance between the two vertices as well as the path itself.

## Testing

To run the tests, install protostar and run :

```
protostar test
```
