import type { ApiInterfaceRx } from '@polkadot/api/types';
import type { Option,  StorageKey } from '@polkadot/types';
import type { Nominations, AccountId  } from '@polkadot/types/interfaces';
import type { DeriveCustodyAccounts } from './types';
import {  switchMap, map } from 'rxjs';
import { memo } from '../util';

export function nominatingCustodyAccounts (instanceId: string, api: ApiInterfaceRx) {
  return memo(
    instanceId,
    () => api.query.xxNetwork.custodyAccounts.keys().pipe(
      map((keys: StorageKey<[AccountId]>[]) => keys.map(({ args: [nominatorId] }) => nominatorId)),
      switchMap(((custodyAccounts: AccountId[]) => api.query.staking.nominators.multi<Option<Nominations>>(custodyAccounts).pipe(
        map(
          (nominators: Option<Nominations>[]) => nominators.reduce((acc, nominators, index) => {
            if (nominators.isSome && custodyAccounts[index]) {
              return acc.concat({
                accountId: custodyAccounts[index],
                targets: nominators.unwrap().targets,
              });
            }
            return acc;
          }, [] as DeriveCustodyAccounts)
        )
      )))
    )
  )
}
