/**
 * Template Loader Service
 * Centralized service for loading and processing checklist templates from JSON
 */

import type { ChecklistItem, InfoBlock, FileAttachment } from '$lib/types';

export interface ChecklistTemplate {
	id: string;
	title: string;
	description: string;
	category: string;
	required: boolean;
	scope: 'global' | 'asset';
	recommendation: string;
	help_text: string;
	why_matters: string;
	kind: 'manual' | 'auto';
	read_only: boolean;
	script_controlled?: boolean;
	info?: {
		what_it_means?: string;
		why_it_matters?: string;
		law_refs?: string[];
		priority?: 'critical' | 'high' | 'medium' | 'low';
		priority_number?: number;
		resources?: Array<{
			title: string;
			url: string;
		}>;
		risks?: {
			attack_vectors: string[];
			potential_impact: string[];
		};
		guide?: {
			non_technical_steps: string[];
			scope_caveats?: string;
			acceptance_summary?: string;
			faq?: Array<{
				question: string;
				answer: string;
			}>;
		};
		legal?: {
			requirement_summary: string;
			article_refs: string[];
			quotes?: Array<{
				text: string;
				source: string;
			}>;
		};
		pdf_guide?: {
			available: boolean;
			sections: string[];
			download_url?: string;
		};
	};
}

export interface ChecklistTemplateResponse {
	templates: ChecklistTemplate[];
}

export interface ProcessedChecklistData {
	categories: Array<{
		name: string;
		items: ChecklistItem[];
	}>;
	totalItems: number;
	requiredItems: number;
	manualItems: number;
	autoItems: number;
}

class TemplateLoaderService {
	private templates: ChecklistTemplate[] = [];
	private processedData: ProcessedChecklistData | null = null;
	private loadPromise: Promise<void> | null = null;

	/**
	 * Load templates from JSON file or API
	 */
	async loadTemplates(source?: string | ChecklistTemplateResponse): Promise<void> {
		if (this.loadPromise) {
			return this.loadPromise;
		}

		this.loadPromise = this._doLoad(source);
		return this.loadPromise;
	}

