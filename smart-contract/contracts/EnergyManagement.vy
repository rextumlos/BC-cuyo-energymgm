# @version ^0.3.7

# Development of Blockchain-based Energy Management in Cuyo Island, Palawan: A simulation in Ganache
struct User:
    name: String[20]
    energy_consumption: decimal
    demand: decimal                 # Energy required per month
    demand_response_active: bool
    demand_response_rate: decimal
    electric_bill: decimal

struct Transaction:
    fromAddress: address
    energy_consumption: decimal
    demand: decimal                 # Energy required per month
    demand_response_active: bool
    demand_response_rate: decimal
    electric_bill: decimal

transactions: Transaction[100]

# Microgrid's address
grid_address: public(address)

# register user in grid
users: public(HashMap[address, User])

# Energy production and price per kWh in the microgrid
energy_production: decimal
power_rate: decimal

# Total users, transactions, energy demand and energy sales in the microgrid
total_users: uint256
total_demand: decimal
total_energy_sales: decimal
total_transactions: uint256

grid_is_stable: bool

# Events
# when a user's energy demand is updated
event Demand_updated:
    _user: address
    _old_demand: decimal
    _new_demand: decimal

# when the grid's energy price is updated
event Rate_updated:
    _old_power_rate: decimal
    _new_power_rate: decimal

# when the grid stability status changes
event Grid_stability_changed:
    _is_stable: bool

# Grid stability threshold
stability_threshold: decimal

# Functions
# initializing smart contract
@external
def __init__(owner_address: address, production: decimal, rate: decimal, threshold: decimal):
    self.grid_address = owner_address
    self.energy_production = production
    self.power_rate = rate
    self.stability_threshold = threshold
    self.total_demand = 0.0
    self.total_users = 0
    self.total_energy_sales = 0.0
    self.total_transactions = 0
    self.grid_is_stable = True

@external
# updating the energy price
def update_power_rate(owner_address: address, new_rate: decimal):
    # only the owner has access
    assert owner_address == self.grid_address and msg.sender == self.grid_address, "Invalid credentials."
    old_rate: decimal = self.power_rate
    self.power_rate = new_rate
    log Rate_updated(old_rate, new_rate)

# updating energy threshold
@external
def update_threshold(owner_address: address, new_threshold: decimal):
    # only the owner has access
    assert owner_address == self.grid_address and msg.sender == self.grid_address, "Invalid credentials."

    self.stability_threshold = new_threshold

# adding users
@external
def add_users(owner_address: address, user_address: address, name: String[20]):
    # only the owner has access
    assert owner_address == self.grid_address, "Invalid credentials."

    self.users[user_address] = User({
        name: name,
        energy_consumption: 0.0,
        demand: 0.0,
        demand_response_active: False,
        demand_response_rate: 0.0,
        electric_bill: 0.0
    })

    self.total_users += 1

# get total demand and sales, and energy price
@external
def get_total_demand() -> decimal:
    return self.total_demand

@external
def get_power_rate() -> decimal:
    return self.power_rate

@external
def get_stability_threshold() -> decimal:
    return self.stability_threshold

@external
def get_energy_production() -> decimal:
    return self.energy_production

@external
def get_total_energy_sales() -> decimal:
    self.calculate_total_energy_sales()
    return self.total_energy_sales

@external
def get_transactions() -> Transaction[100]:
    assert msg.sender == self.grid_address, "Invalid credentials."
    return self.transactions

@external
def get_total_users() -> uint256:
    return self.total_users

@external
def get_total_transactions() -> uint256:
    return self.total_transactions

@external
def get_grid_is_stable() -> bool:
    return self.grid_is_stable

# user functions
@external 
def get_user_demand(user_address: address) -> decimal:
    user: User =  self.users[user_address]
    assert user_address == msg.sender or self.grid_address == msg.sender, "Invalid access"
    assert user.name != "", "Address not found."

    return self.users[user_address].demand

