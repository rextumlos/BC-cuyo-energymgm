# @version ^0.3.7

# Development of Blockchain-based Energy Management in Cuyo Island, Palawan: A simulation in Ganache
struct User:
    name: String[20]
    demand: uint256
    demand_response_active: bool
    demand_response_rate: decimal

# Microgrid's address
grid_address: public(address)

# register user in grid
users: public(HashMap[address, User])

# Energy production and price per kWh in the microgrid
energy_production: public(uint256)
energy_price: public(decimal)

# Total users, energy demand and energy sales in the microgrid
total_users: public(uint256)
total_demand: public(uint256)
total_energy_sales: public(decimal)

# Events
# when a user's energy demand is updated
event Demand_updated:
    _user: address
    _demand: uint256

# when the grid's energy price is updated
event Price_updated:
    _energy_price: decimal

# when the grid stability status changes
event Grid_stability_changed:
    _is_stable: bool

# Grid stability threshold
stability_threshold: uint256 

# Functions
# initializing smart contract
@external
def __init__(owner_address: address, production: uint256, price: decimal, threshold: uint256):
    self.grid_address = owner_address
    self.energy_production = production
    self.energy_price = price
    self.stability_threshold = threshold
    self.total_demand = 0
    self.total_users = 0

@external
# updating the energy price
def update_energy_price(owner_address: address, new_price: decimal):
    # only the owner has access
    assert owner_address == self.grid_address, "Invalid credentials."

    self.energy_price = new_price
    log Price_updated(new_price)

# updating energy threshold
@external
def update_threshold(owner_address: address, new_threshold: uint256):
    # only the owner has access
    assert owner_address == self.grid_address, "Invalid credentials."

    self.stability_threshold = new_threshold

# adding users
@external
def add_users(owner_address: address, user_address: address, name: String[20]):
    # only the owner has access
    assert owner_address == self.grid_address, "Invalid credentials."

    self.users[user_address] = User({
        name: name,
        demand: 0,
        demand_response_active: False,
        demand_response_rate: 0.0,
    })

    self.total_users += 1

# get total demand and sales, and energy price
@external
def get_total_demand() -> uint256:
    return self.total_demand

@external
def get_energy_price() -> decimal:
    return self.energy_price

@external
def get_total_energy_sales() -> decimal:
    self.calculate_total_energy_sales()
    return self.total_energy_sales

# user functions
@external 
def get_user_demand(user_address: address) -> uint256:
    user: User =  self.users[user_address]
    assert user_address == msg.sender or self.grid_address == msg.sender, "Invalid access"
    assert user.name != "", "Address not found."

    return self.users[user_address].demand

@external
def update_demand(user_address: address, new_demand: uint256):
    user: User =  self.users[user_address]
    assert user_address == msg.sender, "Invalid access"
    assert user.name != "", "Address not found."

    self.total_demand -= self.users[user_address].demand
    self.users[user_address].demand = new_demand
    self.total_demand += new_demand
    log Demand_updated(user_address, new_demand)
    self.check_grid_stability()


    if self.users[user_address].demand_response_active:
        self.apply_demand_response(new_demand, user_address)

@external
def update_demand_response(user_address: address, active: bool):
    user: User =  self.users[user_address]
    assert user_address == msg.sender, "Invalid access"
    assert user.name != "", "Address not found."

    self.users[user_address].demand_response_active = active

@internal
def apply_demand_response(demand: uint256, user_address: address):
    decimal_demand: decimal = convert(demand, decimal)

    self.set_demand_response_rate(user_address)
    adjusted_demand: uint256 = convert((decimal_demand * (1.0 - self.users[user_address].demand_response_rate)), uint256)

    self.users[user_address].demand = adjusted_demand
    self.total_demand -= (demand - adjusted_demand)
    self.check_grid_stability()
    log Demand_updated(msg.sender, adjusted_demand)

@internal
def set_demand_response_rate(user_address: address):
    average_demand: uint256 = self.total_demand / self.total_users

    # simple algorithm for setting the demand response rate
    if average_demand <= 50:
        self.users[user_address].demand_response_rate = 0.1
    elif average_demand <= 100:
        self.users[user_address].demand_response_rate = 0.2
    elif average_demand <= 200:
        self.users[user_address].demand_response_rate = 0.3
    else:
        self.users[user_address].demand_response_rate = 0.4

@internal
def check_grid_stability():
    if self.total_demand <= self.energy_production + self.stability_threshold and self.total_demand >= self.energy_production - self.stability_threshold:
        log Grid_stability_changed(True)
    else:
        log Grid_stability_changed(False)

@internal
def calculate_total_energy_sales():
    decimal_total_demand: decimal = convert(self.total_demand, decimal)
    self.total_energy_sales = decimal_total_demand * self.energy_price


