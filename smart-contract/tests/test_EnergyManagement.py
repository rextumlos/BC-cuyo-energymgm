import pytest
from brownie import EnergyManagement, accounts
from brownie.exceptions import VirtualMachineError


@pytest.fixture()
def microgrid():
    energy_production = 7902770000
    power_rate = 10000
    threshold = 100000
    microgrid = accounts[0].deploy(EnergyManagement, accounts[0], energy_production, power_rate, threshold)
    return microgrid

def test_init(microgrid):
    assert microgrid.grid_address() == accounts[0]
    assert microgrid.get_energy_production.call() == 7902770000
    assert microgrid.get_power_rate.call() == 10000
    assert microgrid.get_stability_threshold.call() == 100000
    assert microgrid.get_total_demand.call() == 0
    assert microgrid.get_total_users.call() == 0
    assert microgrid.get_total_energy_sales.call() == 0
    assert microgrid.get_total_transactions.call() == 0
    assert microgrid.get_grid_is_stable.call() == True
    
def test_update_power_rate(microgrid):
    expected = 20000
    txn = microgrid.update_power_rate(accounts[0], expected)
    txn.wait(1)
    
    with pytest.raises(VirtualMachineError):
        microgrid.update_power_rate(accounts[0], expected, {"from": accounts[1]})
    
    actual = microgrid.get_power_rate.call()
    assert expected == actual
    
def test_update_threshold(microgrid):
    expected = 30000
    txn = microgrid.update_threshold(accounts[0], expected)
    txn.wait(1)
    
    with pytest.raises(VirtualMachineError):
        microgrid.update_threshold(accounts[0], expected, {"from": accounts[1]})
    
    actual = microgrid.get_stability_threshold.call()
    assert expected == actual
    
def test_add_users(microgrid):
    new_user_address = accounts[1]
    new_username = "Cuyo"
    
    txn = microgrid.add_users(accounts[0], new_user_address, new_username, {'from': accounts[0]})
    txn.wait(1)
    
    total_users = microgrid.get_total_users.call()
    assert total_users == 1
    assert microgrid.users(new_user_address)[0] == new_username
    assert microgrid.users(new_user_address)[1] == 0
    assert microgrid.users(new_user_address)[2] == 0
    assert microgrid.users(new_user_address)[3] == 0
    
    new_user_address_2 = accounts[2]
    new_username_2 = "Palawan"
    
    with pytest.raises(VirtualMachineError):
        microgrid.add_users(accounts[2], new_user_address_2, new_username_2, {'from': accounts[2]})
    
          
def test_get_user_demand(microgrid):
    new_user_address = accounts[1]
    new_username = "Cuyo"
    
    txn = microgrid.add_users(accounts[0], new_user_address, new_username, {'from': accounts[0]})
    txn.wait(1)
    
    expected = 0
    actual = microgrid.get_user_demand.call(new_user_address)
    
    assert expected == actual
    
    with pytest.raises(VirtualMachineError):
        microgrid.get_user_demand.call(new_user_address, {'from': accounts[2]})
    
    
def test_update_energy_consumption(microgrid):
    new_user_address = accounts[1]
    new_username = "Cuyo"
    
    txn = microgrid.add_users(accounts[0], new_user_address, new_username, {'from': accounts[0]})
    txn.wait(1)
    
    new_consumption = 20000
    txn_update = microgrid.update_energy_consumption(accounts[1], new_consumption, {'from': accounts[1]})
    txn_update.wait(1)
    
    expected = str(20000 * 720)
    
    actual = microgrid.get_user_demand.call(new_user_address, {'from': accounts[1]})
    assert expected == actual
    
def test_fail_update_energy_consumption(microgrid):
    new_user_address = accounts[1]
    new_username = "Cuyo"
    
    txn = microgrid.add_users(accounts[0], new_user_address, new_username, {'from': accounts[0]})
    txn.wait(1)
    
    new_consumption = 11000000
    
    with pytest.raises(VirtualMachineError):
        microgrid.update_energy_consumption(accounts[1], new_consumption, {"from": accounts[1]})

def test_get_electric_bill(microgrid):
    new_user_address = accounts[1]
    new_username = "Cuyo"
    
    txn = microgrid.add_users(accounts[0], new_user_address, new_username, {'from': accounts[0]})
    txn.wait(1)
    
    new_consumption = 20000
    txn_update = microgrid.update_energy_consumption(accounts[1], new_consumption, {'from': accounts[1]})
    txn_update.wait(1)
    
    expected = new_consumption * 720 * microgrid.get_power_rate.call()
    actual = microgrid.get_user_electric_bill.call(accounts[1], {'from': accounts[1]})
    
    assert expected == actual

def test_get_transactions(microgrid):
    first_user_address = accounts[1]
    first_username = "Cuyo"
    
    txn = microgrid.add_users(accounts[0], first_user_address, first_username, {'from': accounts[0]})
    txn.wait(1)
    
    second_user_address = accounts[2]
    second_username = "Palawan"

    txn_2 = microgrid.add_users(accounts[0], second_user_address, second_username, {'from': accounts[0]})
    txn_2.wait(1)
    
    new_consumption = 10900000
    txn_update = microgrid.update_energy_consumption(accounts[1], new_consumption, {'from': accounts[1]})
    txn_update.wait(1)
    
    new_consumption_2 = 75000
    txn_update_consumption_2 = microgrid.update_energy_consumption(accounts[2], new_consumption_2, {'from': accounts[2]})
    txn_update_consumption_2.wait(1)
    
    with pytest.raises(VirtualMachineError):
        microgrid.get_transactions.call({"from": accounts[1]})
        
    expected_len = 100
    actual_len = len(microgrid.get_transactions.call({"from": accounts[0]}))
    assert expected_len == actual_len
    
