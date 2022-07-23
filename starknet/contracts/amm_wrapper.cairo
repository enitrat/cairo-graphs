%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starknet.contracts.amm_wrapper_library import AmmWrapper
from starkware.cairo.common.uint256 import Uint256

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    jediswap_router : felt, jediswap_factory : felt
):
    AmmWrapper.initializer(jediswap_router, jediswap_factory)
    return ()
end

@view
func get_pair{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token0 : felt, token1 : felt
) -> (pair : felt):
    return AmmWrapper.get_pair(token0, token1)
end

@view
func get_all_pairs{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    all_pairs_len : felt, all_pairs : felt*
):
    return AmmWrapper.get_all_pairs()
end

@view
func get_pair_token0{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    pair : felt
) -> (token0 : felt):
    return AmmWrapper.get_pair_token0(pair)
end

@view
func get_pair_token1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    pair : felt
) -> (token1 : felt):
    return AmmWrapper.get_pair_token1(pair)
end

@view
func get_pair_reserves{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    pair : felt
) -> (reserve_0 : Uint256, reserve_1 : Uint256):
    return AmmWrapper.get_pair_reserves(pair)
end

@view
func get_amounts_out{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    amount_in : Uint256, path_len : felt, path : felt*
) -> (amounts_len : felt, amounts : Uint256*):
    return AmmWrapper.get_amounts_out(amount_in, path_len, path)
end
