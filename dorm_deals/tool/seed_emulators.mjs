// Seeds the local Firebase emulators with a demo account and some listings.
//
//   firebase emulators:start
//   node tool/seed_emulators.mjs
//
// Safe to re-run: it wipes the emulator's listings and re-creates them.
// Talks to the emulators only, never the live project.

const projectId = 'dormdeals-5b396';
const bucket = 'dormdeals-5b396.firebasestorage.app';

const authHost = 'http://localhost:9099';
const firestoreHost = 'http://localhost:8080';
const storageHost = 'http://localhost:9199';

// Demo login for the app when it's running against the emulators.
export const demoAccount = {
  email: 'demo@dormdeals.test',
  password: 'campus-demo-4821',
};

// Emulator-only admin token, skips security rules.
const owner = { Authorization: 'Bearer owner' };

const hoursAgo = (hours) => new Date(Date.now() - hours * 3600 * 1000);

async function check(response, what) {
  if (!response.ok) {
    throw new Error(`${what} failed (${response.status}): ${await response.text()}`);
  }
  return response.json();
}

async function getDemoUserId() {
  const key = 'fake-api-key';
  const body = JSON.stringify({ ...demoAccount, returnSecureToken: true });
  const headers = { 'Content-Type': 'application/json' };

  const signUp = await fetch(
    `${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=${key}`,
    { method: 'POST', headers, body },
  );
  if (signUp.ok) {
    return (await signUp.json()).localId;
  }

  // Already created on an earlier run, sign in to get the uid instead.
  const signIn = await fetch(
    `${authHost}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${key}`,
    { method: 'POST', headers, body },
  );
  return (await check(signIn, 'Demo sign in')).localId;
}

async function uploadPhoto(picsumId) {
  const image = await fetch(`https://picsum.photos/id/${picsumId}/1000/750`);
  const bytes = Buffer.from(await image.arrayBuffer());
  const name = `listing_images/seed-${picsumId}.jpg`;

  const upload = await fetch(
    `${storageHost}/v0/b/${bucket}/o?uploadType=media&name=${encodeURIComponent(name)}`,
    {
      method: 'POST',
      headers: { ...owner, 'Content-Type': 'image/jpeg' },
      body: bytes,
    },
  );
  const { downloadTokens } = await check(upload, `Upload ${name}`);

  return `${storageHost}/v0/b/${bucket}/o/${encodeURIComponent(name)}?alt=media&token=${downloadTokens}`;
}

function toFields(listing) {
  const value = (v) => {
    if (v === null || v === undefined) return { nullValue: null };
    if (v instanceof Date) return { timestampValue: v.toISOString() };
    if (typeof v === 'number') return { doubleValue: v };
    return { stringValue: v };
  };

  return Object.fromEntries(
    Object.entries(listing).map(([key, v]) => [key, value(v)]),
  );
}

async function main() {
  const demoUid = await getDemoUserId();
  console.log(`Demo account ready: ${demoAccount.email}`);

  await fetch(
    `${firestoreHost}/emulator/v1/projects/${projectId}/databases/(default)/documents`,
    { method: 'DELETE' },
  );

  const library = { latitude: -33.7759, longitude: 151.1135 };
  const campusHub = { latitude: -33.7741, longitude: 151.1127 };

  const listings = [
    {
      title: 'MacBook Air 2020, 8GB / 256GB',
      description: 'Battery health 89%. Few light scratches on the lid, screen is perfect. Comes with the original charger.',
      price: 480,
      category: 'electronics',
      pickupLocation: 'Campus Hub, near the food court',
      seller: 'daniel.kim@students.mq.edu.au',
      photo: 0,
      createdAt: hoursAgo(5),
      ...campusHub,
    },
    {
      title: 'Campbell Biology, 12th edition',
      description: 'Used for BIOL1610. Some highlighting in chapters 4-6, otherwise clean. No missing pages.',
      price: 65,
      category: 'textbook',
      pickupLocation: 'Library, ground floor lockers',
      seller: 'maya.reddy@students.mq.edu.au',
      photo: 24,
      createdAt: hoursAgo(26),
      ...library,
    },
    {
      title: 'COMP3130 notes, weeks 1-13',
      description: 'Typed notes with worked exam answers and diagrams for every lecture. Printed and bound.',
      price: 18,
      category: 'notes',
      pickupLocation: 'Library foyer, level 2',
      seller: demoAccount.email,
      sellerId: demoUid,
      createdAt: hoursAgo(3),
      ...library,
    },
    {
      title: 'Kindle Paperwhite with case',
      description: '10th gen, 8GB. Works perfectly, switched to an iPad so it barely gets used now.',
      price: 70,
      category: 'electronics',
      pickupLocation: 'Lincoln building foyer',
      seller: 'sana.khalil@students.mq.edu.au',
      photo: 367,
      createdAt: hoursAgo(50),
    },
    {
      title: 'ECON1020 full semester notes',
      description: 'Handwritten but neat. Covers every topic on the final, plus a page of formulas at the back.',
      price: 15,
      category: 'notes',
      pickupLocation: 'Arts precinct, outside the cafe',
      seller: 'liam.chen@students.mq.edu.au',
      photo: 1073,
      createdAt: hoursAgo(74),
    },
    {
      title: 'Stationery bundle, mostly unused',
      description: 'Pens, highlighters, sticky notes and two A5 notebooks. Bought too much in O-week.',
      price: 12,
      category: 'stationery',
      pickupLocation: 'Campus Hub, near the food court',
      seller: 'jules.ward@students.mq.edu.au',
      photo: 20,
      createdAt: hoursAgo(98),
      ...campusHub,
    },
    {
      title: 'Lab coat, size M',
      description: 'Worn for one semester of CHEM1001. Washed, no stains or tears.',
      price: 15,
      category: 'essentials',
      pickupLocation: 'Science labs entrance',
      seller: demoAccount.email,
      sellerId: demoUid,
      createdAt: hoursAgo(120),
    },
    {
      title: 'Wired keyboard and mouse',
      description: 'Logitech set, full size keyboard. Good for a desk setup in college.',
      price: 25,
      category: 'electronics',
      pickupLocation: 'Dunmore Lang College',
      seller: 'tom.okafor@students.mq.edu.au',
      photo: 366,
      createdAt: hoursAgo(170),
    },
    {
      title: 'Loud alarm clock for 9am lectures',
      description: 'Battery powered, very loud. Has not failed me once, moving out so it has to go.',
      price: 8,
      category: 'essentials',
      pickupLocation: 'Robert Menzies College',
      seller: 'priya.nair@students.mq.edu.au',
      photo: 175,
      createdAt: hoursAgo(260),
    },
  ];

  for (const { seller, sellerId, photo, ...listing } of listings) {
    const image = photo === undefined ? null : await uploadPhoto(photo);

    const doc = {
      latitude: null,
      longitude: null,
      ...listing,
      sellerName: seller,
      sellerId: sellerId ?? `seed-${seller.split('@')[0]}`,
      image,
    };

    await check(
      await fetch(
        `${firestoreHost}/v1/projects/${projectId}/databases/(default)/documents/listings`,
        {
          method: 'POST',
          headers: { ...owner, 'Content-Type': 'application/json' },
          body: JSON.stringify({ fields: toFields(doc) }),
        },
      ),
      `Creating "${listing.title}"`,
    );
    console.log(`  + ${listing.title}`);
  }

  console.log(`Seeded ${listings.length} listings.`);
}

main().catch((error) => {
  console.error(error.message);
  console.error('Are the emulators running? Start them with: firebase emulators:start');
  process.exit(1);
});
