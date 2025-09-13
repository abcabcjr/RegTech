/**
 * Utility functions for managing organization data in local storage
 */

const ORGANIZATION_KEY = 'regtech_organization_name';

/**
 * Get the organization name from local storage
 */
export function getOrganizationName(): string | null {
	if (typeof window === 'undefined') return null;
	return localStorage.getItem(ORGANIZATION_KEY);
}

/**
 * Save the organization name to local storage
 */
export function saveOrganizationName(name: string): void {
	if (typeof window === 'undefined') return;
	localStorage.setItem(ORGANIZATION_KEY, name);
}

/**
 * Clear the organization name from local storage
 */
export function clearOrganizationName(): void {
	if (typeof window === 'undefined') return;
	localStorage.removeItem(ORGANIZATION_KEY);
}

