import React, { useEffect, useState } from 'react'
import { supabase } from './supabase'

export default function Jobs() {
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
        const { data, error } = await supabase.from('job_cards')
          .select('id,title,company,location,application_url,last_seen_at')
          .order('title').order('id')
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
  }, [attempt])
  return <section aria-labelledby="jobs-heading">
    <div className="intro"><div><h1 id="jobs-heading">Jobs</h1><p>Collected postings. Matching to your preferences is coming next.</p></div></div>
    <p>Salary and eligibility are unconfirmed. Check the employer’s page for current availability and requirements.</p>
    {loading ? <p role="status">Loading jobs…</p> : error ? <div role="alert"><p>{error}</p><button onClick={() => setAttempt(n => n + 1)}>Try again</button></div> : jobs.length === 0 ? <p>No collected jobs are available yet. Check back after the next collection.</p> : <div className="job-list">{jobs.map(job => {
      let href
      try { const url = new URL(job.application_url); if (url.protocol === 'https:' && !url.username && !url.password) href = url.href } catch { /* Invalid source links are not clickable. */ }
      return <article className="card" key={job.id}>
        <h2>{job.title}</h2><p>{job.company} · {job.location || 'Location not listed'}</p>
        <p><small>Last collected: {new Date(job.last_seen_at).toLocaleString()}</small></p>
        {href ? <a href={href} target="_blank" rel="noopener noreferrer">Apply on employer site ↗</a> : <p>Application link unavailable.</p>}
      </article>
    })}</div>}
  </section>
}
