%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin

from starknet.interfaces.i_router import IRouter
from starknet.interfaces.i_factory import IFactory
from starknet.interfaces.i_pair import IJediSwapPair
from starkware.cairo.common.uint256 import Uint256
from starknet.data_types.data_types import Pair, Node
from starkware.cairo.common.alloc import alloc

@storage_var
func AmmWrapper_jediswap_router() -> (address : felt):
end

@storage_var
func AmmWrapper_jediswap_factory() -> (address : felt):
end

namespace AmmWrapper:
    func initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        jediswap_router : felt, jediswap_factory : felt
    ):
        AmmWrapper_jediswap_router.write(jediswap_router)
        AmmWrapper_jediswap_factory.write(jediswap_factory)
        return ()
    end

    func get_pair{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token0 : felt, token1 : felt
    ) -> (pair : felt):
        let (factory_address) = AmmWrapper_jediswap_factory.read()
        let (pair) = IFactory.get_pair(factory_address, token0, token1)
        return (pair)
    end

    func get_parsed_pairs{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        let (parsed_pairs : Pair*) = alloc()

        return ()
    end

    func get_pair_tokens{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        pair_address : felt
    ) -> (pair : felt):
        let (token0) = get_pair_token0(pair_address)
        let (token1) = get_pair_token1(pair_address)
        tempvar pair : Pair = Pair(token0, token1)
        return (pair)
    end

    func get_all_pairs{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        all_pairs_len : felt, all_pairs : felt*
    ):
        let (factory_address) = AmmWrapper_jediswap_factory.read()
        let (all_pairs_len, all_pairs) = IFactory.get_all_pairs(factory_address)
        # return (all_pairs_len, all_pairs)
        return (3, all_pairs)
    end

    func get_pair_token0{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        pair : felt
    ) -> (token0 : felt):
        let (token0) = IJediSwapPair.token0(pair)
        return (token0)
    end

    func get_pair_token1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        pair : felt
    ) -> (token1 : felt):
        let (token1) = IJediSwapPair.token1(pair)
        return (token1)
    end

    func get_pair_reserves{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        pair : felt
    ) -> (reserve_0 : Uint256, reserve_1 : Uint256):
        let (reserve_0, reserve_1, _) = IJediSwapPair.get_reserves(pair)
        return (reserve_0, reserve_1)
    end

    func get_amounts_out{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        amount_in : Uint256, path_len : felt, path : felt*
    ) -> (amounts_len : felt, amounts : Uint256*):
        alloc_locals
        let (router_address) = AmmWrapper_jediswap_router.read()
        let (amounts_len, amounts) = IRouter.get_amounts_out(
            router_address, amount_in, path_len, path
        )
        return (amounts_len, amounts)
    end
end
