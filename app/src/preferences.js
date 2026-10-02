export const defaultPreferences = {
  full_name: '', target_role: '', location: '', role_type: 'any', work_mode: 'any',
  salary_floor: null, salary_currency: null, salary_period: null,
  unknown_salary_policy: null, eligibility_policy: null,
  digest_time: '07:00', timezone: 'Asia/Kolkata', paused: false,
}

export function readPreferences(row) {
  return { ...defaultPreferences, ...row, digest_time: row?.digest_time?.slice(0, 5) || defaultPreferences.digest_time }
}

export function validatePreferences(value) {
  if (!value.target_role.trim()) return 'Enter at least one target role.'
  if (!value.location.trim()) return 'Enter at least one preferred location.'
  if (!value.unknown_salary_policy) return 'Choose how to handle jobs without salary information.'
  if (!value.eligibility_policy) return 'Choose how to handle unconfirmed eligibility.'
  if (!['any', 'full_time', 'internship'].includes(value.role_type)) return 'Choose a valid role type.'
  if (!['any', 'remote', 'hybrid', 'onsite'].includes(value.work_mode)) return 'Choose a valid work mode.'
  if (!['include_with_caveat', 'exclude'].includes(value.unknown_salary_policy)) return 'Choose a valid salary policy.'
  if (!['include_with_caveat', 'confirmed_only'].includes(value.eligibility_policy)) return 'Choose a valid eligibility policy.'
  if (!/^([01]\d|2[0-3]):[0-5]\d$/.test(value.digest_time)) return 'Choose a valid daily digest time.'
  if (value.salary_floor !== null && value.salary_floor !== '') {
    const amount = Number(value.salary_floor)
    if (!Number.isFinite(amount) || amount < 0) return 'Enter a valid salary floor of zero or more.'
    if (!value.salary_currency || !value.salary_period) return 'Choose a currency and period for your salary floor.'
    if (!/^[A-Z]{3}$/.test(value.salary_currency)) return 'Choose a valid currency.'
    if (!['year', 'month', 'hour'].includes(value.salary_period)) return 'Choose a valid salary period.'
  }
  try { new Intl.DateTimeFormat('en', { timeZone: value.timezone }) }
  catch { return 'Enter a valid IANA timezone, such as Asia/Kolkata.' }
  return null
}

export function profileRecord(value, userId) {
  const hasFloor = value.salary_floor !== null && value.salary_floor !== ''
  return {
    user_id: userId,
    full_name: value.full_name.trim(), target_role: value.target_role.trim(), location: value.location.trim(),
    role_type: value.role_type, work_mode: value.work_mode,
    salary_floor: hasFloor ? Number(value.salary_floor) : null,
    salary_currency: hasFloor ? value.salary_currency : null,
    salary_period: hasFloor ? value.salary_period : null,
    unknown_salary_policy: value.unknown_salary_policy,
    eligibility_policy: value.eligibility_policy,
    digest_time: value.digest_time, timezone: value.timezone, paused: value.paused,
  }
}
