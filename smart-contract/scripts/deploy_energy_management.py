from brownie import EnergyManagement, accounts


def deploy_energy_management():
    energy_production = "7902770.0"
    power_rate = "10.0"
    threshold = "100.0"
    microgrid = accounts[0].deploy(EnergyManagement, accounts[0], energy_production, power_rate, threshold)
    return microgrid

def main():
    deploy_energy_management()