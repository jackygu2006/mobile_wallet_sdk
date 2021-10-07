/* eslint-disable */

export default {
  types: {
    ValidatorPrefsWithBlocked: {
      commission: 'Compact<Perbill>',
      cmix_root: 'Hash',
      blocked: 'bool'
    },
    ValidatorPrefs: {
      commission: 'Compact<Perbill>',
      blocked: 'bool',
      cmix_root: 'Hash'
    },
  }
}
