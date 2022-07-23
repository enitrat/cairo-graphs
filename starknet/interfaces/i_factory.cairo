%lang starknet

@contract_interface
namespace IFactory:
    func get_pair(token0 : felt, token1 : felt) -> (pair : felt):
    end

    func get_all_pairs() -> (all_pairs_len : felt, all_pairs : felt*):
    end

    func get_num_of_pairs() -> (num_of_pairs : felt):
    end

    func get_fee_to() -> (address : felt):
    end

    func get_fee_to_setter() -> (address : felt):
    end

    func get_pair_contract_class_hash() -> (class_hash : felt):
    end

    func create_pair(tokenA : felt, tokenB : felt) -> (pair : felt):
    end

    func set_fee_to(new_fee_to : felt):
    end

    func set_fee_to_setter(new_fee_to_setter : felt):
    end
end
