// Configuration
const API_BASE_URL = window.location.protocol + '//' + window.location.hostname + ':3000';

// DOM Elements
const apiStatusCard = document.getElementById('api-status');
const dbStatusCard = document.getElementById('db-status');
const replicationStatusCard = document.getElementById('replication-status');
const apiResponseEl = document.getElementById('api-response');

// Buttons
const btnGetData = document.getElementById('btn-get-data');
const btnCreateData = document.getElementById('btn-create-data');
const btnStats = document.getElementById('btn-stats');

// Utility function to update status cards
function updateStatusCard(card, status, message) {
    const statusText = card.querySelector('.status-text');
    statusText.textContent = message;
    card.classList.remove('healthy', 'unhealthy', 'loading');
    if (status === 'healthy') {
        card.classList.add('healthy');
    } else if (status === 'unhealthy') {
        card.classList.add('unhealthy');
    } else {
        card.classList.add('loading');
    }
}

// Utility function to display API response
function displayResponse(data, error = false) {
    if (error) {
        apiResponseEl.textContent = `Error: ${data}`;
        apiResponseEl.style.color = '#ff6b6b';
    } else {
        apiResponseEl.textContent = JSON.stringify(data, null, 2);
        apiResponseEl.style.color = '#00ff00';
    }
}

// Check system health
async function checkHealth() {
    try {
        const response = await fetch(`${API_BASE_URL}/api/health`);
        const data = await response.json();
        
        if (data.status === 'healthy') {
            updateStatusCard(apiStatusCard, 'healthy', '✓ Online');
            updateStatusCard(dbStatusCard, 'healthy', data.database?.status === 'connected' ? '✓ Connected' : '✗ Disconnected');
            updateStatusCard(replicationStatusCard, 'healthy', data.database?.replication?.active ? '✓ Active' : '○ N/A');
        } else {
            updateStatusCard(apiStatusCard, 'unhealthy', '✗ Offline');
        }
    } catch (error) {
        console.error('Health check failed:', error);
        updateStatusCard(apiStatusCard, 'unhealthy', '✗ Unreachable');
        updateStatusCard(dbStatusCard, 'unhealthy', '✗ Unknown');
        updateStatusCard(replicationStatusCard, 'unhealthy', '✗ Unknown');
    }
}

// Get data from API
async function getData() {
    try {
        displayResponse('Loading...', false);
        const response = await fetch(`${API_BASE_URL}/api/data`);
        const data = await response.json();
        displayResponse(data);
    } catch (error) {
        displayResponse(error.message, true);
    }
}

// Create new data
async function createData() {
    try {
        displayResponse('Creating record...', false);
        const newRecord = {
            name: `Sample Record ${Date.now()}`,
            value: Math.floor(Math.random() * 1000),
            timestamp: new Date().toISOString()
        };
        
        const response = await fetch(`${API_BASE_URL}/api/data`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(newRecord)
        });
        
        const data = await response.json();
        displayResponse(data);
    } catch (error) {
        displayResponse(error.message, true);
    }
}

// Get statistics
async function getStats() {
    try {
        displayResponse('Loading statistics...', false);
        const response = await fetch(`${API_BASE_URL}/api/stats`);
        const data = await response.json();
        displayResponse(data);
    } catch (error) {
        displayResponse(error.message, true);
    }
}

// Event listeners
btnGetData.addEventListener('click', getData);
btnCreateData.addEventListener('click', createData);
btnStats.addEventListener('click', getStats);

// Initialize
checkHealth();
setInterval(checkHealth, 10000); // Check health every 10 seconds

// Display welcome message
displayResponse({
    message: 'Welcome to the 3-Tier Infrastructure Demo!',
    instructions: 'Click a button above to interact with the API',
    architecture: {
        loadBalancer: '1× Nginx',
        webServers: '2× Nginx',
        appServers: '2× Node.js',
        databases: '2× PostgreSQL (master + replica)'
    }
});
