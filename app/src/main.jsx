import React, { useEffect, useState } from 'react'
import { createRoot } from 'react-dom/client'
import { supabase } from './supabase'
import { defaultPreferences, profileRecord, readPreferences, validatePreferences } from './preferences'
import './style.css'

function App() {
  const [session, setSession] = useState(null)
  const [loading, setLoading] = useState(Boolean(supabase))
  const [profileLoading, setProfileLoading] = useState(false)
  const [email, setEmail] = useState('')
  const [profile, setProfile] = useState(defaultPreferences)
  const [message, setMessage] = useState('')
  const [saving, setSaving] = useState(false)
  const preview = !supabase
  const setField = (name, value) => setProfile(current => ({ ...current, [name]: value }))

  useEffect(() => {
    if (!supabase) {
      try { setProfile(readPreferences(JSON.parse(localStorage.getItem('roleping_preview_profile') || '{}'))) }
      catch { setProfile(defaultPreferences) }
      return
    }
    supabase.auth.getSession().then(({ data, error }) => {
      setSession(data?.session || null)
      if (error) setMessage(error.message)
      setLoading(false)
    })
    const { data } = supabase.auth.onAuthStateChange((_event, next) => setSession(next))
    return () => data.subscription.unsubscribe()
  }, [])

  useEffect(() => {
    if (!supabase) return
    setProfile(defaultPreferences)
    if (!session) return
    let active = true
    setProfileLoading(true)
    supabase.from('profiles')
      .select('full_name,target_role,location,role_type,work_mode,salary_floor,salary_currency,salary_period,unknown_salary_policy,eligibility_policy,digest_time,timezone,paused')
      .eq('user_id', session.user.id).maybeSingle().then(({ data, error }) => {
        if (!active) return
        if (data) setProfile(readPreferences(data))
        if (error) setMessage(error.message)
        setProfileLoading(false)
      })
    return () => { active = false }
  }, [session])

  async function signIn(event) {
    event.preventDefault()
    setMessage('')
    const { error } = await supabase.auth.signInWithOtp({ email, options: { emailRedirectTo: window.location.origin } })
    setMessage(error ? error.message : 'Check your email for a sign-in link.')
  }

  async function save(event) {
    event.preventDefault()
    const problem = validatePreferences(profile)
    if (problem) { setMessage(problem); return }
    setSaving(true)
    setMessage('')
    try {
      if (preview) {
        localStorage.setItem('roleping_preview_profile', JSON.stringify(profile))
        setMessage('Saved in this browser only. Sign in to sync settings.')
      } else {
        const { error } = await supabase.from('profiles').upsert(profileRecord(profile, session.user.id))
        setMessage(error ? error.message : 'Settings saved.')
      }
    } catch (error) { setMessage(error.message || 'Could not save settings.') }
    finally { setSaving(false) }
  }

  return <main className="app">
    <header><strong><span className="mark">↗</span> Role Ping</strong><small>Early build</small></header>
    <div className="content">
      {preview && <p className="notice">Local preview: settings stay in this browser. Signed-in settings are saved to Supabase.</p>}
      {loading ? <p>Checking your session…</p> : !preview && !session ? <section className="card auth">
        <h1>Sign in</h1><p>Enter your email to receive a sign-in link.</p>
        <form onSubmit={signIn}><label>Email address<input type="email" required value={email} onChange={e => setEmail(e.target.value)} placeholder="you@example.com"/></label><button>Send sign-in link</button></form>
      </section> : <>
        <div className="intro"><div><h1>Job preferences</h1><p>Set your search and delivery choices. Job collection and notifications are still being built.</p></div>{session && <button className="secondary" onClick={() => supabase.auth.signOut()}>Sign out</button>}</div>
        {profileLoading ? <p>Loading your settings…</p> : <section className="card"><form onSubmit={save}>
          <h2>Search</h2><div className="grid">
            <label>Your name<input maxLength="120" value={profile.full_name} onChange={e => setField('full_name', e.target.value)} placeholder="Your name"/></label>
            <label>Target roles<input maxLength="300" value={profile.target_role} onChange={e => setField('target_role', e.target.value)} placeholder="e.g. Frontend engineer"/></label>
            <label>Preferred locations<input maxLength="300" value={profile.location} onChange={e => setField('location', e.target.value)} placeholder="e.g. Bengaluru, Remote"/></label>
            <label>Role type<select value={profile.role_type} onChange={e => setField('role_type', e.target.value)}><option value="any">Any</option><option value="full_time">Full-time</option><option value="internship">Internship</option></select></label>
            <label>Work mode<select value={profile.work_mode} onChange={e => setField('work_mode', e.target.value)}><option value="any">Any</option><option value="remote">Remote</option><option value="hybrid">Hybrid</option><option value="onsite">On-site</option></select></label>
          </div>
          <h2>Compensation and eligibility</h2><div className="grid">
            <label>Minimum salary (optional)<input type="number" min="0" step="0.01" value={profile.salary_floor ?? ''} onChange={e => setProfile(current => ({ ...current, salary_floor: e.target.value || null, ...(e.target.value ? {} : { salary_currency: null, salary_period: null }) }))} placeholder="No minimum"/></label>
            <label>Currency<select disabled={profile.salary_floor === null || profile.salary_floor === ''} value={profile.salary_currency ?? ''} onChange={e => setField('salary_currency', e.target.value || null)}><option value="">Choose</option><option value="INR">INR</option><option value="USD">USD</option></select></label>
            <label>Salary period<select disabled={profile.salary_floor === null || profile.salary_floor === ''} value={profile.salary_period ?? ''} onChange={e => setField('salary_period', e.target.value || null)}><option value="">Choose</option><option value="year">Per year</option><option value="month">Per month</option><option value="hour">Per hour</option></select></label>
            <label>When salary is not listed<select value={profile.unknown_salary_policy ?? ''} onChange={e => setField('unknown_salary_policy', e.target.value || null)}><option value="">Choose a policy</option><option value="include_with_caveat">Show with a caveat</option><option value="exclude">Exclude the job</option></select></label>
            <label>When eligibility is unconfirmed<select value={profile.eligibility_policy ?? ''} onChange={e => setField('eligibility_policy', e.target.value || null)}><option value="">Choose a policy</option><option value="include_with_caveat">Show with a caveat</option><option value="confirmed_only">Confirmed only</option></select></label>
          </div>
          <h2>Delivery</h2><div className="grid">
            <label>Daily digest time<input type="time" value={profile.digest_time} onChange={e => setField('digest_time', e.target.value)}/></label>
            <label>Timezone<input maxLength="100" value={profile.timezone} onChange={e => setField('timezone', e.target.value)} placeholder="Asia/Kolkata"/></label>
          </div>
          <label className="pause"><input type="checkbox" checked={profile.paused} onChange={e => setField('paused', e.target.checked)}/><span>Pause future notifications <small>Delivery is not active yet.</small></span></label>
          <div className="actions"><button disabled={saving}>{saving ? 'Saving…' : 'Save settings'}</button></div>
        </form></section>}
      </>}
      {message && <p className="message" role="status">{message}</p>}
    </div>
  </main>
}

createRoot(document.getElementById('root')).render(<App />)
