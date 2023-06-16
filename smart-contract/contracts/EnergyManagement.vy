# @version ^0.3.7

# Development of Blockchain-based Energy Management in Cuyo Island, Palawan: A simulation in Ganache
struct User:
    name: String[20]
    energy_consumption: uint256     # decimal
    demand: uint256                 # Energy required per month
    electric_bill: uint256

struct Transaction:
    fromAddress: address
    energy_consumption: uint256     # decimal
    demand: uint256                 # Energy required per month # decimal
    electric_bill: uint256          # decimal

transactions: Transaction[100]

# Microgrid's address
grid_address: public(address)

# register user in grid
users: public(HashMap[address, User])

# Energy production and price per kWh in the microgrid
energy_production: uint256          # decimal
power_rate: uint256                 # decimal

# Total users, transactions, energy demand and energy sales in the microgrid
total_users: uint256
total_demand: uint256               # decimal
total_energy_sales: uint256         # decimal
total_transactions: uint256

grid_is_stable: bool

# Events
# when a user's energy demand is updated
event Demand_updated:
    _user: address
    _old_demand: uint256            # decimal
    _new_demand: uint256            # decimal

# when the grid's energy price is updated
event Rate_updated:
    _old_power_rate: uint256        # decimal
    _new_power_rate: uint256        # decimal

# when the grid stability status changes
event Grid_stability_changed:
    _is_stable: bool

# Grid stability threshold
stability_threshold: uint256        # decimal

# Functions
# initializing smart contract
@external
def __init__(owner_address: address, production: uint256, rate: uint256, threshold: uint256):
    self.grid_address = owner_address
    self.energy_production = production
    self.power_rate = rate
    self.stability_threshold = threshold
    self.total_demand = 0
    self.total_users = 0
    self.total_energy_sales = 0
    self.total_transactions = 0
    self.grid_is_stable = True

@external
# updating the energy price
def update_power_rate(owner_address: address, new_rate: uint256):
    # only the owner has access
    assert owner_address == self.grid_address and msg.sender == self.grid_address, "Invalid credentials."
    old_rate: uint256 = self.power_rate
    self.power_rate = new_rate
    log Rate_updated(old_rate, new_rate)

# updating energy threshold
@external
def update_threshold(owner_address: address, new_threshold: uint256):
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
        energy_consumption: 0,
        demand: 0,
        electric_bill: 0
    })

    self.total_users += 1

# get total demand and sales, and energy price
@external
def get_total_demand() -> uint256:
    return self.total_demand

@external
def get_power_rate() -> uint256:
    return self.power_rate

@external
def get_stability_threshold() -> uint256:
    return self.stability_threshold

@external
def get_energy_production() -> uint256:
    return self.energy_production

@external
def get_total_energy_sales() -> uint256:
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
def get_user_demand(user_address: address) -> uint256:
    user: User =  self.users[user_address]
    assert user_address == msg.sender or self.grid_address == msg.sender, "Invalid access"
    assert user.name != "", "Address not found."

    return self.users[user_address].demand

@external
def get_user_consumption(user_address: address) -> uint256:
    user: User =  self.users[user_address]
    assert user_address == msg.sender or self.grid_address == msg.sender, "Invalid access"
    assert user.name != "", "Address not found."

    return self.users[user_address].energy_consumption

@external
def get_user_electric_bill(user_address: address) -> uint256:
    user: User =  self.users[user_address]
    assert user_address == msg.sender or self.grid_address == msg.sender, "Invalid access"
    assert user.name != "", "Address not found."

    return self.users[user_address].electric_bill

@external
def update_energy_consumption(user_address: address, new_consumption: uint256):
    user: User =  self.users[user_address]
    assert user_address == msg.sender, "Invalid access"
    assert user.name != "", "Address not found."

    assert self.energy_production >= self.total_demand + new_consumption * 720, "Too much energy."

    old_demand: uint256 = self.users[user_address].demand
    self.total_demand -= self.users[user_address].demand
    self.users[user_address].energy_consumption = new_consumption
    self.users[user_address].demand = new_consumption * 720  # Assuming 720 hours in a month (30 days)
    self.total_demand += new_consumption * 720

    log Demand_updated(user_address, old_demand, self.users[user_address].demand)

    self.check_grid_stability()
    self.calculate_electric_bill(user_address)  # Calculate electric bill

    self.update_transactions(user_address)

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
    self.total_energy_sales = self.total_demand * self.power_rate

@internal
def calculate_electric_bill(user_address: address):
    self.users[user_address].electric_bill = self.users[user_address].energy_consumption * 720 * self.power_rate

@internal
def update_transactions(user_address: address):
    self.transactions[self.total_transactions] = Transaction({
        fromAddress: user_address,
        energy_consumption: self.users[user_address].energy_consumption,
        demand:  self.users[user_address].demand,
        electric_bill: self.users[user_address].electric_bill,
    })

    self.total_transactions += 1
