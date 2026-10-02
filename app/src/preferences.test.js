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

test('rejects empty and malformed delivery times before saving', () => {
  for (const digest_time of ['', '24:00', '07:60', '7:00']) {
    assert.match(validatePreferences({ ...ready, digest_time }), /digest time/)
  }
  for (const digest_time of ['00:00', '07:00', '23:59']) {
    assert.equal(validatePreferences({ ...ready, digest_time }), null)
  }
})

test('rejects unsupported choices restored from local storage', () => {
  for (const field of ['role_type', 'work_mode', 'unknown_salary_policy', 'eligibility_policy']) {
    assert.ok(validatePreferences({ ...ready, [field]: 'invalid' }))
  }
  assert.match(validatePreferences({ ...ready, salary_floor: 100, salary_currency: 'INR', salary_period: 'week' }), /salary period/)
  assert.match(validatePreferences({ ...ready, salary_floor: 100, salary_currency: 'rupees', salary_period: 'year' }), /currency/)
})

test('Any choices and fractional experience survive a save/load round trip', () => {
  const input = { ...ready, target_role: 'Any', location: 'any', skills: 'any', years_experience: '2.5' }
  assert.equal(validatePreferences(input), null)
  const saved = profileRecord(input, 'user-1')
  assert.equal(saved.years_experience, 2.5)
  assert.equal(readPreferences(saved).skills, 'any')
  assert.equal(profileRecord({ ...input, years_experience: 0 }, 'user-1').years_experience, 0)
  assert.equal(profileRecord({ ...input, years_experience: '' }, 'user-1').years_experience, null)
  assert.equal(readPreferences({}).years_experience, null)
  assert.equal(readPreferences({}).skills, 'any')
})

test('invalid experience and ambiguous Any lists are rejected', () => {
  for (const years_experience of [-1, 'abc', Infinity]) {
    assert.match(validatePreferences({ ...ready, years_experience }), /experience/)
  }
  for (const field of ['target_role', 'location', 'skills']) {
    assert.ok(validatePreferences({ ...ready, [field]: 'any, React' }))
    assert.ok(validatePreferences({ ...ready, [field]: 'React,' }))
  }
  assert.ok(validatePreferences({ ...ready, skills: '' }))
  assert.equal(validatePreferences({ ...ready, skills: 'React, C++, SQL', years_experience: 0 }), null)
})
