/* eslint-disable */
/* tslint:disable */
// @ts-nocheck
/*
 * ---------------------------------------------------------------
 * ## THIS FILE WAS GENERATED VIA SWAGGER-TYPESCRIPT-API        ##
 * ##                                                           ##
 * ## AUTHOR: acacode                                           ##
 * ## SOURCE: https://github.com/acacode/swagger-typescript-api ##
 * ---------------------------------------------------------------
 */

export interface HandlerSetStatusRequest {
  /**
   * Asset ID (empty for global items)
   * @example "asset-123"
   */
  asset_id?: string;
  /**
   * Checklist item template ID
   * @example "security-policy-001"
   */
  item_id?: string;
  /**
   * Optional notes
   * @example "Verified during security audit"
   */
  notes?: string;
  /**
   * Status: yes, no, or na
   * @example "yes"
   */
  status?: "yes" | "no" | "na";
}

export interface HandlerUploadTemplatesRequest {
  /** Array of checklist templates to upload */
  templates?: ModelChecklistItemTemplate[];
}

export interface ModelChecklistItemTemplate {
  /** Applicable asset types if scope is "asset" */
  asset_types?: string[];
  category?: string;
  description?: string;
  /** Rules for auto-derivation */
  evidence_rules?: ModelEvidenceRule[];
  id?: string;
  recommendation?: string;
  required?: boolean;
  /** "global" or "asset" */
  scope?: string;
  title?: string;
}

export interface ModelDerivedChecklistItem {
  /** Applicable asset types if scope is "asset" */
  asset_types?: string[];
  category?: string;
  description?: string;
  /** Relevant metadata for auto-derived status */
  evidence?: Record<string, any>;
  /** Rules for auto-derivation */
  evidence_rules?: ModelEvidenceRule[];
  id?: string;
  /** From manual assignment */
  notes?: string;
  recommendation?: string;
  required?: boolean;
  /** "global" or "asset" */
  scope?: string;
  /** "auto" or "manual" */
  source?: string;
  /** "yes", "no", "na" */
  status?: string;
  title?: string;
  /** From manual assignment */
  updated_at?: string;
}

export interface ModelEvidenceRule {
  /** e.g., "http.title", "last_scanned_at" */
  key?: string;
  /** "exists", "eq", "regex", "gte_days_since" */
  op?: string;
  /** "scan_metadata" */
  source?: string;
  /** Value for "eq", "regex", "gte_days_since" */
  value?: any;
}

export interface V1AssetCatalogueResponse {
  assets: V1AssetSummary[];
  total: number;
}

export interface V1AssetDetails {
  discovered_at: string;
  id: string;
  last_scanned_at?: string;
  properties?: Record<string, any>;
  scan_count: number;
  scan_results?: V1ScanResult[];
  status: string;
  type: string;
  value: string;
}

export interface V1AssetDetailsResponse {
  asset: V1AssetDetails;
}

export interface V1AssetSummary {
  discovered_at: string;
  id: string;
  last_scanned_at?: string;
  scan_count: number;
  /** @example "discovered,scanning,scanned,error" */
  status: string;
  /** @example "domain,subdomain,ip,service" */
  type: string;
  value: string;
}

export interface V1DiscoverAssetsRequest {
  /** @example ["example.com","192.168.1.1"] */
  hosts: string[];
}

export interface V1DiscoverAssetsResponse {
  host_count: number;
  job_id: string;
  message: string;
  started_at: string;
}

export interface V1ErrorResponse {
  code: number;
  details?: Record<string, string>;
  error: string;
}

export interface V1HealthResponse {
  services: Record<string, string>;
  /** @example "healthy,unhealthy" */
  status: string;
  timestamp: string;
  version?: string;
}

export interface V1JobProgress {
  completed: number;
  failed: number;
  total: number;
}

export interface V1JobStatusResponse {
  completed_at?: string;
  error?: string;
  job_id: string;
  progress: V1JobProgress;
  started_at: string;
  /** @example "pending,running,completed,failed" */
  status: string;
}

export interface V1ScanResult {
  duration: string;
  error?: string;
  executed_at: string;
  id: string;
  metadata?: Record<string, any>;
  output?: string[];
  script_name: string;
  success: boolean;
}

export interface V1StartAllAssetsScanRequest {
  /** @example ["domain","ip","service"] */
  asset_types?: string[];
  scripts?: string[];
}

export interface V1StartAllAssetsScanResponse {
  asset_count: number;
  job_id: string;
  message: string;
  started_at: string;
}

export interface V1StartAssetScanRequest {
  /** @example ["vulnerability_scan.lua","port_scan.lua"] */
  scripts?: string[];
}

