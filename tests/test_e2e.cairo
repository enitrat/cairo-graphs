%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.uint256 import Uint256, uint256_lt
from starknet.contracts.amm_wrapper_library import AmmWrapper
from starknet.data_types.data_types import Pair, Node
from starkware.cairo.common.alloc import alloc
from starknet.graph.graph import build_graph
from starknet.graph.dfs_search import init_dfs
from starknet.contracts.hubble_library import Hubble, parse_all_pairs

const JEDI_ROUTER = 19876081725
const JEDI_FACTORY = 1786125

const TOKEN_A = 123
const TOKEN_B = 456
const TOKEN_C = 990
const TOKEN_D = 982

const RESERVE_A_B_0_LOW = 27890
const RESERVE_A_B_1_LOW = 26789

const PAIR_A_B = 12345
const PAIR_A_C = 13345
const PAIR_B_C = 23456
const PAIR_D_C = 43567
const PAIR_D_B = 42567

func before_each{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    let (contract_address) = get_contract_address()

    # Store values in contract storage
    %{ store(ids.contract_address, "AmmWrapper_jediswap_router", [ids.JEDI_ROUTER]) %}
    %{ store(ids.contract_address, "AmmWrapper_jediswap_factory", [ids.JEDI_FACTORY]) %}
    return ()
end

@external
func test_e2e{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    before_each()
    %{ stop_mock = mock_call(ids.JEDI_FACTORY,"get_all_pairs", [5,ids.PAIR_A_B, ids.PAIR_A_C,ids.PAIR_B_C,ids.PAIR_D_C,ids.PAIR_D_B]) %}
    let (all_pairs_len, all_pairs) = AmmWrapper.get_all_pairs()
    %{ stop_mock() %}
    assert all_pairs_len = 5
    assert all_pairs[0] = PAIR_A_B
    assert all_pairs[1] = PAIR_A_C
    assert all_pairs[2] = PAIR_B_C
    assert all_pairs[3] = PAIR_D_C
    assert all_pairs[4] = PAIR_D_B

    %{
        stop_mock_ab_0 = mock_call(ids.PAIR_A_B,"token0", [ids.TOKEN_A])
        stop_mock_ab_1 = mock_call(ids.PAIR_A_B,"token1", [ids.TOKEN_B])
        stop_mock_ac_0 = mock_call(ids.PAIR_A_C,"token0", [ids.TOKEN_A])
        stop_mock_ac_1 = mock_call(ids.PAIR_A_C,"token1", [ids.TOKEN_C])
        stop_mock_bc_0 = mock_call(ids.PAIR_B_C,"token0", [ids.TOKEN_B])
        stop_mock_bc_1 = mock_call(ids.PAIR_B_C,"token1", [ids.TOKEN_C])
        stop_mock_dc_0 = mock_call(ids.PAIR_D_C,"token0", [ids.TOKEN_D])
        stop_mock_dc_1 = mock_call(ids.PAIR_D_C,"token1", [ids.TOKEN_C])
        stop_mock_db_0 = mock_call(ids.PAIR_D_B,"token0", [ids.TOKEN_D])
        stop_mock_db_1 = mock_call(ids.PAIR_D_B,"token1", [ids.TOKEN_B])
    %}

    # see details in test_dfs.cairo
    let (local parsed_pairs : Pair*) = alloc()
    let (parsed_pairs_len) = parse_all_pairs(all_pairs_len, all_pairs, parsed_pairs, 0)
    assert parsed_pairs_len = 5
    assert parsed_pairs[0] = Pair(TOKEN_A, TOKEN_B)
    assert parsed_pairs[1] = Pair(TOKEN_A, TOKEN_C)
    assert parsed_pairs[2] = Pair(TOKEN_B, TOKEN_C)
    assert parsed_pairs[3] = Pair(TOKEN_D, TOKEN_C)
    assert parsed_pairs[4] = Pair(TOKEN_D, TOKEN_B)

    let (graph_len, graph, neighbors) = build_graph(pairs_len=parsed_pairs_len, pairs=parsed_pairs)

    let node_a = graph[0]
    let node_c = graph[2]
    let (saved_paths_len, saved_paths) = init_dfs(graph_len, graph, neighbors, node_a, node_c, 4)
    # %{
    #     print(ids.saved_paths_len)
    #     for i in range(ids.saved_paths_len):
    #         print(memory[ids.saved_paths+i])
    # %}
    assert saved_paths_len = 12
    assert saved_paths[0] = 2  # path 1 length
    assert saved_paths[3] = 4  # path 2 length
    assert saved_paths[8] = 3  # path 3 length
    assert saved_paths[1] = TOKEN_A
    assert saved_paths[2] = TOKEN_C
    assert saved_paths[4] = TOKEN_A
    assert saved_paths[5] = TOKEN_B
    assert saved_paths[6] = TOKEN_D
    assert saved_paths[7] = TOKEN_C
    assert saved_paths[9] = TOKEN_A
    assert saved_paths[10] = TOKEN_B
    assert saved_paths[11] = TOKEN_C

    # let amount_in = Uint256(1000,0)

    # %{
    #     stop_mock_ab_out = mock_call(ids.PAIR_A_B,"token0", [ids.TOKEN_A])
    #     stop_mock_ac_out = mock_call(ids.PAIR_A_B,"token0", [ids.TOKEN_A])
    #     stop_mock_bc_out = mock_call(ids.PAIR_A_B,"token0", [ids.TOKEN_A])
    #     stop_mock_dc_out = mock_call(ids.PAIR_A_B,"token0", [ids.TOKEN_A])
    #     stop_mock_db_out= mock_call(ids.PAIR_A_B,"token0", [ids.TOKEN_A])
    # %}

    # now that we have the paths -> we need to run IJediswapRouter.get_amounts_out with each path :)
    return ()
end

func test_get_best_route{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    before_each()
    %{ stop_mock = mock_call(ids.JEDI_FACTORY,"get_all_pairs", [5,ids.PAIR_A_B, ids.PAIR_A_C,ids.PAIR_B_C,ids.PAIR_D_C,ids.PAIR_D_B]) %}
    let (all_pairs_len, all_pairs) = AmmWrapper.get_all_pairs()
    %{ stop_mock() %}
    assert all_pairs_len = 5
    assert all_pairs[0] = PAIR_A_B
    assert all_pairs[1] = PAIR_A_C
    assert all_pairs[2] = PAIR_B_C
    assert all_pairs[3] = PAIR_D_C
    assert all_pairs[4] = PAIR_D_B

    %{
        stop_mock_ab_0 = mock_call(ids.PAIR_A_B,"token0", [ids.TOKEN_A])
        stop_mock_ab_1 = mock_call(ids.PAIR_A_B,"token1", [ids.TOKEN_B])
        stop_mock_ac_0 = mock_call(ids.PAIR_A_C,"token0", [ids.TOKEN_A])
        stop_mock_ac_1 = mock_call(ids.PAIR_A_C,"token1", [ids.TOKEN_C])
        stop_mock_bc_0 = mock_call(ids.PAIR_B_C,"token0", [ids.TOKEN_B])
        stop_mock_bc_1 = mock_call(ids.PAIR_B_C,"token1", [ids.TOKEN_C])
        stop_mock_dc_0 = mock_call(ids.PAIR_D_C,"token0", [ids.TOKEN_D])
        stop_mock_dc_1 = mock_call(ids.PAIR_D_C,"token1", [ids.TOKEN_C])
        stop_mock_db_0 = mock_call(ids.PAIR_D_B,"token0", [ids.TOKEN_D])
        stop_mock_db_1 = mock_call(ids.PAIR_D_B,"token1", [ids.TOKEN_B])
    %}
    return ()
end
