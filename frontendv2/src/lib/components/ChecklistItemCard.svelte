<script lang="ts">
  import type { ChecklistItem } from '$lib/types';
  
  interface Props {
    item: ChecklistItem;
    onUpdate?: (item: ChecklistItem) => void;
    onToggleInfo?: () => void;
    showInfoButton?: boolean;
    infoExpanded?: boolean;
  }
  
  let { 
    item, 
    onUpdate,
    onToggleInfo,
    showInfoButton = false,
    infoExpanded = false
  }: Props = $props();
  
  let notesValue = $state(item.notes || '');
  
  function handleStatusChange(newStatus: 'yes' | 'no' | 'na') {
    const updatedItem: ChecklistItem = {
      ...item,
      status: newStatus,
      lastUpdated: new Date().toISOString()
    };
    onUpdate?.(updatedItem);
  }
  
  function handleNotesChange() {
    if (notesValue !== item.notes) {
      const updatedItem: ChecklistItem = {
        ...item,
        notes: notesValue,
        lastUpdated: new Date().toISOString()
      };
      onUpdate?.(updatedItem);
    }
  }
  
  function getStatusColor(status: string): string {
    switch (status) {
      case 'yes': return '#10b981'; // green
      case 'no': return '#ef4444';  // red
      case 'na': return '#6b7280';  // gray
      default: return '#6b7280';
    }
  }
  
  function getStatusText(status: string): string {
    switch (status) {
      case 'yes': return 'Compliant';
      case 'no': return 'Non-compliant';
      case 'na': return 'Not Applicable';
      default: return 'Unknown';
    }
  }
  
  function getPriorityIcon(priority?: string): string {
    switch (priority) {
      case 'must': return '🔴';
      case 'should': return '🟡';
      default: return '⚪';
    }
  }
</script>

