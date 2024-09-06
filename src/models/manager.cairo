use starknet::ContractAddress;

#[derive(Drop, Serde)]
#[dojo::model]
pub struct SystemManager {
    #[key]
    pub system: ContractAddress,
    pub managerAddress: ContractAddress,
}

#[derive(Drop, Serde)]
#[dojo::model]
pub struct ManagerSignature {
    #[key]
    pub system: ContractAddress,
    pub msgHash: felt252,
    pub isUsed: bool,
}


#[derive(Drop, Serde)]
#[dojo::model]
pub struct MaxScale {
    #[key]
    pub system: ContractAddress,
    pub maxTable: u16,
    pub maxStool: u16,
}

#[derive(Drop, Serde)]
#[dojo::model]
pub struct UpgradePubPrice {
    #[key]
    pub system: ContractAddress,
    pub addTablePrice: u256,
    pub addStoolPrice: u256,
}
