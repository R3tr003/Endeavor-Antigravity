import firebaseFunctionsTest from 'firebase-functions-test';


const firestoreMock = {
    collection: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    get: jest.fn()
};

jest.mock('firebase-admin/firestore', () => {
    return {
        getFirestore: jest.fn(() => firestoreMock),
        Timestamp: {
            fromDate: jest.fn((d) => ({
                toMillis: () => d.getTime(),
                toDate: () => d
            }))
        }
    };
});

const testEnv = firebaseFunctionsTest();

import { icalFeed } from '../icalFeed';

describe('iCal Feed Function', () => {
    let req: any;
    let res: any;

    beforeEach(() => {
        jest.clearAllMocks();
        
        req = {
            query: {},
            headers: {},
            on: jest.fn()
        };
        
        res = {
            status: jest.fn().mockReturnThis(),
            send: jest.fn(),
            setHeader: jest.fn(),
            on: jest.fn()
        };
    });

    afterAll(() => {
        testEnv.cleanup();
    });

    it('returns 401 if token is missing', async () => {
        await new Promise((resolve) => {
            req.query = {};
            res.send.mockImplementation(() => resolve(null));
            icalFeed(req, res);
        });

        expect(res.status).toHaveBeenCalledWith(401);
        expect(res.send).toHaveBeenCalledWith('Unauthorized: missing token');
    });

    it('returns 401 if token is invalid', async () => {
        firestoreMock.get.mockResolvedValueOnce({ empty: true });

        req.query = { token: 'invalid' };
        
        await new Promise((resolve) => {
            res.send.mockImplementation(() => resolve(null));
            icalFeed(req, res);
        });

        expect(res.status).toHaveBeenCalledWith(401);
        expect(res.send).toHaveBeenCalledWith('Unauthorized: invalid token');
    });

    it('returns 401 if token is expired', async () => {
        const pastDate = new Date(Date.now() - 10000); // 10 seconds ago
        
        firestoreMock.get.mockResolvedValueOnce({
            empty: false,
            docs: [{
                data: () => ({
                    icalTokenExpiry: { toMillis: () => pastDate.getTime() }
                })
            }]
        });

        req.query = { token: 'valid_but_expired' };
        
        await new Promise((resolve) => {
            res.send.mockImplementation(() => resolve(null));
            icalFeed(req, res);
        });

        expect(res.status).toHaveBeenCalledWith(401);
        expect(res.send).toHaveBeenCalledWith('Unauthorized: token expired');
    });

    it('generates an iCal feed with events for a valid token', async () => {
        const futureDate = new Date(Date.now() + 10000);
        const eventStart = new Date();
        const eventEnd = new Date(Date.now() + 3600000);

        // First firestore mock call getting user
        firestoreMock.get.mockResolvedValueOnce({
            empty: false,
            docs: [{
                data: () => ({
                    id: 'user1',
                    icalTokenExpiry: { toMillis: () => futureDate.getTime() }
                })
            }]
        });

        // Second firestore mock call getting events
        firestoreMock.get.mockResolvedValueOnce({
            docs: [
                {
                    id: 'event1',
                    data: () => ({
                        title: 'Brainstorming',
                        description: 'Startup talks',
                        startDate: { toDate: () => eventStart },
                        endDate: { toDate: () => eventEnd },
                        location: 'Google Meet',
                        status: 'confirmed'
                    })
                }
            ]
        });

        req.query = { token: 'valid_token' };
        
        await new Promise((resolve) => {
            res.send.mockImplementation(() => resolve(null));
            icalFeed(req, res);
        });

        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.setHeader).toHaveBeenCalledWith('Content-Type', 'text/calendar; charset=utf-8');
        expect(res.send.mock.calls[0][0]).toContain('BEGIN:VCALENDAR');
        expect(res.send.mock.calls[0][0]).toContain('SUMMARY:Brainstorming');
        expect(res.send.mock.calls[0][0]).toContain('END:VCALENDAR');
    });
});
