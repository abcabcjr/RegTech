import adapter from '@sveltejs/adapter-static';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';
import childProcess from 'child_process';
import fs from 'fs';

const PKG = JSON.parse(fs.readFileSync(new URL('./package.json', import.meta.url), 'utf8'));

function getCommitHash() {
	let revision = childProcess.execSync('git rev-parse HEAD').toString().trim();
	return revision.slice(0, 7);
}

function getCommitBranch() {
	return childProcess.execSync('git branch --show-current').toString().trim();
}

function getTotalCommitCount() {
	try {
		let commitCount = childProcess.execSync('git rev-list --all --count').toString().trim();
		return parseInt(commitCount, 10); // Convert the string output to an integer
	} catch (error) {
		console.error('Error getting total commit count:', error.message);
		return -1;
	}
}

process.env.PUBLIC_FLAVOR = getCommitBranch();
process.env.PUBLIC_VER = getCommitHash();
process.env.PUBLIC_BUILD_TIME = Math.trunc(Date.now() / 1000);
process.env.PUBLIC_IS_DEV = getCommitBranch() === 'main' ? '' : 'true';
process.env.PUBLIC_PKG_VER = PKG.version || '0.0.0';
process.env.PUBLIC_REVISION = getTotalCommitCount();
process.env.PUBLIC_IS_PACKAGED = !process.env.VITE_BUILD ? '' : 'true';
// TODO: API host configs
process.env.PUBLIC_API_HOST = '';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	// Consult https://svelte.dev/docs/kit/integrations
	// for more information about preprocessors
	preprocess: vitePreprocess(),
	compilerOptions: {
		runes: true
	},
	kit: {
		// adapter-auto only supports some environments, see https://svelte.dev/docs/kit/adapter-auto for a list.
		// If your environment is not supported, or you settled on a specific environment, switch out the adapter.
		// See https://svelte.dev/docs/kit/adapters for more information about adapters.
		adapter: adapter({
			pages: 'build',
			assets: 'build',
			fallback: 'index.html'
		})
	}
};

export default config;
