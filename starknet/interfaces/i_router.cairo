%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IRouter:
    func factory() -> (address : felt):
    end

    func sort_tokens(tokenA : felt, tokenB : felt) -> (token0 : felt, token1 : felt):
    end

    func quote(amountA : Uint256, reserveA : Uint256, reserveB : Uint256) -> (amountB : Uint256):
    end

    func get_amount_out(amountIn : Uint256, reserveIn : Uint256, reserveOut : Uint256) -> (
        amountOut : Uint256
    ):
    end

    func get_amount_in(amountOut : Uint256, reserveIn : Uint256, reserveOut : Uint256) -> (
        amountIn : Uint256
    ):
    end

    func get_amounts_out(amountIn : Uint256, path_len : felt, path : felt*) -> (
        amounts_len : felt, amounts : Uint256*
    ):
    end

    func get_amounts_in(amountOut : Uint256, path_len : felt, path : felt*) -> (
        amounts_len : felt, amounts : Uint256*
    ):
    end

    func add_liquidity(
        tokenA : felt,
        tokenB : felt,
        amountADesired : Uint256,
        amountBDesired : Uint256,
        amountAMin : Uint256,
        amountBMin : Uint256,
        to : felt,
        deadline : felt,
    ) -> (amountA : Uint256, amountB : Uint256, liquidity : Uint256):
    end

    func remove_liquidity(
        tokenA : felt,
        tokenB : felt,
        liquidity : Uint256,
        amountAMin : Uint256,
        amountBMin : Uint256,
        to : felt,
        deadline : felt,
    ) -> (amountA : Uint256, amountB : Uint256):
    end

    func swap_exact_tokens_for_tokens(
        amountIn : Uint256,
        amountOutMin : Uint256,
        path_len : felt,
        path : felt*,
        to : felt,
        deadline : felt,
    ) -> (amounts_len : felt, amounts : Uint256*):
    end

    func swap_tokens_for_exact_tokens(
        amountOut : Uint256,
        amountInMax : Uint256,
        path_len : felt,
        path : felt*,
        to : felt,
        deadline : felt,
    ) -> (amounts_len : felt, amounts : Uint256*):
    end
end