export interface V1StartAssetScanResponse {
  asset_id: string;
  job_id: string;
  message: string;
  started_at: string;
}

export type QueryParamsType = Record<string | number, any>;
export type ResponseFormat = keyof Omit<Body, "body" | "bodyUsed">;

export interface FullRequestParams extends Omit<RequestInit, "body"> {
  /** set parameter to `true` for call `securityWorker` for this request */
  secure?: boolean;
  /** request path */
  path: string;
  /** content type of request body */
  type?: ContentType;
  /** query params */
  query?: QueryParamsType;
  /** format of response (i.e. response.json() -> format: "json") */
  format?: ResponseFormat;
  /** request body */
  body?: unknown;
  /** base url */
  baseUrl?: string;
  /** request cancellation token */
  cancelToken?: CancelToken;
}

export type RequestParams = Omit<
  FullRequestParams,
  "body" | "method" | "query" | "path"
>;

export interface ApiConfig<SecurityDataType = unknown> {
  baseUrl?: string;
  baseApiParams?: Omit<RequestParams, "baseUrl" | "cancelToken" | "signal">;
  securityWorker?: (
    securityData: SecurityDataType | null,
  ) => Promise<RequestParams | void> | RequestParams | void;
  customFetch?: typeof fetch;
}

export interface HttpResponse<D extends unknown, E extends unknown = unknown>
  extends Response {
  data: D;
  error: E;
}

type CancelToken = Symbol | string | number;

export enum ContentType {
  Json = "application/json",
  JsonApi = "application/vnd.api+json",
  FormData = "multipart/form-data",
  UrlEncoded = "application/x-www-form-urlencoded",
  Text = "text/plain",
}

export class HttpClient<SecurityDataType = unknown> {
  public baseUrl: string = "";
  private securityData: SecurityDataType | null = null;
  private securityWorker?: ApiConfig<SecurityDataType>["securityWorker"];
  private abortControllers = new Map<CancelToken, AbortController>();
  private customFetch = (...fetchParams: Parameters<typeof fetch>) =>
    fetch(...fetchParams);

  private baseApiParams: RequestParams = {
    credentials: "same-origin",
    headers: {},
    redirect: "follow",
    referrerPolicy: "no-referrer",
  };

  constructor(apiConfig: ApiConfig<SecurityDataType> = {}) {
    Object.assign(this, apiConfig);
  }

  public setSecurityData = (data: SecurityDataType | null) => {
    this.securityData = data;
  };

  protected encodeQueryParam(key: string, value: any) {
    const encodedKey = encodeURIComponent(key);
    return `${encodedKey}=${encodeURIComponent(typeof value === "number" ? value : `${value}`)}`;
  }

  protected addQueryParam(query: QueryParamsType, key: string) {
    return this.encodeQueryParam(key, query[key]);
  }

  protected addArrayQueryParam(query: QueryParamsType, key: string) {
    const value = query[key];
    return value.map((v: any) => this.encodeQueryParam(key, v)).join("&");
  }

  protected toQueryString(rawQuery?: QueryParamsType): string {
    const query = rawQuery || {};
    const keys = Object.keys(query).filter(
      (key) => "undefined" !== typeof query[key],
    );
    return keys
      .map((key) =>
        Array.isArray(query[key])
          ? this.addArrayQueryParam(query, key)
          : this.addQueryParam(query, key),
      )
      .join("&");
  }

  protected addQueryParams(rawQuery?: QueryParamsType): string {
    const queryString = this.toQueryString(rawQuery);
    return queryString ? `?${queryString}` : "";
  }

  private contentFormatters: Record<ContentType, (input: any) => any> = {
    [ContentType.Json]: (input: any) =>
      input !== null && (typeof input === "object" || typeof input === "string")
        ? JSON.stringify(input)
        : input,
    [ContentType.JsonApi]: (input: any) =>
      input !== null && (typeof input === "object" || typeof input === "string")
        ? JSON.stringify(input)
        : input,
    [ContentType.Text]: (input: any) =>
      input !== null && typeof input !== "string"
        ? JSON.stringify(input)
        : input,
    [ContentType.FormData]: (input: any) => {
      if (input instanceof FormData) {
        return input;
      }

      return Object.keys(input || {}).reduce((formData, key) => {
        const property = input[key];
        formData.append(
          key,
          property instanceof Blob
            ? property
            : typeof property === "object" && property !== null
              ? JSON.stringify(property)
              : `${property}`,
        );
        return formData;
      }, new FormData());
    },
    [ContentType.UrlEncoded]: (input: any) => this.toQueryString(input),
  };

