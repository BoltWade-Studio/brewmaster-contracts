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
