#[dojo::contract]
mod Brewmaster {
    use core::traits::Into;
    use brewmaster::models::brewpub::{BrewPubStruct, PubScaleStruct};
    use brewmaster::models::manager::{SystemManager, ManagerSignature, MaxScale, UpgradePubPrice};
    use brewmaster::interfaces::{
        IAction::IBrewmasterImpl, IAccount::{AccountABIDispatcher, AccountABIDispatcherTrait}
    };
    use starknet::{
        ContractAddress, get_caller_address, get_block_timestamp, get_contract_address, get_tx_info
    };
    use array::{Array, ArrayTrait};
    use core::pedersen::PedersenTrait;
    use core::hash::{HashStateTrait, HashStateExTrait};

    const PROOF_TYPE_HASH: felt252 =
        selector!(
            "Proof(player:ContractAddress,treasury:u256,points:u256,saltNonce:u128)u256(low:felt,high:felt)"
        );

    const U256_TYPE_HASH: felt252 = selector!("u256(low:felt,high:felt)");
    const STARKNET_DOMAIN_TYPE_HASH: felt252 =
        selector!("StarkNetDomain(name:felt,version:felt,chainId:felt)");


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

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct UpdateSystemManager {
        #[key]
        oldManager: ContractAddress,
        newManager: ContractAddress,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct CloseUpPub {
        #[key]
        player: ContractAddress,
        treasury: u256,
        points: u256
    }

    #[derive(Drop, Copy, Hash)]
    struct StarknetDomain {
        name: felt252,
        version: felt252,
        chain_id: felt252,
    }

    #[derive(Drop, Copy, Hash)]
    struct Proof {
        player: ContractAddress,
        treasury: u256,
        points: u256,
        saltNonce: u128
    }

    #[abi(embed_v0)]
    impl BrewmasterImpl of IBrewmasterImpl<ContractState> {
        fn updateSystemManager(ref world: IWorldDispatcher, managerOfWorld: ContractAddress) {
            let oldManager: SystemManager = get!(world, get_contract_address(), (SystemManager));
            set!(
                world,
                (SystemManager { system: get_contract_address(), managerAddress: managerOfWorld })
            );
            emit!(
                world,
                (UpdateSystemManager {
                    oldManager: oldManager.managerAddress, newManager: managerOfWorld
                })
            )
        }

        fn updateMaxScale(ref world: IWorldDispatcher, maxTable: u16, maxStool: u16) {
            set!(world, (MaxScale { system: get_contract_address(), maxTable, maxStool }))
        }

        fn updateUpgradePrice(
            ref world: IWorldDispatcher, addTablePrice: u256, addStoolPrice: u256
        ) {
            set!(
                world,
                (UpgradePubPrice { system: get_contract_address(), addTablePrice, addStoolPrice })
            )
        }

        fn createPub(ref world: IWorldDispatcher) {
            let manager: SystemManager = get!(world, get_contract_address(), (SystemManager));
            let upgradePrice: UpgradePubPrice = get!(
                world, get_contract_address(), (UpgradePubPrice)
            );
            assert(
                manager.managerAddress.is_non_zero()
                    && upgradePrice.addTablePrice > 0
                    && upgradePrice.addStoolPrice > 0,
                'System not initialized.'
            );

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
            let maxScale: MaxScale = get!(world, get_contract_address(), (MaxScale));
            assert(maxScale.maxStool > 0, 'System not set max scale');

            let player = get_caller_address();
            let mut playerPub: BrewPubStruct = get!(world, player, (BrewPubStruct));

            assert(playerPub.scale.len() > 0, 'Pub not created.');
            assert(playerPub.scale.len() > tableIndex.into(), 'Table not exist.');
            assert(
                *(playerPub.scale.at(tableIndex.into()).stools) < maxScale.maxStool,
                'Table reachs maximum stool.'
            );
            let basePrice: u256 = get!(world, get_contract_address(), (UpgradePubPrice))
                .addStoolPrice;

            assert(playerPub.treasury >= basePrice, 'Insufficience Treasury');
            playerPub.treasury -= basePrice;

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
            let maxScale: MaxScale = get!(world, get_contract_address(), (MaxScale));
            assert(maxScale.maxTable > 0, 'System not set max scale');

            let player = get_caller_address();
            let mut playerPub: BrewPubStruct = get!(world, player, (BrewPubStruct));

            assert(playerPub.scale.len() > 0, 'Pub not created.');
            assert(playerPub.scale.len() < maxScale.maxTable.into(), 'reach maximum tables.');

            let tableIndex: u16 = playerPub.scale.len().try_into().unwrap();

            let basePrice: u256 = get!(world, get_contract_address(), (UpgradePubPrice))
                .addTablePrice;
            let price = basePrice * (tableIndex.into() + 1 - 3);
            assert(playerPub.treasury >= price, 'Insufficience Treasury');
            playerPub.treasury -= price;

            playerPub.scale.append(PubScaleStruct { tableIndex, stools: 1 });

            set!(world, (playerPub));
            emit!(world, (AddStool { player, tableIndex }))
        }

        fn closingUpPub(
            ref world: IWorldDispatcher,
            treasury: u256,
            points: u256,
            closedAt: u128,
            managerSignature: Array<felt252>
        ) {
            let player = get_caller_address();
            let mut playerPub: BrewPubStruct = get!(world, player, (BrewPubStruct));

            assert(playerPub.scale.len() > 0, 'Pub not created.');

            let manager: SystemManager = get!(world, get_contract_address(), (SystemManager));
            let msgHash = Private::computeMessageHash(
                manager.managerAddress, player, treasury, points, closedAt
            );
            assert(
                Private::isValidSignature(manager.managerAddress, msgHash, managerSignature),
                'Invalid manager signature'
            );

            let proof: ManagerSignature = get!(world, get_contract_address(), (ManagerSignature));
            assert(!proof.isUsed, 'Signature is used');
            set!(
                world, (ManagerSignature { system: get_contract_address(), msgHash, isUsed: true })
            );

            playerPub.treasury += treasury;
            playerPub.points += points;
            set!(world, (playerPub));
            emit!(world, (CloseUpPub { player, treasury, points }))
        }

        fn getSystemManager(world: @IWorldDispatcher) -> ContractAddress {
            let manager: SystemManager = get!(world, get_contract_address(), (SystemManager));
            manager.managerAddress
        }

        fn getMaxScale(world: @IWorldDispatcher) -> MaxScale {
            get!(world, get_contract_address(), (MaxScale))
        }

        fn getPriceForAddTable(world: @IWorldDispatcher, player: ContractAddress) -> u256 {
            let mut playerPub: BrewPubStruct = get!(world, player, (BrewPubStruct));
            let basePrice: u256 = get!(world, get_contract_address(), (UpgradePubPrice))
                .addTablePrice;
            if playerPub.scale.len() == 0 {
                return basePrice;
            }

            let newTableIndex: u16 = playerPub.scale.len().try_into().unwrap();
            basePrice * (newTableIndex.into() + 1 - 3)
        }

        fn getPriceForAddStool(world: @IWorldDispatcher) -> u256 {
            get!(world, get_contract_address(), (UpgradePubPrice)).addStoolPrice
        }
    }

    trait IStructHash<T> {
        fn hash_struct(self: @T) -> felt252;
    }

    impl StructHashStarknetDomain of IStructHash<StarknetDomain> {
        fn hash_struct(self: @StarknetDomain) -> felt252 {
            let mut state = PedersenTrait::new(0);
            state = state.update_with(STARKNET_DOMAIN_TYPE_HASH);
            state = state.update_with(*self);
            state = state.update_with(4);
            state.finalize()
        }
    }

    impl StructHashU256 of IStructHash<u256> {
        fn hash_struct(self: @u256) -> felt252 {
            let mut state = PedersenTrait::new(0);
            state = state.update_with(U256_TYPE_HASH);
            state = state.update_with(*self);
            state = state.update_with(3);
            state.finalize()
        }
    }

    impl StructHashProof of IStructHash<Proof> {
        fn hash_struct(self: @Proof) -> felt252 {
            let mut state = PedersenTrait::new(0);
            state = state.update_with(PROOF_TYPE_HASH);
            state = state.update_with(*self.player);
            state = state.update_with(self.treasury.hash_struct());
            state = state.update_with(self.points.hash_struct());
            state = state.update_with(*self.saltNonce);
            state = state.update_with(5);
            state.finalize()
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn isValidSignature(
            signer: ContractAddress, hash: felt252, signature: Array<felt252>
        ) -> bool {
            let account: AccountABIDispatcher = AccountABIDispatcher { contract_address: signer };
            account.is_valid_signature(hash, signature) == 'VALID'
        }

        fn computeMessageHash(
            manager: ContractAddress,
            player: ContractAddress,
            treasury: u256,
            points: u256,
            saltNonce: u128
        ) -> felt252 {
            let domain = StarknetDomain {
                name: 'brewmaster', version: 1, chain_id: get_tx_info().unbox().chain_id
            };

            let mut state = PedersenTrait::new(0);
            state = state.update_with('StarkNet Message');
            state = state.update_with(domain.hash_struct());
            state = state.update_with(manager);
            let proof = Proof { player, treasury, points, saltNonce };
            state = state.update_with(proof.hash_struct());
            state = state.update_with(4);
            state.finalize()
        }
    }
}
