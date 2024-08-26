#[dojo::contract]
mod Brewmaster {
    use brewmaster::models::brewpub::{BrewPubStruct, PubScaleStruct};
    use brewmaster::interfaces::IAction::IBrewmasterImpl;
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use array::{Array, ArrayTrait};

    const MAX_STOOL_PER_TABLE: u16 = 10;

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct CreatePub {
        #[key]
        player: ContractAddress,
        createdAt: u64
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct AddStool {
        #[key]
        player: ContractAddress,
        tableIndex: u16
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct AddTable {
        #[key]
        player: ContractAddress,
        tableIndex: u16
    }

    #[abi(embed_v0)]
    impl BrewmasterImpl of IBrewmasterImpl<ContractState> {
        fn createPub(ref world: IWorldDispatcher) {
            let player = get_caller_address();
            let mut playerPub = get!(world, player, (BrewPubStruct));

            assert(playerPub.scale.len() == 0, 'Player has created a pub.');

            let mut index: u16 = 0;
            let mut pubScale = ArrayTrait::<PubScaleStruct>::new();
            loop {
                if index == 3 {
                    break;
                }

                pubScale.append(PubScaleStruct { tableIndex: index, stools: 1 });
                index += 1;
            };

            set!(
                world,
                (BrewPubStruct {
                    player, scale: pubScale, treasury: 0, points: 0, createAt: get_block_timestamp()
                })
            );

            emit!(world, (CreatePub { player, createdAt: get_block_timestamp() }))
        }

        fn getPlayerPub(world: @IWorldDispatcher, player: ContractAddress) -> BrewPubStruct {
            get!(world, player, (BrewPubStruct))
        }

        fn addStool(ref world: IWorldDispatcher, tableIndex: u16) {
            let player = get_caller_address();
            let mut playerPub: BrewPubStruct = get!(world, player, (BrewPubStruct));

            assert(playerPub.scale.len() > 0, 'Pub not created.');
            assert(playerPub.scale.len() > tableIndex.into(), 'Table not exist.');
            assert(
                *(playerPub.scale.at(tableIndex.into()).stools) < MAX_STOOL_PER_TABLE,
                'Table reachs maximum stool.'
            );
            // TODO assert amount of treasury
            // TODO reduse the treasury

            let mut newPubScale = ArrayTrait::<PubScaleStruct>::new();
            let cpPubScale = playerPub.scale.clone();
            let mut index: u16 = 0;
            loop {
                if index.into() == cpPubScale.len() {
                    break;
                }

                if index == tableIndex {
                    newPubScale
                        .append(
                            PubScaleStruct {
                                tableIndex: index, stools: *(cpPubScale.at(index.into()).stools) + 1
                            }
                        );
                } else {
                    newPubScale
                        .append(
                            PubScaleStruct {
                                tableIndex: index, stools: *(cpPubScale.at(index.into()).stools)
                            }
                        );
                }

                index += 1;
            };

            playerPub.scale = newPubScale;
            set!(world, (playerPub));
            emit!(world, (AddStool { player, tableIndex }))
        }

        fn addTable(ref world: IWorldDispatcher) {
            let player = get_caller_address();
            let mut playerPub = get!(world, player, (BrewPubStruct));

            assert(playerPub.scale.len() > 0, 'Pub not created.');
            // TODO assert amount of treasury
            // TODO reduse the treasury

            let tableIndex = playerPub.scale.len().try_into().unwrap();
            playerPub.scale.append(PubScaleStruct { tableIndex, stools: 1 });

            set!(world, (playerPub));
            emit!(world, (AddStool { player, tableIndex }))
        }
    }
}