	private async _doLoad(source?: string | ChecklistTemplateResponse): Promise<void> {
		try {
			let data: ChecklistTemplateResponse;

			if (typeof source === 'string') {
				// Load from URL or file path
				const response = await fetch(source);
				if (!response.ok) {
					throw new Error(`Failed to load templates: ${response.statusText}`);
				}
				data = await response.json();
			} else if (source && typeof source === 'object') {
				// Use provided data directly
				data = source;
			} else {
				// Default: try to load from backend API or static file
				try {
					const response = await fetch('/api/checklist/templates');
					if (response.ok) {
						data = await response.json();
					} else {
						// Fallback to static file
						const fallbackResponse = await fetch('/checklist_templates_full.json');
						if (!fallbackResponse.ok) {
							throw new Error('No template source available');
						}
						data = await fallbackResponse.json();
					}
				} catch (apiError) {
					// Final fallback to static file
					const fallbackResponse = await fetch('/checklist_templates_full.json');
					if (!fallbackResponse.ok) {
						throw new Error('Failed to load templates from any source');
					}
					data = await fallbackResponse.json();
				}
			}

			this.validateTemplateData(data);
			this.templates = data.templates;
			this.processedData = this.processTemplates();
			
			console.log(`✅ Loaded ${this.templates.length} checklist templates`);
		} catch (error) {
			console.error('❌ Failed to load templates:', error);
			throw new Error(`Template loading failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
		}
	}

	/**
	 * Validate the loaded template data structure
	 */
	private validateTemplateData(data: any): void {
		if (!data || typeof data !== 'object') {
			throw new Error('Invalid template data: not an object');
		}

		if (!Array.isArray(data.templates)) {
			throw new Error('Invalid template data: templates is not an array');
		}

		if (data.templates.length === 0) {
			throw new Error('Invalid template data: no templates found');
		}

		// Validate each template has required fields
		for (let i = 0; i < data.templates.length; i++) {
			const template = data.templates[i];
			const requiredFields = ['id', 'title', 'description', 'category', 'required', 'scope'];
			
			for (const field of requiredFields) {
				if (!(field in template)) {
					throw new Error(`Template ${i} missing required field: ${field}`);
				}
			}

			if (typeof template.id !== 'string' || template.id.trim() === '') {
				throw new Error(`Template ${i} has invalid id`);
			}
		}
	}

	/**
	 * Process templates into organized categories
	 */
	private processTemplates(): ProcessedChecklistData {
		const categoryMap = new Map<string, ChecklistItem[]>();
		let requiredCount = 0;
		let manualCount = 0;
		let autoCount = 0;

		// Define category order for consistent display
		const categoryOrder = [
			'Governance & Risk Management',
			'Identity & Access Management', 
			'Logging & Monitoring',
			'Backup & Disaster Recovery',
			'Network Security',
			'Web Security',
			'Email Security',
			'Vulnerability Management',
			'Data Protection',
			'Audits & Certifications',
			'Awareness & Training'
		];

		for (const template of this.templates) {
			// Convert template to ChecklistItem
			const item: ChecklistItem = {
				id: template.id,
				title: template.title,
				description: template.description,
				category: template.category,
				status: 'no', // Default status
				lastUpdated: new Date().toISOString(),
				required: template.required,
				recommendation: template.recommendation,
				helpText: template.help_text,
				whyMatters: template.why_matters,
				kind: template.kind,
				readOnly: template.read_only,
				attachments: [],
				notes: '',
				coveredAssets: [],
				priority: template.priority,
				priority_number: template.priority_number,
				info: template.info ? {
					whatItMeans: template.info.what_it_means || template.description,
					whyItMatters: template.info.why_it_matters || template.why_matters,
					lawRefs: template.info.legal?.article_refs || [],
					priority: template.priority,
					priority_number: template.priority_number,
					resources: template.info.resources || [],
					guide: {
						non_technical_steps: template.info.guide?.non_technical_steps || [],
						scope_caveats: template.info.guide?.scope_caveats,
						acceptance_summary: template.info.guide?.acceptance_summary,
						faq: template.info.guide?.faq?.map(item => ({ q: item.question, a: item.answer })) || []
					}
				} : undefined
			};

			// Add to category map
			if (!categoryMap.has(template.category)) {
				categoryMap.set(template.category, []);
			}
			categoryMap.get(template.category)!.push(item);

			// Count statistics
			if (template.required) requiredCount++;
			if (template.kind === 'manual') manualCount++;
			if (template.kind === 'auto') autoCount++;
		}

		// Convert to ordered categories
		const categories: Array<{ name: string; items: ChecklistItem[] }> = [];

		// Add categories in defined order
		for (const categoryName of categoryOrder) {
			if (categoryMap.has(categoryName)) {
				const items = categoryMap.get(categoryName)!;
				// Sort items within category by required first, then alphabetically
				items.sort((a, b) => {
					if (a.required !== b.required) {
						return a.required ? -1 : 1;
					}
					return a.title.localeCompare(b.title);
				});
				categories.push({ name: categoryName, items });
			}
		}

		// Add any remaining categories not in the defined order
		for (const [categoryName, items] of categoryMap) {
			if (!categoryOrder.includes(categoryName)) {
				items.sort((a, b) => {
					if (a.required !== b.required) {
						return a.required ? -1 : 1;
					}
					return a.title.localeCompare(b.title);
				});
				categories.push({ name: categoryName, items });
			}
		}

		return {
			categories,
			totalItems: this.templates.length,
			requiredItems: requiredCount,
			manualItems: manualCount,
			autoItems: autoCount
		};
	}

	/**
	 * Get processed checklist data
	 */
	getProcessedData(): ProcessedChecklistData {
		if (!this.processedData) {
			throw new Error('Templates not loaded yet. Call loadTemplates() first.');
		}
		return this.processedData;
	}

	/**
	 * Get template info for info panel
	 */
	getTemplateInfo(templateId: string): InfoBlock | null {
		const template = this.templates.find(t => t.id === templateId);
		if (!template?.info) {
			return null;
		}

		return {
			whatItMeans: template.info.what_it_means || template.description || '',
			whyItMatters: template.info.why_it_matters || template.why_matters || '',
			lawRefs: template.info.legal?.article_refs || [],
			priority: template.priority,
			priority_number: template.priority_number,
			resources: template.info.resources || [],
			guide: {
				non_technical_steps: template.info.guide?.non_technical_steps || [],
				scope_caveats: template.info.guide?.scope_caveats,
				acceptance_summary: template.info.guide?.acceptance_summary,
				faq: template.info.guide?.faq?.map(item => ({ q: item.question, a: item.answer })) || []
			}
		};
	}

	/**
	 * Get template by ID
	 */
	getTemplate(templateId: string): ChecklistTemplate | null {
		return this.templates.find(t => t.id === templateId) || null;
	}

	/**
	 * Search templates by text
	 */
	searchTemplates(query: string): ChecklistTemplate[] {
		const lowQuery = query.toLowerCase();
		return this.templates.filter(template => 
			template.title.toLowerCase().includes(lowQuery) ||
			template.description.toLowerCase().includes(lowQuery) ||
			template.category.toLowerCase().includes(lowQuery) ||
			template.recommendation.toLowerCase().includes(lowQuery)
		);
	}

	/**
	 * Get templates by category
	 */
	getTemplatesByCategory(category: string): ChecklistTemplate[] {
		return this.templates.filter(t => t.category === category);
	}

	/**
	 * Check if templates are loaded
	 */
	isLoaded(): boolean {
		return this.processedData !== null;
	}

	/**
	 * Get loading statistics
	 */
	getStats() {
		if (!this.processedData) {
			return null;
		}

		return {
			totalItems: this.processedData.totalItems,
			requiredItems: this.processedData.requiredItems,
			manualItems: this.processedData.manualItems,
			autoItems: this.processedData.autoItems,
			categories: this.processedData.categories.length
		};
	}

	/**
	 * Reload templates (clears cache)
	 */
	async reload(source?: string | ChecklistTemplateResponse): Promise<void> {
		this.templates = [];
		this.processedData = null;
		this.loadPromise = null;
		return this.loadTemplates(source);
	}
}

// Export both class and singleton instance
export { TemplateLoaderService as TemplateLoader };
export const templateLoader = new TemplateLoaderService();