<div class="checklist-item-card" class:required={item.required} class:readonly={item.readOnly}>
  <header class="item-header">
    <div class="item-title-row">
      <h3 class="item-title">
        {#if item.required}
          <span class="required-indicator" title="Required">*</span>
        {/if}
        {item.title}
        {#if item.info?.priority}
          <span class="priority-icon" title="Priority: {item.info.priority}">
            {getPriorityIcon(item.info.priority)}
          </span>
        {/if}
      </h3>
      
      <div class="item-badges">
        <span class="kind-badge" class:automated={item.kind === 'auto'} class:manual={item.kind === 'manual'}>
          {item.kind === 'auto' ? '🤖 Auto' : '👤 Manual'}
        </span>
        
        {#if item.readOnly}
          <span class="readonly-badge" title="Read-only (automatically managed)">
            🔒 Read-only
          </span>
        {/if}
      </div>
    </div>
    
    <p class="item-description">{item.description}</p>
  </header>

  <div class="item-content">
    <!-- Status Controls -->
    <div class="status-section">
      <span class="status-label">Compliance Status:</span>
      <div class="status-controls">
        {#if !item.readOnly}
          <button 
            class="status-button"
            class:active={item.status === 'yes'}
            style="border-color: {getStatusColor('yes')}"
            onclick={() => handleStatusChange('yes')}
          >
            ✓ Yes
          </button>
          <button 
            class="status-button"
            class:active={item.status === 'no'}
            style="border-color: {getStatusColor('no')}"
            onclick={() => handleStatusChange('no')}
          >
            ✗ No
          </button>
          <button 
            class="status-button"
            class:active={item.status === 'na'}
            style="border-color: {getStatusColor('na')}"
            onclick={() => handleStatusChange('na')}
          >
            N/A
          </button>
        {:else}
          <div class="readonly-status" style="color: {getStatusColor(item.status)}">
            <strong>{getStatusText(item.status)}</strong>
            <span class="readonly-note">(automatically determined)</span>
          </div>
        {/if}
      </div>
    </div>

    <!-- Help Text -->
    {#if item.helpText}
      <div class="help-section">
        <p class="help-text">💡 {item.helpText}</p>
      </div>
    {/if}

    <!-- Why It Matters -->
    {#if item.whyMatters}
      <div class="why-matters-section">
        <p class="why-matters"><strong>Why it matters:</strong> {item.whyMatters}</p>
      </div>
    {/if}

    <!-- Recommendation -->
    {#if item.recommendation}
      <div class="recommendation-section">
        <p class="recommendation"><strong>Recommendation:</strong> {item.recommendation}</p>
      </div>
    {/if}

    <!-- Notes/Justification -->
    {#if !item.readOnly}
      <div class="notes-section">
        <label for="notes-{item.id}">Notes/Justification:</label>
        <textarea
          id="notes-{item.id}"
          bind:value={notesValue}
          onblur={handleNotesChange}
          placeholder="Add notes, justification, or additional context..."
          rows="3"
        ></textarea>
      </div>
    {/if}

    <!-- Info Panel Toggle -->
    {#if showInfoButton && item.info}
      <div class="info-toggle-section">
        <button 
          class="info-toggle-button"
          onclick={onToggleInfo}
          type="button"
        >
          <span class="info-icon">ℹ️</span>
          {infoExpanded ? 'Hide' : 'Show'} Compliance Information
          <span class="toggle-arrow">{infoExpanded ? '▲' : '▼'}</span>
        </button>
      </div>
    {/if}

    <!-- Last Updated -->
    {#if item.lastUpdated}
      <div class="metadata">
        <small>Last updated: {new Date(item.lastUpdated).toLocaleDateString()}</small>
      </div>
    {/if}
  </div>
</div>

<style>
  .checklist-item-card {
    background: white;
    border: 1px solid #e5e7eb;
    border-radius: 8px;
    padding: 1.5rem;
    transition: border-color 0.2s ease;
  }

  .checklist-item-card.required {
    border-left: 4px solid #ef4444;
  }

  .checklist-item-card.readonly {
    background: #f9fafb;
  }

  .item-header {
    margin-bottom: 1rem;
  }

  .item-title-row {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    gap: 1rem;
    margin-bottom: 0.5rem;
  }

  .item-title {
    margin: 0;
    font-size: 1.125rem;
    font-weight: 600;
    color: #1f2937;
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  .required-indicator {
    color: #ef4444;
    font-weight: bold;
  }

  .priority-icon {
    font-size: 0.875rem;
  }

  .item-badges {
    display: flex;
    gap: 0.5rem;
    flex-shrink: 0;
  }

  .kind-badge, .readonly-badge {
    font-size: 0.75rem;
    padding: 0.25rem 0.5rem;
    border-radius: 12px;
    font-weight: 500;
  }

  .kind-badge.automated {
    background: #dbeafe;
    color: #1e40af;
  }

  .kind-badge.manual {
    background: #fef3c7;
    color: #92400e;
  }

  .readonly-badge {
    background: #f3f4f6;
    color: #6b7280;
  }

  .item-description {
    margin: 0;
    color: #6b7280;
    line-height: 1.5;
  }

  .status-section {
    margin-bottom: 1rem;
  }

  .status-label {
    display: block;
    font-weight: 500;
    margin-bottom: 0.5rem;
    color: #374151;
  }

  .status-controls {
    display: flex;
    gap: 0.5rem;
  }

  .status-button {
    padding: 0.5rem 1rem;
    border: 2px solid;
    border-radius: 6px;
    background: white;
    cursor: pointer;
    font-size: 0.875rem;
    font-weight: 500;
    transition: all 0.2s ease;
  }

  .status-button:hover {
    opacity: 0.8;
  }

  .status-button.active {
    background-color: currentColor;
    color: white;
  }

  .readonly-status {
    font-size: 0.875rem;
  }

  .readonly-note {
    font-size: 0.75rem;
    opacity: 0.7;
    margin-left: 0.5rem;
  }

  .help-section, .why-matters-section, .recommendation-section {
    margin-bottom: 1rem;
  }

  .help-text {
    margin: 0;
    padding: 0.75rem;
    background: #f0f9ff;
    border-radius: 6px;
    border-left: 4px solid #0ea5e9;
    font-size: 0.875rem;
  }

  .why-matters, .recommendation {
    margin: 0;
    font-size: 0.875rem;
    color: #374151;
  }

  .notes-section {
    margin-bottom: 1rem;
  }

  .notes-section label {
    display: block;
    font-weight: 500;
    margin-bottom: 0.5rem;
    color: #374151;
  }

  .notes-section textarea {
    width: 100%;
    padding: 0.75rem;
    border: 1px solid #d1d5db;
    border-radius: 6px;
    font-family: inherit;
    font-size: 0.875rem;
    resize: vertical;
  }

  .info-toggle-section {
    margin-top: 1.5rem;
    padding-top: 1rem;
    border-top: 1px solid #e5e7eb;
  }

  .info-toggle-button {
    background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
    border: none;
    color: white;
    cursor: pointer;
    font-size: 0.875rem;
    font-weight: 500;
    padding: 0.75rem 1rem;
    border-radius: 6px;
    display: flex;
    align-items: center;
    gap: 0.5rem;
    width: 100%;
    justify-content: center;
    transition: all 0.2s ease;
  }

  .info-toggle-button:hover {
    background: linear-gradient(135deg, #2563eb 0%, #1e40af 100%);
    transform: translateY(-1px);
    box-shadow: 0 4px 8px rgba(59, 130, 246, 0.3);
  }

  .info-icon {
    font-size: 1rem;
  }

  .toggle-arrow {
    font-size: 0.75rem;
    margin-left: auto;
  }



  .metadata {
    margin-top: 1rem;
    padding-top: 0.75rem;
    border-top: 1px solid #f3f4f6;
    color: #9ca3af;
  }

  @media (max-width: 768px) {
    .item-title-row {
      flex-direction: column;
      align-items: flex-start;
    }

    .status-controls {
      flex-direction: column;
    }

    .status-button {
      text-align: center;
    }
  }
</style>