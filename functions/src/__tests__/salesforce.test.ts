import * as admin from 'firebase-admin';
import firebaseFunctionsTest from 'firebase-functions-test';
import fetch from 'node-fetch';

jest.mock('node-fetch');
const mockedFetch = fetch as jest.MockedFunction<typeof fetch>;

// Mock the firebase-admin module completely to prevent live database mutations
jest.mock('firebase-admin', () => {
    const firestoreMock = {
        collection: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn()
    };
    return {
        initializeApp: jest.fn(),
        apps: [],
        firestore: jest.fn(() => firestoreMock),
    };
});

// Mock rateLimiter to always succeed
jest.mock('../rateLimiter', () => ({
    checkRateLimit: jest.fn().mockResolvedValue(undefined)
}));

const testEnv = firebaseFunctionsTest();

import { 
    checkUserExists, 
    checkSalesforceAuthorization, 
    getSalesforceContactData, 
    checkAndFetchSalesforceContact 
} from '../salesforce';

describe('Salesforce Functions', () => {
    let firestoreMock: any;

    beforeEach(() => {
        jest.clearAllMocks();
        firestoreMock = admin.firestore();
        
        // Setup minimal mock for Salesforce OAuth fetch by default
        mockedFetch.mockImplementation(async (url: any) => {
            if (url.toString().includes('/oauth2/token')) {
                return {
                    ok: true,
                    json: async () => ({ access_token: 'fake-token' })
                } as any;
            }
            return {
                ok: true,
                json: async () => ({ records: [] })
            } as any;
        });

        // Set env vars
        process.env.SALESFORCE_CLIENT_ID = 'test-id';
        process.env.SALESFORCE_CLIENT_SECRET = 'test-secret';
    });

    afterAll(() => {
        testEnv.cleanup();
    });

    // ------------------------------------------------------------------------
    // checkUserExists
    // ------------------------------------------------------------------------
    describe('checkUserExists', () => {
        it('throws invalid-argument error if email is missing', async () => {
            const wrapped = testEnv.wrap(checkUserExists);
            await expect(wrapped({ data: { email: '' } } as any)).rejects.toThrow('Email is required.');
        });

        it('returns { exists: false } if the user document is not found', async () => {
            const wrapped = testEnv.wrap(checkUserExists);
            (firestoreMock.collection('users').where('email', '==', 'missing@test.com').get as jest.Mock).mockResolvedValueOnce({
                empty: true,
                docs: []
            });

            const result = await wrapped({ data: { email: 'missing@test.com' } } as any);
            expect(result).toEqual({ exists: false });
        });

        it('returns { exists: true } and the correct userId when user and company are found', async () => {
            const wrapped = testEnv.wrap(checkUserExists);
            (firestoreMock.collection('users').where('email', '==', 'found@test.com').get as jest.Mock).mockResolvedValueOnce({
                empty: false,
                docs: [{ data: () => ({ id: 'mock-user-id' }) }]
            });
            (firestoreMock.collection('companies').where('userId', '==', 'mock-user-id').get as jest.Mock).mockResolvedValueOnce({
                empty: false,
                docs: [{ data: () => ({ name: 'Mock Company' }) }]
            });

            const result = await wrapped({ data: { email: 'found@test.com' } } as any);
            expect(result).toEqual({ exists: true, userId: 'mock-user-id' });
        });
    });

    // ------------------------------------------------------------------------
    // checkSalesforceAuthorization
    // ------------------------------------------------------------------------
    describe('checkSalesforceAuthorization', () => {
        it('throws if email missing', async () => {
            const wrapped = testEnv.wrap(checkSalesforceAuthorization);
            await expect(wrapped({ data: {} } as any)).rejects.toThrow('Email is required.');
        });

        it('returns authorized: false when SOQL returns zero records', async () => {
            const wrapped = testEnv.wrap(checkSalesforceAuthorization);
            const result = await wrapped({ data: { email: 'notinsf@test.com' } } as any);
            expect(result).toEqual({ authorized: false });
        });

        it('returns authorized: true and contactId when SOQL finds a record', async () => {
            mockedFetch.mockImplementation(async (url: any) => {
                if (url.toString().includes('/oauth2/token')) {
                    return { ok: true, json: async () => ({ access_token: 'fake-token' }) } as any;
                }
                return {
                    ok: true,
                    json: async () => ({ records: [{ Id: 'mock-sf-id' }] })
                } as any;
            });

            const wrapped = testEnv.wrap(checkSalesforceAuthorization);
            const result = await wrapped({ data: { email: 'insf@test.com' } } as any);
            expect(result).toEqual({ authorized: true, contactId: 'mock-sf-id' });
        });
    });

    // ------------------------------------------------------------------------
    // getSalesforceContactData
    // ------------------------------------------------------------------------
    describe('getSalesforceContactData', () => {
        it('throws if contactId missing', async () => {
            const wrapped = testEnv.wrap(getSalesforceContactData);
            await expect(wrapped({ data: {} } as any)).rejects.toThrow('contactId is required.');
        });

        it('parses languages correctly and maps fields', async () => {
            mockedFetch.mockImplementation(async (url: any) => {
                if (url.toString().includes('/oauth2/token')) {
                    return { ok: true, json: async () => ({ access_token: 'fake-token' }) } as any;
                }
                return {
                    ok: true,
                    json: async () => ({ 
                        records: [{ 
                            Id: 'mock-sf-id',
                            FirstName: 'John',
                            LastName: 'Doe',
                            Language_Capabilities__c: 'English; Spanish',
                            Account: { Name: 'Acme Corp' }
                        }] 
                    })
                } as any;
            });

            const wrapped = testEnv.wrap(getSalesforceContactData);
            const result = await wrapped({ data: { contactId: 'mock-sf-id' } } as any);
            
            expect(result.firstName).toBe('John');
            expect(result.languages).toEqual(['English', 'Spanish']);
            expect(result.companyName).toBe('Acme Corp');
        });
    });

    // ------------------------------------------------------------------------
    // checkAndFetchSalesforceContact
    // ------------------------------------------------------------------------
    describe('checkAndFetchSalesforceContact', () => {
        it('throws if email missing', async () => {
            const wrapped = testEnv.wrap(checkAndFetchSalesforceContact);
            await expect(wrapped({ data: {} } as any)).rejects.toThrow('Email is required.');
        });

        it('functions correctly combining authorization and data pulling', async () => {
            mockedFetch.mockImplementation(async (url: any) => {
                if (url.toString().includes('/oauth2/token')) {
                    return { ok: true, json: async () => ({ access_token: 'fake-token' }) } as any;
                }
                return {
                    ok: true,
                    json: async () => ({ 
                        records: [{ 
                            Id: 'mock-sf-id',
                            FirstName: 'Jane',
                            LastName: 'Doe'
                        }] 
                    })
                } as any;
            });

            const wrapped = testEnv.wrap(checkAndFetchSalesforceContact);
            const result = await wrapped({ data: { email: 'jane@test.com' }, auth: { uid: 'mock-uid' } } as any);
            expect(result.authorized).toBe(true);
            expect(result.contactId).toBe('mock-sf-id');
            expect(result.firstName).toBe('Jane');
        });
    });
});
