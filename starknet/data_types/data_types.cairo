# A node has an identifier (token address) and a list of neighbor nodes
struct Node:
    member index : felt
    member identifier : felt
    member neighbor_nodes : Node*
end

# A pair containing 2 token identified by their address
struct Pair:
    member token_0 : felt
    member token_1 : felt
end