@external
def get_user_consumption(user_address: address) -> decimal:
    user: User =  self.users[user_address]
    assert user_address == msg.sender or self.grid_address == msg.sender, "Invalid access"
    assert user.name != "", "Address not found."

    return self.users[user_address].energy_consumption

@external
def get_user_electric_bill(user_address: address) -> decimal:
    user: User =  self.users[user_address]
    assert user_address == msg.sender or self.grid_address == msg.sender, "Invalid access"
    assert user.name != "", "Address not found."

    return self.users[user_address].electric_bill

@external
def update_energy_consumption(user_address: address, new_consumption: decimal):
    user: User =  self.users[user_address]
    assert user_address == msg.sender, "Invalid access"
    assert user.name != "", "Address not found."

    if not self.users[user_address].demand_response_active:
        assert self.energy_production >= self.total_demand + new_consumption * 720.0, "Too much energy."

    old_demand: decimal = self.users[user_address].demand
    self.total_demand -= self.users[user_address].demand
    self.users[user_address].energy_consumption = new_consumption
    self.users[user_address].demand = new_consumption * 720.0  # Assuming 720 hours in a month (30 days)
    self.total_demand += new_consumption * 720.0

    log Demand_updated(user_address, old_demand, self.users[user_address].demand)

    self.check_grid_stability()
    self.calculate_electric_bill(user_address)  # Calculate electric bill

    if self.users[user_address].demand_response_active:
        self.apply_demand_response(self.users[user_address].demand, user_address)
        self.update_transactions(user_address)
    else:
        self.update_transactions(user_address)

@external
def update_demand_response(user_address: address, active: bool):
    user: User =  self.users[user_address]
    assert user_address == msg.sender, "Invalid access"
    assert user.name != "", "Address not found."

    self.users[user_address].demand_response_active = active

@internal
def apply_demand_response(demand: decimal, user_address: address):
    # decimal_demand: decimal = convert(demand, decimal)

    self.set_demand_response_rate(user_address)
    # adjusted_demand: uint256 = convert((demand * (1.0 - self.users[user_address].demand_response_rate)), uint256)
    adjusted_demand: decimal = demand * (1.0 - self.users[user_address].demand_response_rate)

    self.users[user_address].demand = adjusted_demand
    self.users[user_address].energy_consumption = adjusted_demand / 720.0
    self.total_demand -= (demand - adjusted_demand)
    self.check_grid_stability()
    log Demand_updated(msg.sender, demand, adjusted_demand)

@internal
def set_demand_response_rate(user_address: address):
    average_demand: decimal = self.total_demand / convert(self.total_users, decimal)

    # simple algorithm for setting the demand response rate
    if average_demand <= 500.0:
        self.users[user_address].demand_response_rate = 0.1
    elif average_demand <= 1000.0:
        self.users[user_address].demand_response_rate = 0.2
    elif average_demand <= 2000.0:
        self.users[user_address].demand_response_rate = 0.3
    else:
        self.users[user_address].demand_response_rate = 0.4

@internal
def check_grid_stability():
    if self.total_demand <= self.energy_production + self.stability_threshold and self.total_demand >= self.energy_production - self.stability_threshold:
        log Grid_stability_changed(True)
        self.grid_is_stable = True
    else:
        log Grid_stability_changed(False)
        self.grid_is_stable = False

@internal
def calculate_total_energy_sales():
    # decimal_total_demand: decimal = convert(self.total_demand, decimal)
    self.total_energy_sales = self.total_demand * self.power_rate

@internal
def calculate_electric_bill(user_address: address):
    self.users[user_address].electric_bill = self.users[user_address].energy_consumption * 720.0 * self.power_rate

@internal
def update_transactions(user_address: address):
    self.transactions[self.total_transactions] = Transaction({
        fromAddress: user_address,
        energy_consumption: self.users[user_address].energy_consumption,
        demand:  self.users[user_address].demand,
        demand_response_active: self.users[user_address].demand_response_active,
        demand_response_rate: self.users[user_address].demand_response_rate,
        electric_bill: self.users[user_address].electric_bill,
    })

    self.total_transactions += 1


