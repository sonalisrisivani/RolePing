import test from 'node:test'
import assert from 'node:assert/strict'
import { defaultPreferences, profileRecord, readPreferences, validatePreferences } from './preferences.js'

const ready = { ...defaultPreferences, target_role: 'Engineer', location: 'Remote', unknown_salary_policy: 'exclude', eligibility_policy: 'confirmed_only' }

test('requires explicit unknown-value choices', () => {
  assert.match(validatePreferences({ ...ready, unknown_salary_policy: null }), /without salary/)
  assert.match(validatePreferences({ ...ready, eligibility_policy: null }), /unconfirmed eligibility/)
})

test('requires comparable salary units and valid timezone', () => {
  assert.match(validatePreferences({ ...ready, salary_floor: '50000' }), /currency and period/)
  assert.match(validatePreferences({ ...ready, timezone: 'Invalid/Zone' }), /IANA timezone/)
  assert.equal(validatePreferences({ ...ready, salary_floor: '50000', salary_currency: 'INR', salary_period: 'month' }), null)
})

test('serializes salary floor without stale units', () => {
  const value = profileRecord({ ...ready, salary_floor: '', salary_currency: 'INR', salary_period: 'year' }, 'user-1')
  assert.equal(value.salary_floor, null)
  assert.equal(value.salary_currency, null)
  assert.equal(value.salary_period, null)
})

test('loads database time into the browser time input', () => {
  assert.equal(readPreferences({ digest_time: '07:00:00' }).digest_time, '07:00')
})
