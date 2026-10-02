import React, { useEffect, useState } from 'react'
import { supabase } from './supabase'

export default function Jobs() {
  const [mode, setMode] = useState('matches')
  const [jobs, setJobs] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [attempt, setAttempt] = useState(0)
  useEffect(() => {
    let active = true
    setLoading(true)
    setError('')
    async function load() {
      try {
        const request = mode === 'matches' ? supabase.rpc('match_job_cards') : supabase.from('job_cards')
          .select('id,title,company,location,application_url,last_seen_at')
          .order('title').order('id')
        const { data, error } = await request
        if (error) throw error
        if (active) setJobs(data || [])
      } catch {
        if (active) setError('Could not load jobs. Please try again.')
      } finally {
        if (active) setLoading(false)
      }
    }
    load()
    return () => { active = false }
  }, [attempt, mode])
  return <section aria-labelledby="jobs-heading">
    <div className="intro"><div><h1 id="jobs-heading">Jobs</h1><p>Matches use your saved role terms and locations. Separate alternatives with commas in Preferences.</p></div></div>
    <nav className="page-nav" aria-label="Job results"><button className="secondary" aria-pressed={mode === 'matches'} onClick={() => setMode('matches')}>Matching jobs</button><button className="secondary" aria-pressed={mode === 'all'} onClick={() => setMode('all')}>All jobs</button></nav>
    <p>Salary and eligibility are unconfirmed. Check the employer’s page for current availability and requirements.</p>
    {loading ? <p role="status">Loading jobs…</p> : error ? <div role="alert"><p>{error}</p><button onClick={() => setAttempt(n => n + 1)}>Try again</button></div> : jobs.length === 0 ? <p>{mode === 'matches' ? 'No matches for your saved preferences. Check your role terms and locations. Requiring confirmed eligibility or excluding unknown salary currently removes all postings from this feed. All jobs remain available in the All jobs tab.' : 'No collected jobs are available yet. Check back after the next collection.'}</p> : <div className="job-list">{jobs.map(job => {
      let href
      try { const url = new URL(job.application_url); if (url.protocol === 'https:' && !url.username && !url.password) href = url.href } catch { /* Invalid source links are not clickable. */ }
      return <article className="card" key={job.id}>
        <h2>{job.title}</h2><p>{job.company} · {job.location || 'Location not listed'}</p>
        <p><small>Last collected: {new Date(job.last_seen_at).toLocaleString()}</small></p>
        {job.reasons && <><h3>Why this appeared</h3><ul>{job.reasons.map(reason => <li key={reason}>{reason}</li>)}</ul><ul>{job.caveats.map(caveat => <li key={caveat}>{caveat}</li>)}</ul></>}
        {href ? <a href={href} target="_blank" rel="noopener noreferrer">Apply on employer site ↗</a> : <p>Application link unavailable.</p>}
      </article>
    })}</div>}
  </section>
}
