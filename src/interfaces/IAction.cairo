use starknet::ContractAddress;
use brewmaster::models::brewpub::BrewPubStruct;

#[dojo::interface]
pub trait IBrewmasterImpl {
    fn createPub(ref world: IWorldDispatcher);
    fn addStool(ref world: IWorldDispatcher, tableIndex: u16);
    fn addTable(ref world: IWorldDispatcher);
    fn getPlayerPub(world: @IWorldDispatcher, player: ContractAddress) -> BrewPubStruct;
}
