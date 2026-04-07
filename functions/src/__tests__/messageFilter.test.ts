import firebaseFunctionsTest from 'firebase-functions-test';

// 1) Mock Rate Limiter
jest.mock('../rateLimiter', () => ({
    checkRateLimit: jest.fn().mockResolvedValue(undefined)
}));

// 2) Mock Firestore for both default and 'messaging' databases
const defaultDbMock = {
    collection: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnThis(),
    get: jest.fn()
};
const messagingDbMock = {
    collection: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnThis(),
    orderBy: jest.fn().mockReturnThis(),
    get: jest.fn(),
    update: jest.fn(),
    set: jest.fn()
};

jest.mock('firebase-admin/firestore', () => {
    return {
        getFirestore: jest.fn((dbId) => dbId === 'messaging' ? messagingDbMock : defaultDbMock)
    };
});

// 3) Mock GenAI
jest.mock('@google/genai', () => ({
    GoogleGenAI: jest.fn().mockImplementation(() => ({
        models: {
            generateContent: jest.fn().mockResolvedValue({
                text: '{"isSpam": true, "reason": "Violating rules", "confidence": 0.95}'
            })
        }
    }))
}));

// Mock Secret value method!
jest.mock('firebase-functions/params', () => ({
    defineSecret: () => ({ value: () => 'fake-api-key' })
}));

const testEnv = firebaseFunctionsTest();

import { recheckConversation } from '../messageFilter';
import { HttpsError } from 'firebase-functions/v2/https';

describe('Message Filter: recheckConversation', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    afterAll(() => {
        testEnv.cleanup();
    });

    it('throws unauthenticated if no auth is provided', async () => {
        const wrapped = testEnv.wrap(recheckConversation);
        await expect(wrapped({ data: {} } as any)).rejects.toThrow(HttpsError);
    });

    it('verifies permission mapping and identifies spam conversation successfully', async () => {
        const wrapped = testEnv.wrap(recheckConversation);

        // Provide a robust mock implementation for `get`
        messagingDbMock.get.mockImplementation(async function(this: any) {
            // Check if this is a collection get (e.g., messagesSnap)
            // Or a document get (e.g., convSnap)
            if (this && this.docs) {
               // We spoof the array by returning what messagesSnap expects
               return {
                   docs: [
                       { data: () => ({ isSystemMessage: false, senderId: 'abc', text: 'buy my crypto' }) }
                   ]
               };
            }
            return {
                exists: true,
                data: () => ({ participantIds: ['mock-sf-uuid'] })
            };
        });

        // Ensure collection/doc chaining preserves a recognizable state if needed,
        // or just rely on the above simple fallback assuming `orderBy` or `collection` 
        // doesn't strip the context.
        // Actually simpler:
        messagingDbMock.get = jest.fn().mockImplementation(() => {
            // If it was called after getting 'messages' collection:
            // The simplest is to just return docs always if we don't care, but convSnap wants exists.
            return Promise.resolve({
                exists: true,
                data: () => ({ participantIds: ['mock-sf-uuid'] }),
                docs: [
                    { data: () => ({ isSystemMessage: false, senderId: 'abc', text: 'buy my crypto' }) }
                ]
            });
        });

        defaultDbMock.get = jest.fn().mockImplementation(() => {
            return Promise.resolve({
                exists: true,
                data: () => ({ uuid: 'mock-sf-uuid', firstName: 'Spammer' })
            });
        });


        const result = await wrapped({ 
            data: { conversationId: 'c123' }, 
            auth: { uid: 'caller-uid' } 
        } as any);

        expect(result).toEqual({ filtered: true, reason: 'Violating rules' });
    });
});
