// File: pages/index.tsx
import { useState, useEffect } from 'react'

export default function Home() {
  const [dbStatus, setDbStatus] = useState<string>('Checking...')
  const [isConnected, setIsConnected] = useState<boolean | null>(null)

  useEffect(() => {
    fetch('/api/db-check')
      .then(res => res.json())
      .then(data => {
        setDbStatus(data.message)
        setIsConnected(data.success)
      })
      .catch(() => {
        setDbStatus('Failed to connect to database')
        setIsConnected(false)
      })
  }, [])

  const getStatusIcon = () => {
    if (isConnected === null) return '⏳' // Hourglass for checking
    return isConnected ? '🟢' : '🔴'  // Green circle for success, red circle for failure
  }

  return (
    <div>
      <main>
        <h1>
          Welcome to BLEN DevSecOps Challenge
        </h1>
        <p>
          Innovating with Security and Efficiency
        </p>
        <p>
          Database Connection Status: {getStatusIcon()} {dbStatus}
        </p>
        <p>
          This sample application demonstrates a basic Next.js setup with database connectivity.
        </p>
        <p>
          Your task is to deploy this securely in an AWS environment. Good luck!
        </p>
      </main>
    </div>
  )
}