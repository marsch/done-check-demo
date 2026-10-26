import pytest

from ledger.split import allocate, split_even


def test_allocate_proportional():
    assert allocate(1000, [1, 1, 2]) == [250, 250, 500]


def test_allocate_sums_to_total():
    shares = allocate(1001, [3, 7, 11])
    assert sum(shares) == 1001
    assert len(shares) == 3


def test_allocate_zero_weight():
    assert allocate(500, [0, 1, 1]) == [0, 250, 250]


def test_split_even_exact():
    assert split_even(90, 3) == [30, 30, 30]


def test_split_even_remainder():
    assert split_even(100, 3) == [33, 33, 34]


def test_empty_weights_rejected():
    with pytest.raises(ValueError):
        allocate(100, [])
