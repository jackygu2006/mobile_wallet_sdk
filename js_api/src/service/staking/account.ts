
import { ApiPromise } from '@polkadot/api';
import { 
  DeriveSessionIndexes, 
  DeriveStakingAccount, 
  DeriveStakingKeys, 
  DeriveStakingQuery, 
  DeriveUnlocking, 
  StakingQueryFlags 
} from '@polkadot/api-derive/types';
import { StakingLedger, UnlockChunk, Balance } from '@polkadot/types/interfaces';
import { BN, BN_ZERO } from '@polkadot/util';

export async function getStashInfo(api: ApiPromise, accountId: string): Promise<DeriveStakingAccount>{
  const stakingKeys : DeriveStakingKeys[] = await api.derive.staking.keysMulti([accountId]);

  const QUERY_OPTS : StakingQueryFlags = {
    withDestination: false, // Must close this, set false
    withLedger: true,
    withNominations: true,
    withPrefs: true,
  };
  const queries : DeriveStakingQuery[] = await api.derive.staking.queryMulti([accountId], QUERY_OPTS)
  
  const sessionIndexes : DeriveSessionIndexes = await api.derive.session.indexes()

  const re = {
    ...stakingKeys[0],
    ...queries[0],
    redeemable: redeemableSum(api, queries[0].stakingLedger, sessionIndexes),
    unlocking: calculateUnlocking(api, queries[0].stakingLedger, sessionIndexes)        
  }
  return re;
}

function calculateUnlocking (api: ApiPromise, stakingLedger: StakingLedger | undefined, sessionInfo: DeriveSessionIndexes): DeriveUnlocking[] | undefined {
  const results = Object
    .entries(groupByEra(
      (stakingLedger?.unlocking || []).filter(({ era }) => era.unwrap().gt(sessionInfo.activeEra))
    ))
    .map(([eraString, value]): DeriveUnlocking => ({
      remainingEras: new BN(eraString).isub(sessionInfo.activeEra),
      value: api.registry.createType('Balance', value)
    }));

  return results.length
    ? results
    : undefined;
}

function redeemableSum (api: ApiPromise, stakingLedger: StakingLedger | undefined, sessionInfo: DeriveSessionIndexes): Balance {
  return api.registry.createType('Balance', (stakingLedger?.unlocking || [] as UnlockChunk[]).reduce((total, { era, value }): BN => {
    return sessionInfo.activeEra.gte(era.unwrap())
      ? total.iadd(value.unwrap())
      : total;
  }, new BN(0)));
}

function groupByEra (list: UnlockChunk[]): Record<string, BN> {
  return list.reduce((map: Record<string, BN>, { era, value }): Record<string, BN> => {
    const key = era.toString();

    map[key] = (map[key] || BN_ZERO).add(value.unwrap());

    return map;
  }, {});
}