# @version ^0.3.7
struct Household:
    name: String[20]
    accountAddress: address
    householdAddress: String[50]
    totalEnergy: uint256
    energyCapacity: uint256

struct Transaction:
    name: String[20]
    transactFrom: address
    transactTo: address
    value: uint256
    status: uint256

struct EnergyHistory:
    name: String[20]
    useFor: String[50]
    amount: uint256

enum Status:
    PENDING
    ACCEPTED
    REJECTED

plantName: public(String[20])
contractAddress: public(address)
plantAddress: public(String[50])
totalEnergy: uint256
energyCapacity: public(uint256)
energyGeneration: public(uint256)
energyCost: public(uint256)

households: HashMap[address, Household]
transactions: HashMap[uint256, Transaction]
energyHistory: HashMap[address, EnergyHistory]

#TODO: Insert methods @external etc.
@external
def __init__(_ownerAddress: address, _name: String[20], _plantAddress: String[50], _totalEnergy: uint256, _energyCapacity: uint256, _energyGeneration: uint256, _energyCost: uint256):
    self.contractAddress = _ownerAddress
    self.plantName = _name
    self.plantAddress = _plantAddress
    self.totalEnergy = _totalEnergy
    self.energyCapacity = _energyCapacity
    self.energyGeneration = _energyGeneration
    self.energyCost = _energyCost
    
@external
def registerHousehold(_address: address, _name: String[20], _houseAddress: String[20], _energyCapacity: uint256):
    # Only the owner has access
    assert msg.sender == self.contractAddress
    self.households[_address] = Household({
        name: _name,
        accountAddress: _address,
        householdAddress: _houseAddress,
        totalEnergy: 0,
        energyCapacity: _energyCapacity
    })

@external
@view
def getHousehold(_address: address) -> (String[20], address, String[50], uint256, uint256):
    # Only the owner and household owner has access
    assert self.households[_address].accountAddress == _address or self.contractAddress == _address
    household: Household = self.households[_address]

    return(household.name, household.accountAddress, household.householdAddress, household.totalEnergy, household.energyCapacity)



