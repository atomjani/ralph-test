const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3847;

const RALPH_DIR = process.env.RALPH_DIR || path.join(process.env.HOME, 'ralph-test');
const SESSION_FILE = path.join(RALPH_DIR, '.ralph-tui', 'session.json');
const ITERATIONS_DIR = path.join(RALPH_DIR, '.ralph-tui', 'iterations');

app.use(express.static(path.join(__dirname, 'public')));

function readSession() {
    try {
        if (fs.existsSync(SESSION_FILE)) {
            return JSON.parse(fs.readFileSync(SESSION_FILE, 'utf8'));
        }
    } catch (e) {
        console.error('Error reading session:', e.message);
    }
    return null;
}

function readMeta() {
    const metaFile = SESSION_FILE.replace('session.json', 'session-meta.json');
    try {
        if (fs.existsSync(metaFile)) {
            return JSON.parse(fs.readFileSync(metaFile, 'utf8'));
        }
    } catch (e) {}
    return null;
}

function getIterations() {
    try {
        if (fs.existsSync(ITERATIONS_DIR)) {
            const files = fs.readdirSync(ITERATIONS_DIR).filter(f => f.endsWith('.log'));
            return files.map(f => ({
                file: f,
                mtime: fs.statSync(path.join(ITERATIONS_DIR, f)).mtime
            })).sort((a, b) => b.mtime - a.mtime).slice(0, 10);
        }
    } catch (e) {}
    return [];
}

app.get('/api/status', (req, res) => {
    const session = readSession();
    const meta = readMeta();
    
    if (!session) {
        return res.json({ error: 'No session found' });
    }
    
    res.json({
        sessionId: session.sessionId,
        status: session.status,
        agent: session.agentPlugin,
        cwd: session.cwd,
        currentIteration: session.currentIteration,
        maxIterations: session.maxIterations,
        tasksCompleted: session.tasksCompleted,
        totalTasks: session.trackerState?.totalTasks || 0,
        activeTasks: session.activeTaskIds || [],
        meta: meta
    });
});

app.get('/api/tasks', (req, res) => {
    const session = readSession();
    if (!session || !session.trackerState) {
        return res.json({ tasks: [] });
    }
    res.json({ tasks: session.trackerState.tasks || [] });
});

app.get('/api/history', (req, res) => {
    const session = readSession();
    if (!session) {
        return res.json({ iterations: [] });
    }
    res.json({ iterations: session.iterations || [] });
});

app.get('/api/processes', (req, res) => {
    const { execSync } = require('child_process');
    
    let processes = { ralph: [], opencode: [] };
    
    try {
        const ralph = execSync('ps aux | grep -E "[r]alph" | head -5', { encoding: 'utf8' });
        processes.ralph = ralph.trim().split('\n').filter(l => l);
    } catch (e) {}
    
    try {
        const opencode = execSync('ps aux | grep -E "[o]pencode" | head -5', { encoding: 'utf8' });
        processes.opencode = opencode.trim().split('\n').filter(l => l);
    } catch (e) {}
    
    res.json(processes);
});

app.get('/api/logs/:taskId', (req, res) => {
    const { taskId } = req.params;
    try {
        const files = fs.readdirSync(ITERATIONS_DIR).filter(f => f.includes(taskId));
        if (files.length > 0) {
            const latest = files.sort().pop();
            const content = fs.readFileSync(path.join(ITERATIONS_DIR, latest), 'utf8');
            return res.json({ log: content, file: latest });
        }
    } catch (e) {}
    res.json({ log: 'No logs found' });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Ralph Monitor: http://localhost:${PORT}`);
    console.log(`Ralph Dir: ${RALPH_DIR}`);
});
