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

export interface ModelAssetCoverage {
  asset_id?: string;
  asset_type?: string;
  asset_value?: string;
  notes?: string;
  /** "yes", "no" (excludes "na") */
  status?: string;
  updated_at?: string;
}

export interface ModelChecklistItemInfo {
  law_refs?: string[];
  /** "must", "should", "may" */
  priority?: string;
  resources?: ModelChecklistItemResource[];
  what_it_means?: string;
  why_it_matters?: string;
}

export interface ModelChecklistItemResource {
  title?: string;
  url?: string;
}

export interface ModelChecklistItemTemplate {
  /** Applicable asset types if scope is "asset" */
  asset_types?: string[];
  category?: string;
  description?: string;
  /** Rules for auto-derivation */
  evidence_rules?: ModelEvidenceRule[];
  /** Extended metadata fields for rich UI display */
  help_text?: string;
  id?: string;
  info?: ModelChecklistItemInfo;
  /** "manual" or "auto" */
  kind?: string;
  read_only?: boolean;
  recommendation?: string;
  required?: boolean;
  /** "global" or "asset" */
  scope?: string;
  /** Can be controlled by Lua scripts */
  script_controlled?: boolean;
  title?: string;
  why_matters?: string;
}

export interface ModelDerivedChecklistItem {
  /** Applicable asset types if scope is "asset" */
  asset_types?: string[];
  /** File attachment IDs */
  attachments?: string[];
  category?: string;
  /** Assets covered by this check */
  covered_assets?: ModelAssetCoverage[];
  description?: string;
  /** Relevant metadata for auto-derived status */
  evidence?: Record<string, any>;
  /** Rules for auto-derivation */
  evidence_rules?: ModelEvidenceRule[];
  /** Extended metadata fields for rich UI display */
  help_text?: string;
  id?: string;
  info?: ModelChecklistItemInfo;
  /** "manual" or "auto" */
  kind?: string;
  /** From manual assignment */
  notes?: string;
  read_only?: boolean;
  recommendation?: string;
  required?: boolean;
  /** "global" or "asset" */
  scope?: string;
  /** Can be controlled by Lua scripts */
  script_controlled?: boolean;
  /** "auto" or "manual" */
  source?: string;
  /** "yes", "no", "na" */
  status?: string;
  title?: string;
  /** From manual assignment */
  updated_at?: string;
  why_matters?: string;
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

export interface ModelFileAttachment {
  /** Optional: links to specific asset */
  asset_id?: string;
  /** Compliance context */
  checklist_key?: string;
  content_type?: string;
  description?: string;
  /** Error message if status is "failed" */
  error?: string;
  file_name?: string;
  /** Storage metadata */
  file_path?: string;
  file_size?: number;
  id?: string;
  original_name?: string;
  /** Status */
  status?: string;
  uploaded_at?: string;
  /** Future: user identification */
  uploaded_by?: string;
}

export interface ModelFileAttachmentSummary {
  content_type?: string;
  description?: string;
  file_name?: string;
  file_size?: number;
  id?: string;
  original_name?: string;
  status?: string;
  uploaded_at?: string;
}

export interface ModelFileUploadResponse {
  content_type?: string;
  file_id?: string;
  file_name?: string;
  file_size?: number;
  status?: string;
  uploaded_at?: string;
}

export interface V1AssetCatalogueResponse {
  assets: V1AssetSummary[];
  total: number;
}

export interface V1AssetDetails {
  discovered_at: string;
  /** DNS records for domains/subdomains */
  dns_records?: V1DNSRecords;
  id: string;
  last_scanned_at?: string;
  properties?: Record<string, any>;
  scan_count: number;
  scan_results?: V1ScanResult[];
  status: string;
  /** Tags like "http", "cf-proxied", etc. */
  tags?: string[];
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
  /** Tags like "http", "cf-proxied", etc. */
  tags?: string[];
  /** @example "domain,subdomain,ip,service" */
  type: string;
  value: string;
}

export interface V1Attachment {
  /** @example "evidence.pdf" */
  name: string;
  /** @example "Email headers and logs" */
  note?: string;
}

export interface V1CreateIncidentRequest {
  attachments?: V1Attachment[];
  /** @example "phishing,vuln_exploit,misconfig,malware,other" */
  causeTag: string;
  /** @example 30 */
  downtimeMinutes?: number;
  /** @example 2.5 */
  financialImpactPct?: number;
  initialDetails: V1InitialDetails;
  recurring?: boolean;
  /** @example "financial" */
  sectorPreset?: string;
  significant?: boolean;
  /** @example 100 */
  usersAffected?: number;
}

export interface V1DNSRecords {
  /** A records (IPv4) */
  a?: string[];
  /** AAAA records (IPv6) */
  aaaa?: string[];
  /** CNAME records */
  cname?: string[];
  /** MX records (mail exchange) */
  mx?: string[];
  /** NS records (name servers) */
  ns?: string[];
  /** PTR records (reverse DNS) */
  ptr?: string[];
  /** SOA records (start of authority) */
  soa?: string[];
  /** TXT records */
  txt?: string[];
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

export interface V1FinalDetails {
  /** @example "No cross-border effects identified" */
  crossBorderDesc?: string;
  /** @example "high" */
  gravity?: string;
  /** @example "No data exfiltration occurred" */
  impact?: string;
  /** @example "Need for regular security training" */
  lessons?: string;
  /** @example "Enhanced email filtering implemented" */
  mitigations?: string;
  /** @example "Lack of email security awareness" */
  rootCause?: string;
}

export interface V1GenericStatusResponse {
  message: string;
}

export interface V1HealthResponse {
  services: Record<string, string>;
  /** @example "healthy,unhealthy" */
  status: string;
  timestamp: string;
  version?: string;
}

export interface V1IncidentDetails {
  final?: V1FinalDetails;
  initial?: V1InitialDetails;
  update?: V1UpdateDetails;
}

export interface V1IncidentResponse {
  attachments?: V1Attachment[];
  causeTag: string;
  createdAt: string;
  details: V1IncidentDetails;
  downtimeMinutes?: number;
  financialImpactPct?: number;
  id: string;
  recurring?: boolean;
  sectorPreset?: string;
  significant?: boolean;
  /** @example "initial,update,final" */
  stage: string;
  updatedAt: string;
  usersAffected?: number;
}

export interface V1IncidentStatsResponse {
  byCause: Record<string, number>;
  byStage: Record<string, number>;
  recurringIncidents: number;
  significantIncidents: number;
  totalIncidents: number;
}

export interface V1IncidentSummaryResponse {
  causeTag: string;
  createdAt: string;
  id: string;
  recurring?: boolean;
  significant?: boolean;
  stage: string;
  summary: string;
  title: string;
  updatedAt: string;
}

export interface V1InitialDetails {
  /** @example "2024-01-15T10:30:00Z" */
  detectedAt: string;
  possibleCrossBorder?: boolean;
  /** @example "Multiple users reported suspicious emails" */
  summary: string;
  suspectedIllegal?: boolean;
  /** @example "Security Incident - Phishing Attack" */
  title: string;
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

export interface V1ListIncidentSummariesResponse {
  summaries: V1IncidentSummaryResponse[];
  total: number;
}

export interface V1ListIncidentsResponse {
  incidents: V1IncidentResponse[];
  total: number;
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

export interface V1UpdateDetails {
  /** @example "Blocked malicious domains" */
  corrections?: string;
  /** @example "high" */
  gravity?: string;
  /** @example "Email system compromised" */
  impact?: string;
  /** @example ["malicious-domain.com","suspicious-ip-address"] */
  iocs?: string[];
}

export interface V1UpdateIncidentRequest {
  attachments?: V1Attachment[];
  /** @example "phishing,vuln_exploit,misconfig,malware,other" */
  causeTag: string;
  /** @example 30 */
  downtimeMinutes?: number;
  finalDetails?: V1FinalDetails;
  /** @example 2.5 */
  financialImpactPct?: number;
  initialDetails?: V1InitialDetails;
  recurring?: boolean;
  /** @example "financial" */
  sectorPreset?: string;
  significant?: boolean;
  /** @example "initial,update,final" */
  stage: string;
  updateDetails?: V1UpdateDetails;
  /** @example 100 */
  usersAffected?: number;
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
     * @description Start asset discovery for a list of hosts using integrated recon service
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
     * @description Retrieve all asset-scoped checklist templates with their coverage across all assets
     *
     * @tags checklist
     * @name AssetTemplatesList
     * @summary Get all asset-scoped templates with coverage
     * @request GET:/checklist/asset-templates
     */
    assetTemplatesList: (params: RequestParams = {}) =>
      this.request<ModelDerivedChecklistItem[], V1ErrorResponse>({
        path: `/checklist/asset-templates`,
        method: "GET",
        type: ContentType.Json,
        format: "json",
        ...params,
      }),

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
     * @description Get a summary of compliance coverage showing which assets are covered by compliance checks
     *
     * @tags checklist
     * @name CoverageSummaryList
     * @summary Get compliance coverage summary
     * @request GET:/checklist/coverage/summary
     */
    coverageSummaryList: (params: RequestParams = {}) =>
      this.request<Record<string, any>, V1ErrorResponse>({
        path: `/checklist/coverage/summary`,
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
     * @description Retrieve all available checklist item templates with covered assets that are not compliant (status "no")
     *
     * @tags checklist
     * @name TemplatesList
     * @summary List all checklist templates with non-compliant asset coverage
     * @request GET:/checklist/templates
     */
    templatesList: (params: RequestParams = {}) =>
      this.request<ModelDerivedChecklistItem[], V1ErrorResponse>({
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
  files = {
    /**
     * @description List all file attachments for a specific checklist key
     *
     * @tags files
     * @name FilesList
     * @summary List file attachments
     * @request GET:/files
     */
    filesList: (
      query: {
        /** Checklist key (e.g., global:item1 or asset:assetId:item1) */
        checklistKey: string;
      },
      params: RequestParams = {},
    ) =>
      this.request<ModelFileAttachmentSummary[], V1ErrorResponse>({
        path: `/files`,
        method: "GET",
        query: query,
        format: "json",
        ...params,
      }),

    /**
     * @description Get information about file upload limits and restrictions
     *
     * @tags files
     * @name LimitsList
     * @summary Get upload limits
     * @request GET:/files/limits
     */
    limitsList: (params: RequestParams = {}) =>
      this.request<Record<string, any>, any>({
        path: `/files/limits`,
        method: "GET",
        format: "json",
        ...params,
      }),

    /**
     * @description Get the current status of the MinIO file upload service
     *
     * @tags files
     * @name StatusList
     * @summary Get file service status
     * @request GET:/files/status
     */
    statusList: (params: RequestParams = {}) =>
      this.request<Record<string, any>, any>({
        path: `/files/status`,
        method: "GET",
        format: "json",
        ...params,
      }),

    /**
     * @description Get the list of content types that are supported for file uploads
     *
     * @tags files
     * @name SupportedTypesList
     * @summary Get supported content types
     * @request GET:/files/supported-types
     */
    supportedTypesList: (params: RequestParams = {}) =>
      this.request<Record<string, any>, any>({
        path: `/files/supported-types`,
        method: "GET",
        format: "json",
        ...params,
      }),

    /**
     * @description Upload a file directly as part of a checklist item
     *
     * @tags files
     * @name UploadCreate
     * @summary Upload file
     * @request POST:/files/upload
     */
    uploadCreate: (
      data: {
        /** Checklist key (e.g., global:item1) */
        checklist_key: string;
        /** File description */
        description?: string;
        /**
         * File to upload
         * @format binary
         */
        file: File;
      },
      params: RequestParams = {},
    ) =>
      this.request<ModelFileUploadResponse, V1ErrorResponse>({
        path: `/files/upload`,
        method: "POST",
        body: data,
        type: ContentType.FormData,
        format: "json",
        ...params,
      }),

    /**
     * @description Get metadata for a file attachment
     *
     * @tags files
     * @name FilesDetail
     * @summary Get file information
     * @request GET:/files/{fileId}
     */
    filesDetail: (fileId: string, params: RequestParams = {}) =>
      this.request<ModelFileAttachment, V1ErrorResponse>({
        path: `/files/${fileId}`,
        method: "GET",
        format: "json",
        ...params,
      }),

    /**
     * @description Delete a file attachment and remove it from MinIO storage
     *
     * @tags files
     * @name FilesDelete
     * @summary Delete file attachment
     * @request DELETE:/files/{fileId}
     */
    filesDelete: (fileId: string, params: RequestParams = {}) =>
      this.request<Record<string, string>, V1ErrorResponse>({
        path: `/files/${fileId}`,
        method: "DELETE",
        format: "json",
        ...params,
      }),

    /**
     * @description Download a file attachment directly
     *
     * @tags files
     * @name DownloadList
     * @summary Download file
     * @request GET:/files/{fileId}/download
     */
    downloadList: (fileId: string, params: RequestParams = {}) =>
      this.request<File, V1ErrorResponse>({
        path: `/files/${fileId}/download`,
        method: "GET",
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
  incidents = {
    /**
     * @description Retrieve all incidents with optional filtering
     *
     * @tags incidents
     * @name IncidentsList
     * @summary List incidents
     * @request GET:/incidents
     */
    incidentsList: (
      query?: {
        /** Filter by stages (comma-separated) */
        stages?: string;
        /** Filter by cause tags (comma-separated) */
        causeTags?: string;
        /** Filter by significant incidents only */
        significant?: boolean;
        /** Filter by recurring incidents only */
        recurring?: boolean;
      },
      params: RequestParams = {},
    ) =>
      this.request<V1ListIncidentsResponse, V1ErrorResponse>({
        path: `/incidents`,
        method: "GET",
        query: query,
        type: ContentType.Json,
        format: "json",
        ...params,
      }),

    /**
     * @description Create a new incident record with initial details
     *
     * @tags incidents
     * @name IncidentsCreate
     * @summary Create a new incident
     * @request POST:/incidents
     */
    incidentsCreate: (
      request: V1CreateIncidentRequest,
      params: RequestParams = {},
    ) =>
      this.request<V1IncidentResponse, V1ErrorResponse>({
        path: `/incidents`,
        method: "POST",
        body: request,
        type: ContentType.Json,
        format: "json",
        ...params,
      }),

    /**
     * @description Retrieve statistics about incidents
     *
     * @tags incidents
     * @name StatsList
     * @summary Get incident statistics
     * @request GET:/incidents/stats
     */
    statsList: (params: RequestParams = {}) =>
      this.request<V1IncidentStatsResponse, V1ErrorResponse>({
        path: `/incidents/stats`,
        method: "GET",
        type: ContentType.Json,
        format: "json",
        ...params,
      }),

    /**
     * @description Retrieve incident summaries with optional filtering
     *
     * @tags incidents
     * @name SummariesList
     * @summary List incident summaries
     * @request GET:/incidents/summaries
     */
    summariesList: (
      query?: {
        /** Filter by stages (comma-separated) */
        stages?: string;
        /** Filter by cause tags (comma-separated) */
        causeTags?: string;
        /** Filter by significant incidents only */
        significant?: boolean;
        /** Filter by recurring incidents only */
        recurring?: boolean;
      },
      params: RequestParams = {},
    ) =>
      this.request<V1ListIncidentSummariesResponse, V1ErrorResponse>({
        path: `/incidents/summaries`,
        method: "GET",
        query: query,
        type: ContentType.Json,
        format: "json",
        ...params,
      }),

    /**
     * @description Retrieve a specific incident by its ID
     *
     * @tags incidents
     * @name IncidentsDetail
     * @summary Get incident by ID
     * @request GET:/incidents/{id}
     */
    incidentsDetail: (id: string, params: RequestParams = {}) =>
      this.request<V1IncidentResponse, V1ErrorResponse>({
        path: `/incidents/${id}`,
        method: "GET",
        type: ContentType.Json,
        format: "json",
        ...params,
      }),

    /**
     * @description Update an existing incident record
     *
     * @tags incidents
     * @name IncidentsUpdate
     * @summary Update incident
     * @request PUT:/incidents/{id}
     */
    incidentsUpdate: (
      id: string,
      request: V1UpdateIncidentRequest,
      params: RequestParams = {},
    ) =>
      this.request<V1IncidentResponse, V1ErrorResponse>({
        path: `/incidents/${id}`,
        method: "PUT",
        body: request,
        type: ContentType.Json,
        format: "json",
        ...params,
      }),

    /**
     * @description Delete an incident by ID
     *
     * @tags incidents
     * @name IncidentsDelete
     * @summary Delete incident
     * @request DELETE:/incidents/{id}
     */
    incidentsDelete: (id: string, params: RequestParams = {}) =>
      this.request<V1GenericStatusResponse, V1ErrorResponse>({
        path: `/incidents/${id}`,
        method: "DELETE",
        type: ContentType.Json,
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
