const fs = require('fs');
const path = require('path');

class MarkdownReporter {
  constructor(globalConfig, options) {
    this._globalConfig = globalConfig;
    this._options = options;
  }

  onRunComplete(contexts, results) {
    const reportPath = path.join(__dirname, 'src', '__tests__', 'TEST_REPORT.md');
    
    const dateStr = new Date().toLocaleString('en-US', { timeZoneName: 'short' });
    
    let markdown = `# Backend Test Report (Firebase Functions)\n\n`;
    
    markdown += `> This report is automatically generated every time \`npm test\` is executed.\n\n`;
    
    markdown += `**Last Executed**: ${dateStr}\n\n`;
    
    markdown += `## 📊 Summary\n`;
    markdown += `- **Test Suites**: ${results.numPassedTestSuites} passed, ${results.numFailedTestSuites} failed, ${results.numTotalTestSuites} total\n`;
    markdown += `- **Tests**: ${results.numPassedTests} passed, ${results.numFailedTests} failed, ${results.numTotalTests} total\n`;
    const executionTimeMs = Date.now() - results.startTime;
    markdown += `- **Execution Time**: ${(executionTimeMs / 1000).toFixed(2)}s\n\n`;
    
    if (results.numFailedTests > 0) {
      markdown += `## ❌ Failed Tests\n\n`;
      results.testResults.forEach(suite => {
        if (suite.numFailingTests > 0) {
          markdown += `### ${path.basename(suite.testFilePath)}\n`;
          suite.testResults.filter(t => t.status === 'failed').forEach(test => {
            markdown += `- **${test.ancestorTitles.join(' > ')} > ${test.title}**\n`;
            if (test.failureMessages && test.failureMessages.length > 0) {
                // Extract only the first few lines of the error stack for readability
                const errorLines = test.failureMessages[0].split('\n');
                const truncatedError = errorLines.slice(0, 5).join('\n').replace(/\\n/g, '\n').trim();
                markdown += `\n\`\`\`text\n${truncatedError}\n\`\`\`\n\n`;
            }
          });
        }
      });
    }

    markdown += `## ✅ Passed Test Suites\n\n`;
    results.testResults.forEach(suite => {
      // Show successfully passing suites (even if they had some failures, we list the passed tests here)
      const passedTests = suite.testResults.filter(t => t.status === 'passed');
      if (passedTests.length > 0) {
        markdown += `### ${path.basename(suite.testFilePath)} (${passedTests.length} tests passed)\n`;
        passedTests.forEach(test => {
             const titlePath = test.ancestorTitles.length > 0 ? `${test.ancestorTitles.join(' > ')} > ` : '';
             markdown += `- ✓ *${titlePath}${test.title}*\n`;
        });
        markdown += '\n';
      }
    });

    markdown += `---\n\n`;
    markdown += `## 🚀 Instructions to Run Tests\n\n`;
    markdown += `The backend environment uses **Jest** alongside **firebase-functions-test** to mock the cloud environment.\n\n`;
    markdown += `To run these tests locally and automatically update this report without any side effects on the production database, execute:\n\n`;
    markdown += `\`\`\`bash\ncd "Endeavor Antigravity/functions"\nnpm install\nnpm test\n\`\`\`\n\n`;
    markdown += `To run a specific test suite file:\n`;
    markdown += `\`\`\`bash\nnpx jest src/__tests__/aiSearch.test.ts\n\`\`\`\n`;

    fs.writeFileSync(reportPath, markdown, 'utf8');
  }
}

module.exports = MarkdownReporter;
