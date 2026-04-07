module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testMatch: ['**/__tests__/**/*.test.ts'],
  reporters: [
    "default",
    "<rootDir>/jestReporter.js"
  ]
};