  protected mergeRequestParams(
    params1: RequestParams,
    params2?: RequestParams,
  ): RequestParams {
    return {
      ...this.baseApiParams,
      ...params1,
      ...(params2 || {}),
      headers: {
        ...(this.baseApiParams.headers || {}),
        ...(params1.headers || {}),
        ...((params2 && params2.headers) || {}),
      },
    };
  }

  protected createAbortSignal = (
    cancelToken: CancelToken,
  ): AbortSignal | undefined => {
    if (this.abortControllers.has(cancelToken)) {
      const abortController = this.abortControllers.get(cancelToken);
      if (abortController) {
        return abortController.signal;
      }
      return void 0;
    }

    const abortController = new AbortController();
    this.abortControllers.set(cancelToken, abortController);
    return abortController.signal;
  };

  public abortRequest = (cancelToken: CancelToken) => {
    const abortController = this.abortControllers.get(cancelToken);

    if (abortController) {
      abortController.abort();
      this.abortControllers.delete(cancelToken);
    }
  };

  public request = async <T = any, E = any>({
    body,
    secure,
    path,
    type,
    query,
    format,
    baseUrl,
    cancelToken,
    ...params
  }: FullRequestParams): Promise<HttpResponse<T, E>> => {
    const secureParams =
      ((typeof secure === "boolean" ? secure : this.baseApiParams.secure) &&
        this.securityWorker &&
        (await this.securityWorker(this.securityData))) ||
      {};
    const requestParams = this.mergeRequestParams(params, secureParams);
    const queryString = query && this.toQueryString(query);
    const payloadFormatter = this.contentFormatters[type || ContentType.Json];
    const responseFormat = format || requestParams.format;

    return this.customFetch(
      `${baseUrl || this.baseUrl || ""}${path}${queryString ? `?${queryString}` : ""}`,
      {
        ...requestParams,
        headers: {
          ...(requestParams.headers || {}),
          ...(type && type !== ContentType.FormData
            ? { "Content-Type": type }
            : {}),
        },
        signal:
          (cancelToken
            ? this.createAbortSignal(cancelToken)
            : requestParams.signal) || null,
        body:
          typeof body === "undefined" || body === null
            ? null
            : payloadFormatter(body),
      },
    ).then(async (response) => {
      const r = response as HttpResponse<T, E>;
      r.data = null as unknown as T;
      r.error = null as unknown as E;

      const data = !responseFormat
        ? r
        : await response[responseFormat]()
            .then((data) => {
              if (r.ok) {
                r.data = data;
              } else {
                r.error = data;
              }
              return r;
            })
            .catch((e) => {
              r.error = e;
              return r;
            });

      if (cancelToken) {
        this.abortControllers.delete(cancelToken);
      }

      if (!response.ok) throw data;
      return data;
    });
  };
}

/**
 * @title Asset Scanner API
 * @version 1.0
 * @license MIT (https://opensource.org/licenses/MIT)
 * @termsOfService http://swagger.io/terms/
 * @contact API Support <support@example.com> (http://www.example.com/support)
 *
 * A powerful asset discovery and scanning API with Lua script support
 */
export class Api<
  SecurityDataType extends unknown,
