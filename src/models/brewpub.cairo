use starknet::ContractAddress;

#[derive(Drop, Serde)]
#[dojo::model]
pub struct BrewPubStruct {
    #[key]
    pub player: ContractAddress,
    pub scale: Array<PubScaleStruct>,
    pub treasury: u256,
    pub points: u256,
    pub createAt: u64
}

#[derive(Copy, Drop, Serde, Introspect)]
struct PubScaleStruct {
    tableIndex: u16,
    stools: u16
}

