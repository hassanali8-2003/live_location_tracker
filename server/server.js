const express = require('express');
const http = require('http');
const path = require('path');
const { Server } = require('socket.io');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.static(__dirname));

const server = http.createServer(app);
const io = new Server(server, {
    cors: {
        origin: '*',
        methods: ['GET', 'POST'],
    },
});

const trackedDevices = new Map();
const socketToDevice = new Map();

function buildSnapshot() {
    return Array.from(trackedDevices.values()).sort((a, b) =>
        a.deviceName.localeCompare(b.deviceName)
    );
}

function emitSnapshot() {
    io.emit('devicesSnapshot', buildSnapshot());
}

function normalizeRegisterPayload(payload, socket) {
    if (typeof payload === 'string') {
        return {
            deviceId: payload,
            deviceName: payload,
            platform: 'unknown',
            socketId: socket.id,
            isOnline: true,
        };
    }

    return {
        deviceId: String(payload?.deviceId || payload?.userId || socket.id),
        deviceName: String(payload?.deviceName || payload?.userId || 'Unknown Device'),
        platform: String(payload?.platform || 'unknown'),
        socketId: socket.id,
        isOnline: true,
    };
}

io.on('connection', (socket) => {
    console.log('Connected:', socket.id);
    socket.emit('devicesSnapshot', buildSnapshot());

    socket.on('register', (payload) => {
        const device = normalizeRegisterPayload(payload, socket);
        const previous = trackedDevices.get(device.deviceId) || {};

        trackedDevices.set(device.deviceId, {
            ...previous,
            ...device,
            timestamp: previous.timestamp || new Date().toISOString(),
        });
        socketToDevice.set(socket.id, device.deviceId);
        emitSnapshot();
    });

    socket.on('updateLocation', (data) => {
        const deviceId = String(
            data?.deviceId || data?.userId || socketToDevice.get(socket.id) || socket.id
        );
        const previous = trackedDevices.get(deviceId) || {};
        const device = {
            ...previous,
            deviceId,
            deviceName: String(data?.deviceName || previous.deviceName || deviceId),
            platform: String(data?.platform || previous.platform || 'unknown'),
            lat: Number(data?.lat),
            lng: Number(data?.lng),
            accuracy: data?.accuracy == null ? null : Number(data.accuracy),
            speed: data?.speed == null ? null : Number(data.speed),
            timestamp: data?.timestamp || new Date().toISOString(),
            socketId: socket.id,
            isOnline: true,
        };

        trackedDevices.set(deviceId, device);
        socketToDevice.set(socket.id, deviceId);

        console.log(`Update from ${deviceId}:`, device.lat, device.lng);
        io.emit('locationChanged', device);
        emitSnapshot();
    });

    socket.on('disconnect', () => {
        console.log('Disconnected:', socket.id);
        const deviceId = socketToDevice.get(socket.id);
        socketToDevice.delete(socket.id);

        if (!deviceId || !trackedDevices.has(deviceId)) {
            return;
        }

        trackedDevices.set(deviceId, {
            ...trackedDevices.get(deviceId),
            isOnline: false,
            socketId: null,
            timestamp: new Date().toISOString(),
        });
        emitSnapshot();
    });
});

app.get('/', (_, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
    console.log(`GeoTrack Server running on port ${PORT}`);
});
