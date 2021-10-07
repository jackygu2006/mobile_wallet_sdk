// Auto-generated via `yarn polkadot-types-from-defs`, do not edit
/* eslint-disable */

import type { Compact, Struct, bool } from '@polkadot/types';
import type { Hash, Perbill } from '@polkadot/types/interfaces/runtime';

/** @name ValidatorPrefs */
export interface ValidatorPrefs extends Struct {
  readonly commission: Compact<Perbill>;
  readonly blocked: bool;
  readonly cmix_root: Hash;
}

/** @name ValidatorPrefsWithBlocked */
export interface ValidatorPrefsWithBlocked extends Struct {
  readonly commission: Compact<Perbill>;
  readonly cmix_root: Hash;
  readonly blocked: bool;
}

export type PHANTOM_STAKING = 'staking';
