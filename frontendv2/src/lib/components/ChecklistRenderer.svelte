<script lang="ts">
  import { onMount } from 'svelte';
  import { loadChecklistTemplates, getTemplateStats } from '../checklist/template-loader';
  import type { ChecklistSection } from '../types';
  import ChecklistItemCard from './ChecklistItemCard.svelte';
  import LoadingSpinner from './LoadingSpinner.svelte';

  interface Props {
    selectedCategory?: string | null;
    showOnlyRequired?: boolean;
    searchQuery?: string;
  }

  let {
    selectedCategory = null,
    showOnlyRequired = false,
    searchQuery = ''
  }: Props = $props();

  let sections: ChecklistSection[] = $state([]);
  let loading = $state(true);
  let error: string | null = $state(null);
  let stats = $state({ total: 0, required: 0, optional: 0, manual: 0, automated: 0 });

  // Reactive filtering
  let filteredSections = $derived.by(() => sections.map(section => ({
    ...section,
    items: section.items.filter(item => {
      // Category filter
      if (selectedCategory && section.id !== selectedCategory) {
        return false;
      }
      
      // Required filter
      if (showOnlyRequired && !item.required) {
        return false;
      }
      
      // Search filter
      if (searchQuery) {
        const query = searchQuery.toLowerCase();
        return (
          item.title.toLowerCase().includes(query) ||
          item.description.toLowerCase().includes(query) ||
          item.helpText.toLowerCase().includes(query)
        );
      }
      
      return true;
    })
  })).filter(section => section.items.length > 0));

  // Load templates on mount
  onMount(async () => {
    try {
      loading = true;
      sections = await loadChecklistTemplates();
      stats = getTemplateStats(sections);
      error = null;
    } catch (err) {
      error = err instanceof Error ? err.message : 'Failed to load checklist templates';
      console.error('Error loading templates:', err);
    } finally {
      loading = false;
    }
  });

  // Update item 
  function updateItem(updatedItem: any) {
    sections = sections.map(section => ({
      ...section,
      items: section.items.map(item => 
        item.id === updatedItem.id ? updatedItem : item
      )
    }));
  }
</script>

<div class="checklist-container">
  {#if loading}
    <div class="loading-container">
      <LoadingSpinner />
      <p>Loading checklist templates...</p>
    </div>
  {:else if error}
    <div class="error-container">
      <h3>❌ Error Loading Templates</h3>
      <p>{error}</p>
      <button onclick={() => window.location.reload()}>
        Retry
      </button>
    </div>
  {:else}
    <!-- Statistics Summary -->
    <div class="stats-summary">
      <div class="stat-card">
        <div class="stat-number">{stats.total}</div>
        <div class="stat-label">Total Items</div>
      </div>
      <div class="stat-card">
        <div class="stat-number">{stats.required}</div>
        <div class="stat-label">Required</div>
      </div>
      <div class="stat-card">
        <div class="stat-number">{stats.optional}</div>
        <div class="stat-label">Optional</div>
      </div>
      <div class="stat-card">
        <div class="stat-number">{stats.manual}</div>
        <div class="stat-label">Manual</div>
      </div>
      <div class="stat-card">
        <div class="stat-number">{stats.automated}</div>
        <div class="stat-label">Automated</div>
      </div>
    </div>

    <!-- Filter Controls -->
    <div class="filter-controls">
      <div class="search-box">
        <input 
          type="text" 
          placeholder="Search checklist items..." 
          bind:value={searchQuery}
        />
      </div>
      
      <div class="filter-toggles">
        <label class="toggle">
          <input 
            type="checkbox" 
            bind:checked={showOnlyRequired}
          />
          Show only required items
        </label>
      </div>

      <div class="category-selector">
        <select bind:value={selectedCategory}>
          <option value={null}>All Categories</option>
          {#each sections as section}
            <option value={section.id}>{section.title}</option>
          {/each}
        </select>
      </div>
    </div>

    <!-- Checklist Sections -->
    {#if filteredSections.length === 0}
      <div class="no-results">
        <h3>No items found</h3>
        <p>Try adjusting your search criteria or filters.</p>
      </div>
    {:else}
      {#each filteredSections as section (section.id)}
        <section class="checklist-section">
          <header class="section-header">
            <h2>{section.title}</h2>
            <p class="section-description">{section.description}</p>
            <div class="section-stats">
              {section.items.length} item{section.items.length !== 1 ? 's' : ''}
              • {section.items.filter(i => i.required).length} required
            </div>
          </header>

          <div class="section-items">
            {#each section.items as item (item.id)}
              <ChecklistItemCard
                {item}
                onUpdate={(updatedItem) => updateItem(updatedItem)}
              />
            {/each}
          </div>
        </section>
      {/each}
    {/if}
  {/if}
</div>

<style>
  .checklist-container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 1rem;
  }

  .loading-container {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    min-height: 200px;
    gap: 1rem;
  }

  .error-container {
    text-align: center;
    padding: 2rem;
    border: 2px solid #ef4444;
    border-radius: 8px;
    background: #fef2f2;
    color: #991b1b;
  }

  .error-container button {
    margin-top: 1rem;
    padding: 0.5rem 1rem;
    background: #ef4444;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
  }

  .stats-summary {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
    gap: 1rem;
    margin-bottom: 2rem;
  }

  .stat-card {
    background: white;
    border: 1px solid #e5e7eb;
    border-radius: 8px;
    padding: 1rem;
    text-align: center;
  }

  .stat-number {
    font-size: 2rem;
    font-weight: bold;
    color: #1f2937;
  }

  .stat-label {
    font-size: 0.875rem;
    color: #6b7280;
    margin-top: 0.25rem;
  }

  .filter-controls {
    display: grid;
    grid-template-columns: 1fr auto auto;
    gap: 1rem;
    align-items: center;
    margin-bottom: 2rem;
    padding: 1rem;
    background: white;
    border: 1px solid #e5e7eb;
    border-radius: 8px;
  }

  .search-box input {
    width: 100%;
    padding: 0.5rem;
    border: 1px solid #d1d5db;
    border-radius: 4px;
    font-size: 0.875rem;
  }

  .toggle {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    font-size: 0.875rem;
    white-space: nowrap;
  }

  .category-selector select {
    padding: 0.5rem;
    border: 1px solid #d1d5db;
    border-radius: 4px;
    font-size: 0.875rem;
    min-width: 200px;
  }

  .no-results {
    text-align: center;
    padding: 3rem;
    color: #6b7280;
  }

  .checklist-section {
    margin-bottom: 3rem;
  }

  .section-header {
    margin-bottom: 1.5rem;
  }

  .section-header h2 {
    margin: 0 0 0.5rem 0;
    color: #1f2937;
    font-size: 1.5rem;
  }

  .section-description {
    margin: 0 0 0.5rem 0;
    color: #6b7280;
    font-size: 1rem;
  }

  .section-stats {
    font-size: 0.875rem;
    color: #9ca3af;
  }

  .section-items {
    display: grid;
    gap: 1rem;
  }

  @media (max-width: 768px) {
    .filter-controls {
      grid-template-columns: 1fr;
    }
    
    .stats-summary {
      grid-template-columns: repeat(2, 1fr);
    }
    
    .stat-card {
      padding: 0.75rem;
    }
    
    .stat-number {
      font-size: 1.5rem;
    }
  }
</style>