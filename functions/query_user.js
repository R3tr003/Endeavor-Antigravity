const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

async function check() {
  const email = "ballonciotti@gmail.com";
  console.log(`Checking for ${email}...`);
  const usersRef = db.collection('users');
  const snapshot = await usersRef.where('email', '==', email).get();
  
  if (snapshot.empty) {
    console.log('No matching users found.');
    process.exit(0);
  }
  
  for (const doc of snapshot.docs) {
    console.log('--- USER DOC ---');
    console.log(doc.id, '=>', doc.data());
    
    const userId = doc.data().id;
    console.log(`Checking companies for userId: ${userId}`);
    const companySnap = await db.collection('companies').where('userId', '==', userId).get();
    
    if (companySnap.empty) {
      console.log('No matching companies found for this user.');
    } else {
      companySnap.forEach(cDoc => {
        console.log('--- COMPANY DOC ---');
        console.log(cDoc.id, '=>', cDoc.data());
      });
    }
  }
}

check().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
