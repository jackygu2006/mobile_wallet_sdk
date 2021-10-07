// Auto-generated via `yarn polkadot-types-from-defs`, do not edit
/* eslint-disable */

import type { Compact, Option, Struct, U8aFixed, Vec, bool, u16, u32, u64, u8 } from '@polkadot/types';
import type { ITuple } from '@polkadot/types/types';
import type { AccountId, Balance, BlockNumber, Hash, Perbill, Permill } from '@polkadot/types/interfaces/runtime';

/** @name ChainId */
export interface ChainId extends u8 {}

/** @name CountryCode */
export interface CountryCode extends U8aFixed {}

/** @name CustodyInfo */
export interface CustodyInfo extends Struct {
  readonly allocation: Compact<Balance>;
  readonly vested: Compact<Balance>;
  readonly custody: AccountId;
  readonly reserve: AccountId;
  readonly proxied: bool;
}

/** @name DepositNonce */
export interface DepositNonce extends u64 {}

/** @name GeoBin */
export interface GeoBin extends u8 {}

/** @name IdealInterestPoint */
export interface IdealInterestPoint extends Struct {
  readonly block: BlockNumber;
  readonly interest: Compact<Perbill>;
}

/** @name InflationFixedParams */
export interface InflationFixedParams extends Struct {
  readonly min_inflation: Compact<Perbill>;
  readonly ideal_stake: Compact<Perbill>;
  readonly falloff: Compact<Perbill>;
}

/** @name Performance */
export interface Performance extends Struct {
  readonly period: u64;
  readonly points: RewardPoints;
  readonly countries: Vec<ITuple<[CountryCode, GeoBin]>>;
  readonly multipliers: Vec<ITuple<[GeoBin, PointsMultiplier]>>;
}

/** @name PointsMultiplier */
export interface PointsMultiplier extends u16 {}

/** @name ProposalVotes */
export interface ProposalVotes extends Struct {
  readonly votes_for: Vec<AccountId>;
  readonly votes_against: Vec<AccountId>;
  readonly status: enum;
}

/** @name ResourceId */
export interface ResourceId extends U8aFixed {}

/** @name RewardPoints */
export interface RewardPoints extends Struct {
  readonly success: u32;
  readonly failure: u32;
  readonly block: u32;
}

/** @name Scheduling */
export interface Scheduling extends Struct {
  readonly team_size: u8;
  readonly batch_size: u32;
  readonly min_delay: u64;
  readonly pool_threshold: Permill;
}

/** @name SoftwareHashes */
export interface SoftwareHashes extends Struct {
  readonly server: Hash;
  readonly fatbin: Hash;
  readonly libpow: Hash;
  readonly gateway: Hash;
  readonly scheduling: Hash;
  readonly wrapper: Hash;
  readonly udb: Hash;
  readonly notifications: Hash;
  readonly extra: Option<Vec<Hash>>;
}

/** @name Timeouts */
export interface Timeouts extends Struct {
  readonly precomputation: u64;
  readonly realtime: u64;
  readonly advertisement: u64;
}

/** @name UserRegistration */
export interface UserRegistration extends Struct {
  readonly max: u32;
  readonly period: u64;
}

/** @name Variables */
export interface Variables extends Struct {
  readonly performance: Performance;
  readonly timeouts: Timeouts;
  readonly scheduling: Scheduling;
  readonly registration: UserRegistration;
}

export type PHANTOM_XXNETWORK = 'xxnetwork';
