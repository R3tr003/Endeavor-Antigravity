import firebaseFunctionsTest from 'firebase-functions-test';

const mockedFetch = jest.fn();
global.fetch = mockedFetch as any;

jest.mock('../rateLimiter', () => ({
    checkRateLimit: jest.fn().mockResolvedValue(undefined)
}));

const firestoreMock = {
    collection: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnThis(),
    get: jest.fn(),
    update: jest.fn()
};

jest.mock('firebase-admin/firestore', () => {
    return {
        getFirestore: jest.fn(() => firestoreMock)
    };
});

const testEnv = firebaseFunctionsTest();

import { generateMeetLink, cancelCalendarEvent } from '../meetProvider';

describe('Meet Provider tests', () => {
    let mockDb: any;

    beforeEach(() => {
        jest.clearAllMocks();
        mockDb = firestoreMock;
    });

    afterAll(() => {
        testEnv.cleanup();
    });

    describe('generateMeetLink', () => {
        it('throws if no valid arguments are provided', async () => {
            const wrapped = testEnv.wrap(generateMeetLink);
            await expect(wrapped({ data: {}, auth: { uid: 'user1' } } as any)).rejects.toThrow();
        });

        it('returns forbidden if the user is not a participant', async () => {
            mockDb.get.mockResolvedValueOnce({
                exists: true,
                data: () => ({ participantIds: ['user2'] })
            });

            const wrapped = testEnv.wrap(generateMeetLink);
            await expect(wrapped({
                data: { eventId: 'e1', provider: 'google_meet', userId: 'user1', googleAccessToken: 'token' },
                auth: { uid: 'user1' }
            } as any)).rejects.toThrow('Forbidden');
        });

        it('succesfully generates a google meet link', async () => {
            mockDb.get.mockResolvedValueOnce({
                exists: true,
                data: () => ({
                    participantIds: ['user1'],
                    startDate: { toDate: () => new Date() },
                    endDate: { toDate: () => new Date() },
                    title: 'Test Meet'
                })
            });

            mockedFetch.mockResolvedValueOnce({
                ok: true,
                status: 200,
                json: async () => ({
                    id: 'cal123',
                    conferenceData: { entryPoints: [{ entryPointType: 'video', uri: 'https://meet.google.com/abc' }] }
                })
            } as any);

            const wrapped = testEnv.wrap(generateMeetLink);

            const result = await wrapped({
                data: { eventId: 'e1', provider: 'google_meet', userId: 'user1', googleAccessToken: 'token' },
                auth: { uid: 'user1' }
            } as any);

            expect(result).toEqual({ meetLink: 'https://meet.google.com/abc' });
            expect(mockDb.update).toHaveBeenCalledWith({
                meetLink: 'https://meet.google.com/abc',
                googleCalendarEventId: 'cal123'
            });
        });

        it('succesfully generates a microsoft teams link', async () => {
            mockDb.get.mockResolvedValueOnce({
                exists: true,
                data: () => ({
                    participantIds: ['user1'],
                    startDate: { toDate: () => new Date() },
                    endDate: { toDate: () => new Date() }
                })
            });

            mockedFetch.mockResolvedValueOnce({
                ok: true,
                status: 200,
                json: async () => ({ joinWebUrl: 'https://teams.microsoft.com/link' })
            } as any);

            const wrapped = testEnv.wrap(generateMeetLink);

            const result = await wrapped({
                data: { eventId: 'e1', provider: 'microsoft_teams', userId: 'user1', microsoftAccessToken: 'token' },
                auth: { uid: 'user1' }
            } as any);

            expect(result).toEqual({ meetLink: 'https://teams.microsoft.com/link' });
            expect(mockDb.update).toHaveBeenCalledWith({ meetLink: 'https://teams.microsoft.com/link' });
        });
    });

    describe('cancelCalendarEvent', () => {
        it('returns success if event is not found', async () => {
            mockDb.get.mockResolvedValueOnce({ exists: false });
            const wrapped = testEnv.wrap(cancelCalendarEvent);
            const result = await wrapped({ data: { eventId: 'x', googleAccessToken: 'token' }, auth: { uid: 'user' } } as any);
            expect(result).toEqual({ success: true });
        });

        it('deletes google event successfully', async () => {
            mockDb.get.mockResolvedValueOnce({
                exists: true,
                data: () => ({ googleCalendarEventId: 'cal_x' })
            });

            mockedFetch.mockResolvedValueOnce({ ok: true, status: 200 } as any);

            const wrapped = testEnv.wrap(cancelCalendarEvent);
            const result = await wrapped({ data: { eventId: 'x', googleAccessToken: 'token' }, auth: { uid: 'user' } } as any);

            expect(result).toEqual({ success: true });
            expect(mockedFetch).toHaveBeenCalledWith(
                expect.stringContaining('cal_x'),
                expect.objectContaining({ method: 'DELETE' })
            );
            expect(mockDb.update).toHaveBeenCalledWith({ googleCalendarEventId: null });
        });
    });
});
