const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// PostgreSQL connection pool
const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'appdb',
    user: process.env.DB_USER || 'appuser',
    password: process.env.DB_PASSWORD || 'apppassword',
    max: 20,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,
});

// Database initialization
async function initDatabase() {
    try {
        await pool.query(`
            CREATE TABLE IF NOT EXISTS records (
                id SERIAL PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                value INTEGER,
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        `);
        console.log('✓ Database initialized successfully');
    } catch (error) {
        console.error('✗ Database initialization failed:', error.message);
    }
}

// Health check endpoint
app.get('/api/health', async (req, res) => {
    try {
        // Check database connection
        const dbResult = await pool.query('SELECT NOW()');

        // Check replication status (if available)
        let replicationInfo = { active: false };
        try {
            const replResult = await pool.query(`
                SELECT pg_is_in_recovery() as is_replica,
                       pg_last_wal_receive_lsn() as receive_lsn,
                       pg_last_wal_replay_lsn() as replay_lsn
            `);
            replicationInfo = {
                active: true,
                isReplica: replResult.rows[0].is_replica,
                receiveLsn: replResult.rows[0].receive_lsn,
                replayLsn: replResult.rows[0].replay_lsn
            };
        } catch (replError) {
            // Replication query may fail on master or if not configured
            console.log('Replication info not available:', replError.message);
        }

        res.json({
            status: 'healthy',
            timestamp: new Date().toISOString(),
            server: {
                hostname: require('os').hostname(),
                uptime: process.uptime(),
                memory: process.memoryUsage()
            },
            database: {
                status: 'connected',
                timestamp: dbResult.rows[0].now,
                replication: replicationInfo
            }
        });
    } catch (error) {
        res.status(503).json({
            status: 'unhealthy',
            error: error.message
        });
    }
});

// Get all records
app.get('/api/data', async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM records ORDER BY created_at DESC LIMIT 10');
        res.json({
            success: true,
            count: result.rows.length,
            data: result.rows
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Create new record
app.post('/api/data', async (req, res) => {
    try {
        const { name, value, timestamp } = req.body;
        const result = await pool.query(
            'INSERT INTO records (name, value, timestamp) VALUES ($1, $2, $3) RETURNING *',
            [name, value, timestamp || new Date()]
        );
        res.status(201).json({
            success: true,
            message: 'Record created successfully',
            data: result.rows[0]
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Get statistics
app.get('/api/stats', async (req, res) => {
    try {
        const countResult = await pool.query('SELECT COUNT(*) as total FROM records');
        const avgResult = await pool.query('SELECT AVG(value) as average FROM records');
        const maxResult = await pool.query('SELECT MAX(value) as maximum FROM records');
        const minResult = await pool.query('SELECT MIN(value) as minimum FROM records');

        res.json({
            success: true,
            statistics: {
                totalRecords: parseInt(countResult.rows[0].total),
                averageValue: parseFloat(avgResult.rows[0].average) || 0,
                maximumValue: maxResult.rows[0].maximum || 0,
                minimumValue: minResult.rows[0].minimum || 0
            },
            database: {
                host: process.env.DB_HOST || 'localhost',
                name: process.env.DB_NAME || 'appdb'
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Root endpoint
app.get('/', (req, res) => {
    res.json({
        message: 'Welcome to 3-Tier Infrastructure API',
        version: '1.0.0',
        endpoints: {
            health: '/api/health',
            data: '/api/data',
            stats: '/api/stats'
        }
    });
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Error:', err.stack);
    res.status(500).json({
        success: false,
        error: 'Internal server error'
    });
});

// Start server
app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`💾 Database: ${process.env.DB_HOST || 'localhost'}:${process.env.DB_PORT || 5432}`);
    initDatabase();
});

// Graceful shutdown
process.on('SIGTERM', async () => {
    console.log('SIGTERM received, shutting down gracefully...');
    await pool.end();
    process.exit(0);
});
