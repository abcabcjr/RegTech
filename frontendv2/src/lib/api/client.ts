import { browser } from '$app/environment';
import { Api, type FullRequestParams } from '$lib/api/Api';
import { API_HOST, IS_PACKAGED } from '$lib/env';

export const API_BASE_URL = IS_PACKAGED
	? API_HOST + '/api/v1'
	: browser
		? window.location.protocol + '//' + window.location.hostname + ':8080/api/v1'
		: '';

export class AuthApiError extends Error {}

function createApiClient() {
	const api = new Api({
		baseUrl: API_BASE_URL
	});

	const originalRequest = api.request.bind(api);

	api.request = async function wrappedRequest<T, E>(params: FullRequestParams) {
		try {
			const response = await originalRequest<T, E>(params);
			return response;
		} catch (error) {
			console.error('API request failed:', error);
			throw error;
		}
	};

	return api;
}

const apiClientInternal = createApiClient();

export const apiClient = apiClientInternal;
