use starknet::ContractAddress;
use brewmaster::models::brewpub::BrewPubStruct;
use brewmaster::models::manager::MaxScale;

#[dojo::interface]
pub trait IBrewmasterImpl<TContractState> {
    fn updateSystemManager(ref world: IWorldDispatcher, managerOfWorld: ContractAddress);
    fn updateMaxScale(ref world: IWorldDispatcher, maxTable: u16, maxStool: u16);
    fn createPub(ref world: IWorldDispatcher);
    fn addStool(ref world: IWorldDispatcher, tableIndex: u16);
    fn addTable(ref world: IWorldDispatcher);
    fn closingUpPub(
        ref world: IWorldDispatcher,
        treasury: u256,
        points: u256,
        closedAt: u128,
        managerSignature: Array<felt252>
    );
    fn getPlayerPub(world: @IWorldDispatcher, player: ContractAddress) -> BrewPubStruct;
    fn getSystemManager(world: @IWorldDispatcher) -> ContractAddress;
    fn getMaxScale(world: @IWorldDispatcher) -> MaxScale;
}
