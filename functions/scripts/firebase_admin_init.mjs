import admin from "firebase-admin";
import { existsSync, readFileSync } from "node:fs";

const DEFAULT_PROJECT_ID = "worldcup-pool-tracker-app";

/**
 * Initializes Firebase Admin for local scripts.
 * Set GOOGLE_APPLICATION_CREDENTIALS to a JSON **outside** this repo
 * (see docs/security.md). There is no in-repo fallback path.
 */
export function initFirebaseAdmin() {
  if (admin.apps.length > 0) return admin;

  const saPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;

  if (saPath && existsSync(saPath)) {
    const sa = JSON.parse(readFileSync(saPath, "utf8"));
    admin.initializeApp({
      credential: admin.credential.cert(sa),
      projectId: sa.project_id,
    });
    console.log(`Firebase Admin: service account (${sa.project_id})`);
    return admin;
  }

  const projectId =
    process.env.GCLOUD_PROJECT ??
    process.env.GOOGLE_CLOUD_PROJECT ??
    process.env.FIREBASE_PROJECT_ID ??
    DEFAULT_PROJECT_ID;

  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId,
  });
  console.log(`Firebase Admin: application default credentials (${projectId})`);
  return admin;
}
