%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starknet.contracts.amm_wrapper_library import AmmWrapper
from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IAmmWrapper:
    func get_pair(token0 : felt, token1 : felt) -> (pair : felt):
    end

    func get_all_pairs() -> (all_pairs_len : felt, all_pairs : felt*):
    end

    func get_pair_token0(pair : felt) -> (token0 : felt):
    end

    func get_pair_token1(pair : felt) -> (token1 : felt):
    end

    func get_pair_reserves(pair : felt) -> (reserve_0 : Uint256, reserve_1 : Uint256):
    end

    func get_amounts_out(amount_in : Uint256, path_len : felt, path : felt*) -> (
        amounts_len : felt, amounts : Uint256*
    ):
    end
end
