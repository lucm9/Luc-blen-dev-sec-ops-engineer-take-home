import { NextApiRequest, NextApiResponse } from 'next'
import { Pool } from 'pg'

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: parseInt(process.env.DB_PORT || '5432'),
})

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  try {
    const client = await pool.connect()
    const result = await client.query('SELECT 1')
    client.release()
    res.status(200).json({ message: 'Successfully connected to the database', success: true })
  } catch (err) {
    console.error(err)
    res.status(500).json({ message: 'Failed to connect to the database', success: false })
  }
}