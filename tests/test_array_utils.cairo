%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.memcpy import memcpy

from cairo_graphs.utils.array_utils import Stack, Array

@external
func test_pop_stack() {
    let (my_stack: felt*) = alloc();
    assert my_stack[0] = 1;
    assert my_stack[1] = 2;
    assert my_stack[2] = 3;
    let stack_len = 3;
    let (stack_len, my_stack, last_elem) = Stack.pop(stack_len, my_stack);
    assert last_elem = 3;
    assert stack_len = 2;
    assert my_stack[0] = 1;
    tempvar memcell_allocated = my_stack[1];
    assert memcell_allocated = 2;
    %{ expect_revert() %}
    tempvar memcell_unallocated = my_stack[2];  // last elem was popped -> should revert
    assert memcell_unallocated = 3;
    return ();
}

@external
func test_put_stack() {
    let (my_stack: felt*) = alloc();
    assert my_stack[0] = 1;
    assert my_stack[1] = 2;
    assert my_stack[2] = 3;
    let stack_len = 3;
    let (stack_len, my_stack) = Stack.put(stack_len, my_stack, 4);
    assert stack_len = 4;
    tempvar last_value = my_stack[stack_len - 1];
    assert last_value = 4;
    return ();
}

@external
func test_update_value_at_index() {
    alloc_locals;
    let (local my_array: felt*) = alloc();
    assert my_array[0] = 1;
    assert my_array[1] = 2;
    assert my_array[2] = 3;
    let array_len = 3;
    let (new_array: felt*) = Array.update_value_at_index(array_len, my_array, 1, 20);
    tempvar value = new_array[0];
    assert value = my_array[0];
    tempvar value = new_array[1];
    assert value = 20;
    tempvar value = new_array[2];
    assert value = my_array[2];
    %{ expect_revert() %}
    tempvar value = new_array[3];
    return ();
}

@external
func test_copy() {
    alloc_locals;
    let (local my_array: felt*) = alloc();
    assert my_array[0] = 1;
    assert my_array[1] = 2;
    assert my_array[2] = 3;
    let array_len = 3;
    let (new_array) = Array.copy(array_len, my_array);
    tempvar value = new_array[0];
    assert value = my_array[0];
    tempvar value = new_array[1];
    assert value = my_array[1];
    tempvar value = new_array[2];
    assert value = my_array[2];
    %{ expect_revert() %}
    tempvar value = new_array[3];
    return ();
}

@external
func test_remove_value_at_index() {
    alloc_locals;
    let (local my_array: felt*) = alloc();
    assert my_array[0] = 1;
    assert my_array[1] = 2;
    assert my_array[2] = 3;
    let array_len = 3;
    let (new_array_len: felt, new_array: felt*) = Array.remove_value_at_index(
        array_len, my_array, 1
    );
    assert new_array_len = 2;
    tempvar value = new_array[0];
    assert value = my_array[0];
    tempvar value = new_array[1];
    assert value = my_array[2];
    %{ expect_revert() %}
    tempvar value = new_array[2];
    return ();
}

@external
func test_get_value_index() {
    alloc_locals;
    let (local my_array: felt*) = alloc();
    assert my_array[0] = 1;
    assert my_array[1] = 2;
    assert my_array[2] = 3;
    let array_len = 3;
    let (index) = Array.get_value_index(array_len, my_array, 3, 0);
    assert index = 2;
    return ();
}

@external
func test_inv_array() {
    alloc_locals;
    let (local my_array: felt*) = alloc();
    assert my_array[0] = 1;
    assert my_array[1] = 2;
    assert my_array[2] = 3;
    let array_len = 3;
    let (inv_array) = Array.inverse(array_len, my_array);
    tempvar value = inv_array[2];
    assert value = my_array[0];
    tempvar value = inv_array[1];
    assert value = my_array[1];
    tempvar value = inv_array[0];
    assert value = my_array[2];
    %{ expect_revert() %}
    tempvar value = inv_array[3];
    return ();
}
