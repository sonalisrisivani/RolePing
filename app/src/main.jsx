import React, { useEffect, useState } from 'react'
import { createRoot } from 'react-dom/client'
import { supabase } from './supabase'
import './style.css'

const defaults = { full_name: '', target_role: '', location: '', digest_time: '07:00', timezone: 'Asia/Kolkata', paused: false }

function App() {
  const [session, setSession] = useState(null)
  const [loading, setLoading] = useState(Boolean(supabase))
  const [email, setEmail] = useState('')
  const [profile, setProfile] = useState(defaults)
  const [message, setMessage] = useState('')
  const [saving, setSaving] = useState(false)
  const preview = !supabase

  useEffect(() => {
    if (!supabase) {
      try { setProfile({ ...defaults, ...JSON.parse(localStorage.getItem('roleping_preview_profile') || '{}') }) } catch { /* Ignore invalid local data. */ }
      return
    }
    supabase.auth.getSession().then(({ data, error }) => { setSession(data?.session || null); setLoading(false); if (error) setMessage(error.message) })
    const { data } = supabase.auth.onAuthStateChange((_event, next) => setSession(next))
    return () => data.subscription.unsubscribe()
  }, [])

  useEffect(() => {
    if (!supabase || !session) return
    let active = true
    supabase.from('profiles').select('full_name,target_role,location,digest_time,timezone,paused').eq('user_id', session.user.id).maybeSingle().then(({ data, error }) => {
      if (!active) return
      if (data) setProfile({ ...defaults, ...data })
      if (error) setMessage(error.message)
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
    setSaving(true)
    if (preview) {
      localStorage.setItem('roleping_preview_profile', JSON.stringify(profile))
      setMessage('Saved in this browser only. Connect Supabase for an account.')
    } else {
      const { error } = await supabase.from('profiles').upsert({ ...profile, user_id: session.user.id })
      setMessage(error ? error.message : 'Settings saved.')
    }
    setSaving(false)
  }

  return <main className="app">
    <header><strong><span className="mark">↗</span> Role Ping</strong><small>Early build</small></header>
    <div className="content">
      {preview && <p className="notice">Local preview: settings stay in this browser. Supabase setup enables sign-in and synced settings.</p>}
      {loading ? <p>Checking your session…</p> : !preview && !session ? <section className="card auth"><h1>Sign in</h1><p>Enter your email to receive a sign-in link.</p><form onSubmit={signIn}><label>Email address<input type="email" required value={email} onChange={e => setEmail(e.target.value)} placeholder="you@example.com"/></label><button>Send sign-in link</button></form></section> : <>
        <div className="intro"><div><h1>Job preferences</h1><p>Set your starting preferences. Job collection and notifications are still being built.</p></div>{session && <button className="secondary" onClick={() => supabase.auth.signOut()}>Sign out</button>}</div>
        <section className="card"><form onSubmit={save}><div className="grid">
          <label>Your name<input maxLength="120" value={profile.full_name} onChange={e => setProfile({ ...profile, full_name: e.target.value })} placeholder="Your name"/></label>
          <label>Target roles<input maxLength="300" value={profile.target_role} onChange={e => setProfile({ ...profile, target_role: e.target.value })} placeholder="e.g. Frontend engineer"/></label>
          <label>Preferred locations<input maxLength="300" value={profile.location} onChange={e => setProfile({ ...profile, location: e.target.value })} placeholder="e.g. Bengaluru, Remote"/></label>
          <label>Daily digest time<input type="time" value={profile.digest_time} onChange={e => setProfile({ ...profile, digest_time: e.target.value })}/></label>
          <label>Timezone<input maxLength="100" value={profile.timezone} onChange={e => setProfile({ ...profile, timezone: e.target.value })} placeholder="Asia/Kolkata"/></label>
        </div><label className="pause"><input type="checkbox" checked={profile.paused} onChange={e => setProfile({ ...profile, paused: e.target.checked })}/><span>Pause future notifications <small>Delivery is not active yet.</small></span></label><div className="actions"><button disabled={saving}>{saving ? 'Saving…' : 'Save settings'}</button></div></form></section>
        <section className="next"><strong>Available now</strong><p>Private profile settings when connected to Supabase. In preview mode, only a local browser draft is saved.</p><strong>Next</strong><p>Real job collection, matching, shortlist actions, and delivery.</p></section>
      </>}
      {message && <p className="message" role="status">{message}</p>}
    </div>
  </main>
}

createRoot(document.getElementById('root')).render(<App />)
