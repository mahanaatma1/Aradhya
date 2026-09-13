/**
 * Loaded before every test file.
 *
 * Two jobs: the DOM matchers (`toBeInTheDocument` and friends), and unmounting
 * whatever a test rendered. Testing Library auto-cleans when it can see a
 * global `afterEach`, which it can here — but doing it explicitly means the
 * guarantee does not depend on `globals: true` staying switched on in
 * vitest.config.js.
 */

import '@testing-library/jest-dom/vitest';
import { cleanup } from '@testing-library/react';
import { afterEach } from 'vitest';

afterEach(() => {
  cleanup();
});
