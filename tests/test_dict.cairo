%lang starknet

from starkware.cairo.common.default_dict import default_dict_new, default_dict_finalize
from starkware.cairo.common.dict import dict_write, dict_update, dict_read

@external
func test_dict{range_check_ptr}() -> ():
    alloc_locals
    let (local my_dict_start) = default_dict_new(default_value=7)
    let my_dict = my_dict_start
    dict_write{dict_ptr=my_dict}(key=0, new_value=8)

    dict_write{dict_ptr=my_dict}(key=0, new_value=9)
    let (value_at_0) = dict_read{dict_ptr=my_dict}(key=0)
    %{ print(ids.value_at_0) %}
    # The following is an inconsistent update, the entry with
    # key 1 still contains the default value 7.
    # This will fail while using the library's hints
    # but can be made to pass by a malicious prover.

    # For a honest prover, this will fail in the library's hints,
    # but a malicious prover can make the following dict_update
    # pass. However, if it does, the code will necessarily fail
    # at default_dict_finalize.
    # dict_update{dict_ptr=my_dict}(key=1, prev_value=8, new_value=9)

    # Finalize fails for the malicious prover with extra update.
    let (finalized_dict_start, finalized_dict_end) = default_dict_finalize(
        my_dict_start, my_dict, 7
    )
    return ()
end
