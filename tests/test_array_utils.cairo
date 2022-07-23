%lang starknet
from src.utils.array_utils import Stack
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.memcpy import memcpy

@external
func test_pop_stack():
    let (my_stack : felt*) = alloc()
    assert my_stack[0] = 1
    assert my_stack[1] = 2
    assert my_stack[2] = 3
    let stack_len = 3
    let (stack_len, my_stack, last_elem) = Stack.pop(stack_len, my_stack)
    assert last_elem = 3
    assert stack_len = 2
    assert my_stack[0] = 1
    tempvar should_not_revert = my_stack[1]
    assert should_not_revert = 2
    %{ expect_revert() %}
    tempvar should_revert = my_stack[2]
    return ()
end

@external
func test_put_stack():
    let (my_stack : felt*) = alloc()
    assert my_stack[0] = 1
    assert my_stack[1] = 2
    assert my_stack[2] = 3
    let stack_len = 3
    let (stack_len, my_stack) = Stack.put(stack_len, my_stack, 4)
    assert stack_len = 4
    assert my_stack[3] = 4
    return ()
end
