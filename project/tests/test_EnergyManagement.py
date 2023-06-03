import pytest
from brownie import EnergyManagement, accounts
from brownie.exceptions import VirtualMachineError


@pytest.fixture()
def microgrid():
    microgrid = accounts[0].deploy(EnergyManagement, accounts[0], 7902770, "10.0", 10)
    return microgrid

def test_init(microgrid):
    assert microgrid.grid_address() == accounts[0]
    assert microgrid.energy_production() == 7902770
    assert microgrid.energy_price() == "10"
    assert microgrid.stability_threshold() == 10
    assert microgrid.total_demand() == 0
    assert microgrid.total_users() == 0
    
def test_update_energy_price(microgrid):
    expected = "20"
    txn = microgrid.update_energy_price(accounts[0], expected)
    txn.wait(1)
    
    actual = microgrid.energy_price()
    assert expected == actual
    
def test_update_threshold(microgrid):
    expected = 30
    txn = microgrid.update_threshold(accounts[0], expected)
    txn.wait(1)
    
    actual = microgrid.stability_threshold()
    assert expected == actual
    
def test_add_users(microgrid):
    new_user_address = accounts[1]
    new_username = "Cuyo"
    
    txn = microgrid.add_users(accounts[0], new_user_address, new_username, {'from': accounts[0]})
    txn.wait(1)
    
    total_users = microgrid.total_users()
    assert total_users == 1
    assert microgrid.users(new_user_address)[0] == new_username
    assert microgrid.users(new_user_address)[1] == 0
    assert microgrid.users(new_user_address)[2] == False
    assert microgrid.users(new_user_address)[3] == "0.0"

def test_unauthorized_add_users(microgrid):
    new_user_address = accounts[1]
    new_username = "Cuyo"
    
    with pytest.raises(VirtualMachineError):
        microgrid.add_users(accounts[1], new_user_address, new_username, {'from': accounts[1]})
        
def test_get_total_demand(microgrid):
    expected = 0
    actual = microgrid.get_total_demand.call()
    
    assert expected == actual

def test_get_energy_price(microgrid):
    expected = 10
    actual = microgrid.get_energy_price.call()
    
    assert expected == actual

def test_get_total_energy_sales(microgrid):
    expected = 0
    actual = microgrid.get_total_energy_sales.call()
    
    assert expected == actual

    
def test_get_user_demand(microgrid):
    new_user_address = accounts[1]
    new_username = "Cuyo"
    
    txn = microgrid.add_users(accounts[0], new_user_address, new_username, {'from': accounts[0]})
    txn.wait(1)
    
    expected = 0
    actual = microgrid.get_user_demand.call(new_user_address)
    
    assert expected == actual
    
def test_unauthorized_get_user_demand(microgrid):
    new_user_address = accounts[1]
    new_username = "Cuyo"
    
    txn = microgrid.add_users(accounts[0], new_user_address, new_username, {'from': accounts[0]})
    txn.wait(1)
    
    with pytest.raises(VirtualMachineError):
        microgrid.get_user_demand.call(new_user_address, {'from': accounts[2]})
    
def test_update_demand(microgrid):
    new_user_address = accounts[1]
    new_username = "Cuyo"
    
    txn = microgrid.add_users(accounts[0], new_user_address, new_username, {'from': accounts[0]})
    txn.wait(1)
    
    expected = 20
    txn_update = microgrid.update_demand(accounts[1], expected, {'from': accounts[1]})
    txn_update.wait(1)
    
    actual = microgrid.get_user_demand.call(new_user_address, {'from': accounts[1]})
    assert expected == actual

    
def test_update_demand_response(microgrid):
    new_user_address = accounts[1]
    new_username = "Cuyo"
    
    txn = microgrid.add_users(accounts[0], new_user_address, new_username, {'from': accounts[0]})
    txn.wait(1)
    
    expected = True
    txn_update = microgrid.update_demand_response(accounts[1], expected, {'from': accounts[1]})
    txn_update.wait(1)
    
    actual = microgrid.users(new_user_address)[2]
    assert expected == actual

    

    