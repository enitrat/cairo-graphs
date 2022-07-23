%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256
from starknet.graph.graph import build_graph
from starknet.graph.dfs_search import init_dfs
from starknet.data_types.data_types import Pair, Node
from starknet.contracts.hubble_library import Hubble, get_node_from_token



@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    amm_wrapper_contract : felt
):
    Hubble.initializer(amm_wrapper_contract)
    return ()
end

@view
func get_all_routes{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_from : felt, token_to : felt, max_hops : felt
) -> (routes_len : felt, routes : felt*):
    return Hubble.get_all_routes(token_from, token_to, max_hops)
end

@view
func get_best_route{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    amount_in : Uint256, token_from : felt, token_to : felt, max_hops : felt
) -> (route_len : felt, route : Uint256*, amount_out : Uint256):
    return Hubble.get_best_route(amount_in, token_from, token_to, max_hops)
end