> extends HttpClient<SecurityDataType> {
  assets = {
    /**
     * @description Retrieve all discovered assets for 2D view
     *
     * @tags assets
     * @name CatalogueList
     * @summary Get asset catalogue
     * @request GET:/assets/catalogue
     */
    catalogueList: (
      query?: {
        /** Filter by asset type */
        type?: string;
        /** Filter by asset status */
        status?: string;
      },
      params: RequestParams = {},
    ) =>
      this.request<V1AssetCatalogueResponse, V1ErrorResponse>({
        path: `/assets/catalogue`,
        method: "GET",
        query: query,
        format: "json",
        ...params,
      }),

    /**
     * @description Start asset discovery for a list of hosts using recontool
     *
     * @tags assets
     * @name DiscoverCreate
     * @summary Discover assets
     * @request POST:/assets/discover
     */
    discoverCreate: (
      request: V1DiscoverAssetsRequest,
      params: RequestParams = {},
    ) =>
      this.request<V1DiscoverAssetsResponse, V1ErrorResponse>({
        path: `/assets/discover`,
        method: "POST",
        body: request,
        type: ContentType.Json,
        format: "json",
        ...params,
      }),

    /**
     * @description Start scanning all assets with specified scripts
     *
     * @tags assets
     * @name ScanCreate
     * @summary Start scan of all assets
     * @request POST:/assets/scan
     */
    scanCreate: (
      request: V1StartAllAssetsScanRequest,
      params: RequestParams = {},
    ) =>
      this.request<V1StartAllAssetsScanResponse, V1ErrorResponse>({
        path: `/assets/scan`,
        method: "POST",
        body: request,
        type: ContentType.Json,
        format: "json",
        ...params,
      }),

    /**
     * @description Get detailed information about a specific asset including scan results
     *
     * @tags assets
     * @name AssetsDetail
     * @summary Get asset details
     * @request GET:/assets/{id}
     */
    assetsDetail: (id: string, params: RequestParams = {}) =>
      this.request<V1AssetDetailsResponse, V1ErrorResponse>({
        path: `/assets/${id}`,
        method: "GET",
        format: "json",
        ...params,
      }),

    /**
     * @description Start scanning a specific asset with specified scripts
     *
     * @tags assets
     * @name ScanCreate2
     * @summary Start asset scan
     * @request POST:/assets/{id}/scan
     * @originalName scanCreate
     * @duplicate
     */
    scanCreate2: (
      id: string,
      request: V1StartAssetScanRequest,
      params: RequestParams = {},
    ) =>
      this.request<V1StartAssetScanResponse, V1ErrorResponse>({
        path: `/assets/${id}/scan`,
        method: "POST",
        body: request,
        type: ContentType.Json,
        format: "json",
        ...params,
      }),
  };
  checklist = {
    /**
     * @description Retrieve all checklist items applicable to a specific asset with their current status
     *
     * @tags checklist
     * @name AssetDetail
     * @summary Get asset-specific checklist items
     * @request GET:/checklist/asset/{id}
     */
    assetDetail: (id: string, params: RequestParams = {}) =>
      this.request<ModelDerivedChecklistItem[], V1ErrorResponse>({
        path: `/checklist/asset/${id}`,
        method: "GET",
        type: ContentType.Json,
        format: "json",
        ...params,
      }),

    /**
     * @description Retrieve all global checklist items with their current status
     *
     * @tags checklist
     * @name GlobalList
     * @summary Get global checklist items
     * @request GET:/checklist/global
     */
    globalList: (params: RequestParams = {}) =>
      this.request<ModelDerivedChecklistItem[], V1ErrorResponse>({
        path: `/checklist/global`,
        method: "GET",
        type: ContentType.Json,
        format: "json",
        ...params,
      }),

    /**
     * @description Set the status (yes/no/na) of a checklist item, either global or asset-specific
     *
     * @tags checklist
     * @name StatusCreate
     * @summary Set checklist item status
     * @request POST:/checklist/status
     */
    statusCreate: (
      request: HandlerSetStatusRequest,
      params: RequestParams = {},
    ) =>
      this.request<Record<string, string>, V1ErrorResponse>({
        path: `/checklist/status`,
        method: "POST",
        body: request,
        type: ContentType.Json,
        format: "json",
        ...params,
      }),

    /**
     * @description Retrieve all available checklist item templates
     *
     * @tags checklist
     * @name TemplatesList
     * @summary List all checklist templates
     * @request GET:/checklist/templates
     */
    templatesList: (params: RequestParams = {}) =>
      this.request<ModelChecklistItemTemplate[], V1ErrorResponse>({
        path: `/checklist/templates`,
        method: "GET",
        type: ContentType.Json,
        format: "json",
        ...params,
      }),

    /**
     * @description Upload a JSON file containing checklist templates that will overwrite all existing templates
     *
     * @tags checklist
     * @name TemplatesUploadCreate
     * @summary Upload checklist templates from JSON
     * @request POST:/checklist/templates/upload
     */
    templatesUploadCreate: (
      request: HandlerUploadTemplatesRequest,
      params: RequestParams = {},
    ) =>
      this.request<Record<string, any>, V1ErrorResponse>({
        path: `/checklist/templates/upload`,
        method: "POST",
        body: request,
        type: ContentType.Json,
        format: "json",
        ...params,
      }),
  };
  health = {
    /**
     * @description Check if the service is healthy
     *
     * @tags health
     * @name HealthList
     * @summary Health check
     * @request GET:/health
     */
    healthList: (params: RequestParams = {}) =>
      this.request<V1HealthResponse, any>({
        path: `/health`,
        method: "GET",
        format: "json",
        ...params,
      }),
  };
  jobs = {
    /**
     * @description Get the status and progress of a job
     *
     * @tags jobs
     * @name JobsDetail
     * @summary Get job status
     * @request GET:/jobs/{id}
     */
    jobsDetail: (id: string, params: RequestParams = {}) =>
      this.request<V1JobStatusResponse, V1ErrorResponse>({
        path: `/jobs/${id}`,
        method: "GET",
        format: "json",
        ...params,
      }),
  };
}
