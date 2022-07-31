from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.lang.compiler.lib.registers import get_fp_and_pc

namespace Stack:
    # Removes the last element from an array and returns it
    func pop(stack_len : felt, stack : felt*) -> (
        new_stack_len : felt, new_stack : felt*, last_elem : felt
    ):
        alloc_locals

        let (local res : felt*) = alloc()
        memcpy(res, stack, stack_len - 1)
        return (stack_len - 1, res, stack[stack_len - 1])
    end

    func put(stack_len : felt, stack : felt*, element : felt) -> (
        new_stack_len : felt, new_stack : felt*
    ):
        alloc_locals

        assert stack[stack_len] = element
        let new_stack_len = stack_len + 1
        return (new_stack_len, stack)
    end
end

namespace Array:
    # @notice increments the neighbors_len of a node by re-writing the entire
    func update_value_at_index(
        array_len : felt, array : felt*, elem_index : felt, new_value : felt
    ) -> (new_array : felt*):
        alloc_locals
        let (__fp__, _) = get_fp_and_pc()
        let (local res : felt*) = alloc()
        memcpy(res, array, elem_index)  # copy elem_index elements from array to res
        memcpy(res + elem_index, &new_value, 1)  # store new_value at memory cell [res+member_index]

        # first memory address to copy in
        # first memory address to copy from
        # number of values to copy
        memcpy(res + elem_index + 1, array + elem_index + 1, array_len - elem_index - 1)

        return (res)
    end

    func copy(array_len : felt, array : felt*) -> (new_array : felt*):
        alloc_locals
        let (local res : felt*) = alloc()
        memcpy(res, array, array_len)  # copy array_len elems from array to res

        return (res)
    end

    func remove_value_at_index(array_len : felt, array : felt*, elem_index : felt) -> (
        new_array_len : felt, new_array : felt*
    ):
        alloc_locals
        let (__fp__, _) = get_fp_and_pc()
        let (local res : felt*) = alloc()
        local new_value = array[elem_index] + 1
        memcpy(res, array, elem_index)  # copy elem_index elements from array to res
        # copy the rest of the array from elem_index+1 to the end of the array
        memcpy(res + elem_index, array + elem_index + 1, array_len - elem_index - 1)

        return (array_len - 1, res)
    end

    func get_value_index(array_len : felt, array : felt*, value : felt, current_index : felt) -> (
        index : felt
    ):
        if array_len == 0:
            assert 1 = 0  # fail if it's not in the array
        end

        let current_value : felt = [array]
        if current_value == value:
            return (current_index)
        end

        return get_value_index(array_len - 1, array + 1, value, current_index + 1)
    end

    func inverse(array_len : felt, array : felt*) -> (inv_array : felt*):
        alloc_locals
        let (local inv_array : felt*) = alloc()

        _inverse_internal(array_len, array, inv_array)
        return (inv_array)
    end
end

func _inverse_internal(array_len : felt, array : felt*, inv_array : felt*):
    if array_len == 0:
        return ()
    end
    assert inv_array[array_len - 1] = [array]
    return _inverse_internal(array_len - 1, array + 1, inv_array)
end
