import firebaseFunctionsTest from 'firebase-functions-test';

// 1) Mock Rate Limiter
jest.mock('../rateLimiter', () => ({
    checkRateLimit: jest.fn().mockResolvedValue(undefined)
}));

// 2) Mock Firestore
const collectionMock = jest.fn();
jest.mock('firebase-admin/firestore', () => {
    return {
        getFirestore: jest.fn(() => ({
            collection: collectionMock,
        }))
    };
});

// 3) Mock Genkit to prevent external API calls to Google AI
jest.mock('firebase-functions/https', () => ({
    onCallGenkit: (options: any, flow: any) => {
        // Since we bypassed defineFlow, flow is just the async function
        // Return a mock wrapper matching what testEnv.wrap expects for Callable
        return async (req: any) => {
            return flow(req.data);
        };
    }
}));

jest.mock('@genkit-ai/firebase', () => ({
    enableFirebaseTelemetry: jest.fn()
}));

jest.mock('genkit', () => {
    const original = jest.requireActual('genkit');
    return {
        ...original,
        genkit: () => ({
            defineFlow: (meta: any, run: any) => {
                // Return an async function directly
                return async (req: any) => run(req);
            },
            generate: jest.fn().mockResolvedValue({
                output: {
                    results: [
                        { userId: 'test-doc-id', score: 85, reason: 'Great match!' }
                    ]
                }
            })
        })
    };
});

// Mock @genkit-ai/google-genai
jest.mock('@genkit-ai/google-genai', () => ({
    googleAI: Object.assign(jest.fn(), {
        model: jest.fn().mockReturnValue('mocked-model')
    })
}));

// Initialize Firebase Test env
const testEnv = firebaseFunctionsTest();

import { searchUsersWithAI } from '../aiSearch';

describe('AI Search Function', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    afterAll(() => {
        testEnv.cleanup();
    });

    it('returns empty results if no other users are found', async () => {
        // Do not use testEnv.wrap


        collectionMock.mockReturnValueOnce({
            get: jest.fn().mockResolvedValue({
                size: 1,
                docs: [
                    { id: 'caller-uid', data: () => ({ firstName: 'Me' }) }
                ]
            })
        } as any);

        // Direct invocation because we mocked onCallGenkit
        const result = await (searchUsersWithAI as any)({ data: { query: 'test', currentUserId: 'caller-uid' }, auth: { uid: 'caller-uid' } });
        expect(result).toEqual({ results: [] });
    });

    it('returns GenAI filtered matches when other users exist', async () => {
        // Do not use testEnv.wrap


        collectionMock.mockReturnValueOnce({
            get: jest.fn().mockResolvedValue({
                size: 2,
                docs: [
                    { id: 'caller-uid', data: () => ({ firstName: 'Me' }) },
                    { id: 'test-doc-id', data: () => ({ firstName: 'John', role: 'Dev' }) }
                ]
            })
        } as any);

        // Direct invocation
        const result = await (searchUsersWithAI as any)({ data: { query: 'find a dev', currentUserId: 'caller-uid' }, auth: { uid: 'caller-uid' } });
        expect(result).toEqual({
            results: [
                { userId: 'test-doc-id', score: 85, reason: 'Great match!' }
            ]
        });
    });
});
