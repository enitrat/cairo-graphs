%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256, uint256_lt
from starknet.graph.graph import build_graph
from starknet.graph.dfs_search import init_dfs
from starknet.data_types.data_types import Pair, Node
from starknet.interfaces.i_amm_wrapper import IAmmWrapper
@storage_var
func Hubble_amm_wrapper_address() -> (address : felt):
end

namespace Hubble:
    func initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        amm_wrapper_contract : felt
    ):
        Hubble_amm_wrapper_address.write(amm_wrapper_contract)
        return ()
    end

    func get_all_routes{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_from : felt, token_to : felt, max_hops : felt
    ) -> (routes_len : felt, routes : felt*):
        alloc_locals
        let (amm_wrapper_address) = Hubble_amm_wrapper_address.read()
        with_attr error_message("hubble : get all pairs fail"):
            let (all_pairs_len, all_pairs : felt*) = IAmmWrapper.get_all_pairs(amm_wrapper_address)
        end
        let (local parsed_pairs : Pair*) = alloc()
        with_attr error_message("hubble : parse_all_pairs fail"):
            let (parsed_pairs_len) = parse_all_pairs(all_pairs_len, all_pairs, parsed_pairs, 0)
        end
        with_attr error_message("hubble : build_graphfail"):
            let (graph_len, graph, neighbors) = build_graph(
                pairs_len=parsed_pairs_len, pairs=parsed_pairs
            )
        end
        with_attr error_message("hubble : get node fail"):
            let (local node_from : Node) = get_node_from_token(graph_len, graph, token_from)
            let (local node_to : Node) = get_node_from_token(graph_len, graph, token_to)
        end
        with_attr error_message("hubble : init_dfs fail"):
            let (saved_paths_len, saved_paths) = init_dfs(
                graph_len, graph, neighbors, node_from, node_to, max_hops
            )
        end
        return (saved_paths_len, saved_paths)
    end

    func get_best_route{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        amount_in : Uint256, token_from : felt, token_to : felt, max_hops : felt
    ) -> (route_len : felt, route : Uint256*, amount_out : Uint256):
        let (amm_wrapper_address) = Hubble_amm_wrapper_address.read()
        let (all_routes_len, all_routes) = get_all_routes(token_from, token_to, max_hops)
        let (best_route : Uint256*) = alloc()

        # all routes[0] is the length of the first route, which starts at index = 1
        let (best_route_len, best_route, amount_out) = _get_best_route(
            amount_in,
            all_routes_len,
            all_routes,
            current_best_route_len=0,
            current_best_route=best_route,
        )
        return (best_route_len, best_route, amount_out)
    end

    func _get_best_route{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        amount_in : Uint256,
        all_routes_len : felt,
        all_routes : felt*,
        current_best_route_len : felt,
        current_best_route : Uint256*,
    ) -> (best_route_len : felt, best_route : Uint256*, current_best_amount_out : Uint256):
        alloc_locals
        # end when all routes visited
        if all_routes_len == 0:
            return (
                current_best_route_len,
                current_best_route,
                current_best_route[current_best_route_len - Uint256.SIZE],
            )
        end

        let route_to_eval_len = [all_routes]
        let route_to_eval = all_routes + 1
        let (local amounts_len, local amounts, output_tokens) = evaluate_current_route(
            amount_in, route_to_eval_len, route_to_eval
        )

        let current_best_amount : Uint256 = current_best_route[current_best_route_len - Uint256.SIZE]
        let (is_new_route_better) = uint256_lt(current_best_amount, output_tokens)
        if is_new_route_better == 1:
            # decrement len by (1-> it stores route_len) + route_len that was evaluated
            # tempvar pedersen_ptr = pedersen_ptr
            return _get_best_route(
                amount_in=amount_in,
                all_routes_len=all_routes_len - route_to_eval_len + 1,
                all_routes=all_routes + route_to_eval_len + 1,
                current_best_route_len=amounts_len,
                current_best_route=amounts,
            )
        end
        return _get_best_route(
            amount_in=amount_in,
            all_routes_len=current_best_route_len - route_to_eval_len + 1,
            all_routes=all_routes,
            current_best_route_len=current_best_route_len,
            current_best_route=current_best_route,
        )
    end
end

func parse_all_pairs{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    pairs_addresses_len : felt,
    pairs_addresses : felt*,
    parsed_pairs : Pair*,
    parsed_pairs_len : felt,
) -> (parsed_pairs_len : felt):
    let (amm_wrapper_address) = Hubble_amm_wrapper_address.read()
    if pairs_addresses_len == 0:
        return (parsed_pairs_len)
    end
    let (token_0) = IAmmWrapper.get_pair_token0(amm_wrapper_address, [pairs_addresses])
    let (token_1) = IAmmWrapper.get_pair_token1(amm_wrapper_address, [pairs_addresses])
    assert [parsed_pairs] = Pair(token_0, token_1)
    return parse_all_pairs(
        pairs_addresses_len - 1, pairs_addresses + 1, parsed_pairs + Pair.SIZE, parsed_pairs_len + 1
    )
end

# func _get_best_route{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
#     amount_in : Uint256,
#     all_routes_len : felt,
#     all_routes : felt*,
#     current_best_route_len : felt,
#     current_best_route : Uint256*,
# ) -> (best_route_len : felt, best_route : Uint256*, current_best_amount_out : Uint256):
#     alloc_locals
#     # end when all routes visited
#     if all_routes_len == 0:
#         return (
#             current_best_route_len,
#             current_best_route,
#             current_best_route[current_best_route_len - Uint256.SIZE],
#         )
#     end

# let route_to_eval_len = [all_routes]
#     let route_to_eval = all_routes + 1
#     let (local amounts_len, local amounts, output_tokens) = evaluate_current_route(
#         amount_in, route_to_eval_len, route_to_eval
#     )

# let current_best_amount : Uint256 = current_best_route[current_best_route_len - Uint256.SIZE]
#     let (is_new_route_better) = uint256_lt(current_best_amount, output_tokens)
#     if is_new_route_better == 1:
#         # decrement len by (1-> it stores route_len) + route_len that was evaluated
#         # tempvar pedersen_ptr = pedersen_ptr
#         return _get_best_route(
#             amount_in=amount_in,
#             all_routes_len=all_routes_len - route_to_eval_len + 1,
#             all_routes=all_routes + route_to_eval_len + 1,
#             current_best_route_len=amounts_len,
#             current_best_route=amounts,
#         )
#     end
#     return _get_best_route(
#         amount_in=amount_in,
#         all_routes_len=current_best_route_len - route_to_eval_len + 1,
#         all_routes=all_routes,
#         current_best_route_len=current_best_route_len,
#         current_best_route=current_best_route,
#     )
# end

func evaluate_current_route{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    amount_in : Uint256, route_len : felt, route : felt*
) -> (amounts_len : felt, amounts : Uint256*, output_tokens : Uint256):
    alloc_locals
    let (amm_wrapper_address) = Hubble_amm_wrapper_address.read()
    local pedersen_ptr : HashBuiltin* = pedersen_ptr
    let (amounts_len, amounts) = IAmmWrapper.get_amounts_out(
        amm_wrapper_address, amount_in, route_len, route
    )
    let output_tokens = amounts[amounts_len - 1]
    return (amounts_len, amounts, output_tokens)
end

func get_node_from_token(graph_len : felt, graph : Node*, token : felt) -> (node : Node):
    if graph_len == 0:
        # it should fail
        assert 1 = 0
        # return ([graph])
    end
    if [graph].identifier == token:
        return ([graph])
    end

    return get_node_from_token(graph_len - 1, graph + 1, token)
end
