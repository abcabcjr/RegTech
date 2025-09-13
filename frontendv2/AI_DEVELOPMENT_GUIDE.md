# FrontendV2 Development Guide for AI Agents

## Project Overview

This is a **Svelte 5** application using **SvelteKit** for the RegTech compliance and asset management system. The frontend communicates with a Go backend API and provides interactive dashboards for asset visualization and compliance management.

## Key Technologies

- **Svelte 5** (with new runes syntax: `$state()`, `$props()`, `$effect()`, `$derived()`)
- **SvelteKit** (file-based routing)
- **TypeScript** (strict typing)
- **Tailwind CSS** (utility-first styling)
- **Shadcn-svelte** (UI component library)
- **vis-network** (graph visualization)
- **Vite** (build tool)

## Project Structure

```
frontendv2/src/
├── app.html                 # Main HTML template
├── app.css                  # Global styles
├── lib/                     # Shared libraries and utilities
│   ├── api/                 # API client and types
│   │   ├── Api.ts          # Auto-generated API client
│   │   └── client.ts       # API client wrapper with error handling
│   ├── components/         # Reusable components
│   │   └── ui/             # Shadcn-svelte UI components
│   ├── stores/             # Global state management
│   │   ├── assets.svelte.ts    # Asset data and job management
│   │   └── checklist.svelte.ts # Compliance checklist management
│   ├── env.ts              # Environment configuration
│   └── utils.ts            # Utility functions
└── routes/                 # SvelteKit file-based routing
    ├── +layout.svelte      # Root layout with navigation
    ├── +page.svelte        # Home page (Asset Graph)
    └── compliance/         # Compliance management
        └── +page.svelte    # Compliance overview page
```

## Svelte 5 Patterns and Runes

### State Management
```typescript
// Reactive state
let count = $state(0);
let items = $state([]);
let loading = $state(false);

// Derived state
let doubled = $derived(count * 2);
let filteredItems = $derived(() => items.filter(item => item.active));

// Props (replaces export let)
let { title, items = [] }: { title: string; items: Item[] } = $props();

// Effects (replaces onMount and reactive statements)
$effect(() => {
    // Runs when dependencies change
    console.log('Count changed:', count);
});

$effect(() => {
    // Cleanup function
    const interval = setInterval(() => {
        count++;
    }, 1000);
    
    return () => clearInterval(interval);
});
```

### Component Structure Pattern
```typescript
<script lang="ts">
    // Imports
    import { onMount } from 'svelte';
    import type { ComponentType } from '$lib/api/Api';
    import { someStore } from '$lib/stores/example.svelte';
    
    // Props
    let { 
        data = [], 
        loading = false 
    }: { 
        data: ComponentType[]; 
        loading?: boolean; 
    } = $props();
    
    // State
    let localState = $state('initial');
    let items = $state([]);
    
    // Derived
    let processedData = $derived(() => {
        return data.map(item => ({ ...item, processed: true }));
    });
    
    // Functions
    async function handleAction() {
        loading = true;
        try {
            await someStore.performAction();
        } catch (error) {
            console.error('Action failed:', error);
        } finally {
            loading = false;
        }
    }
    
    // Effects
    $effect(() => {
        // Initialize component
        loadData();
    });
</script>

<!-- Template -->
<div class="container">
    {#if loading}
        <div>Loading...</div>
    {:else if items.length === 0}
        <div>No items found</div>
    {:else}
        {#each items as item (item.id)}
            <div>{item.name}</div>
        {/each}
    {/if}
</div>
```

## Store Architecture

### Store Pattern (Svelte 5 Class-based)
```typescript
// stores/example.svelte.ts
import type { ApiType } from '$lib/api/Api';
import { apiClient } from '$lib/api/client';

export class ExampleStore {
    // State
    data: ApiType[] = $state([]);
    loading = $state(false);
    error: string | null = $state(null);
    
    // Computed
    get filteredData() {
        return this.data.filter(item => item.active);
    }
    
    // Actions
    async load() {
        if (this.loading) return;
        this.loading = true;
        this.error = null;
        
        try {
            const response = await apiClient.example.list();
            // Deep copy to avoid reference issues
            this.data = JSON.parse(JSON.stringify(response.data || []));
        } catch (error) {
            console.error('Failed to load data:', error);
            this.error = error instanceof Error ? error.message : 'Unknown error';
            this.data = [];
        } finally {
            this.loading = false;
        }
    }
    
    async create(item: Partial<ApiType>) {
        try {
            const response = await apiClient.example.create(item);
            await this.load(); // Refresh data
            return response.data;
        } catch (error) {
            console.error('Failed to create item:', error);
            throw error;
        }
    }
}

// Export singleton instance
export const exampleStore = new ExampleStore();
```

## API Integration

### API Client Usage
```typescript
// The API client is auto-generated from Swagger/OpenAPI specs
import { apiClient } from '$lib/api/client';

// Standard API calls
const response = await apiClient.assets.catalogueList({});
const asset = await apiClient.assets.detail(assetId);
const result = await apiClient.checklist.statusCreate({
    item_id: 'item-123',
    status: 'yes'
});

// Error handling is built into the client wrapper
```

### Type Safety
```typescript
// Import types from the generated API client
import type { 
    V1AssetSummary, 
    ModelDerivedChecklistItem,
    HandlerSetStatusRequest 
} from '$lib/api/Api';

// Use types for component props and state
let assets: V1AssetSummary[] = $state([]);
let checklist: ModelDerivedChecklistItem[] = $state([]);
```

## UI Components (Shadcn-svelte)

### Installation and Usage
```bash
# Install new components
npx shadcn-svelte add button card dialog input

# Never manually create UI components - always use shadcn-svelte
```

### Component Usage Pattern
```typescript
<script lang="ts">
    import { Button } from '$lib/components/ui/button';
    import * as Card from '$lib/components/ui/card';
    import * as Dialog from '$lib/components/ui/dialog';
    
    let dialogOpen = $state(false);
</script>

<Card.Root>
    <Card.Header>
        <Card.Title>Example Card</Card.Title>
        <Card.Description>Card description</Card.Description>
    </Card.Header>
    <Card.Content>
        <Button on:click={() => dialogOpen = true}>
            Open Dialog
        </Button>
    </Card.Content>
</Card.Root>

<Dialog.Root bind:open={dialogOpen}>
    <Dialog.Content>
        <Dialog.Header>
            <Dialog.Title>Dialog Title</Dialog.Title>
        </Dialog.Header>
        <Dialog.Footer>
            <Button on:click={() => dialogOpen = false}>Close</Button>
        </Dialog.Footer>
    </Dialog.Content>
</Dialog.Root>
```

## Routing and Navigation

### File-based Routing
- `routes/+page.svelte` → `/`
- `routes/compliance/+page.svelte` → `/compliance`
- `routes/settings/+page.svelte` → `/settings`

### Navigation Pattern
```typescript
// +layout.svelte - Root layout with navigation
<script lang="ts">
    import { page } from '$app/stores';
    
    let currentPath = $derived($page.url.pathname);
</script>

<nav class="bg-white shadow-sm border-b">
    <div class="max-w-7xl mx-auto px-4">
        <div class="flex justify-between h-16">
            <div class="flex space-x-8">
                <a 
                    href="/" 
                    class:text-blue-600={currentPath === '/'}
                    class:text-gray-500={currentPath !== '/'}
                >
                    Asset Graph
                </a>
                <a 
                    href="/compliance" 
                    class:text-blue-600={currentPath === '/compliance'}
                    class:text-gray-500={currentPath !== '/compliance'}
                >
                    Compliance
                </a>
            </div>
        </div>
    </div>
</nav>
```

## Key Application Features

### 1. Asset Graph Visualization
- **Location**: `routes/+page.svelte`
- **Purpose**: Interactive network graph of discovered assets
- **Key Components**: 
  - `vis-network` for graph rendering
  - Asset discovery dialog
  - Asset details drawer
  - Real-time job status updates

### 2. Compliance Management
- **Location**: `routes/compliance/+page.svelte`
- **Purpose**: Compliance checklist management and overview
- **Key Features**:
  - Global vs asset-specific checklists
  - Manual status updates (Yes/No/N/A)
  - Automated status from scan results
  - Template upload functionality
  - Compliance statistics and progress tracking

### 3. Real-time Updates
- **Pattern**: Polling-based updates using `setInterval`
- **Implementation**: Job status polling in `assets.svelte.ts`
- **Usage**: Asset scanning progress, compliance refresh

## Development Patterns

### 1. Adding a New Page
```typescript
// 1. Create route file: routes/newpage/+page.svelte
<script lang="ts">
    import { onMount } from 'svelte';
    import type { NewPageData } from '$lib/api/Api';
    import { Button } from '$lib/components/ui/button';
    
    let data: NewPageData[] = $state([]);
    let loading = $state(false);
    
    async function loadData() {
        loading = true;
        try {
            const response = await apiClient.newpage.list();
            data = response.data || [];
        } catch (error) {
            console.error('Failed to load data:', error);
        } finally {
            loading = false;
        }
    }
    
    $effect(() => {
        loadData();
    });
</script>

<div class="container mx-auto px-4 py-8">
    <h1 class="text-3xl font-bold mb-6">New Page</h1>
    
    {#if loading}
        <div>Loading...</div>
    {:else}
        <!-- Page content -->
    {/if}
</div>

// 2. Add navigation link in +layout.svelte
```

### 2. Adding a New Store
```typescript
// lib/stores/newfeature.svelte.ts
export class NewFeatureStore {
    items = $state([]);
    loading = $state(false);
    
    async load() {
        this.loading = true;
        try {
            const response = await apiClient.newfeature.list();
            this.items = JSON.parse(JSON.stringify(response.data || []));
        } catch (error) {
            console.error('Load failed:', error);
        } finally {
            this.loading = false;
        }
    }
}

export const newFeatureStore = new NewFeatureStore();
```

### 3. Adding Interactive Components
```typescript
// Always use event handlers with proper typing
function handleClick(event: MouseEvent) {
    // Handle click
}

function handleSubmit(event: SubmitEvent) {
    event.preventDefault();
    // Handle form submission
}

// File uploads
function handleFileUpload(event: Event) {
    const target = event.target as HTMLInputElement;
    const file = target.files?.[0];
    if (!file) return;
    
    // Process file
}
```

## Styling Guidelines

### Tailwind CSS Patterns
```typescript
// Container pattern
<div class="container mx-auto px-4 py-8 max-w-7xl">

// Card layouts
<div class="grid grid-cols-1 md:grid-cols-3 gap-6">

// Responsive design
<div class="flex flex-col md:flex-row space-y-4 md:space-y-0 md:space-x-4">

// Status indicators
<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
    Active
</span>
```

## Error Handling

### API Error Pattern
```typescript
async function performAction() {
    try {
        const result = await apiClient.action.perform(data);
        // Success handling
    } catch (error) {
        console.error('Action failed:', error);
        // Show user-friendly error message
        errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
    }
}
```

### Loading States
```typescript
let loading = $state(false);
let error = $state('');

async function loadData() {
    if (loading) return; // Prevent double-loading
    loading = true;
    error = '';
    
    try {
        // API call
    } catch (err) {
        error = err instanceof Error ? err.message : 'Failed to load data';
    } finally {
        loading = false;
    }
}
```

## Performance Considerations

### 1. State Management
- Use deep copying for API responses: `JSON.parse(JSON.stringify(data))`
- Avoid direct mutations of reactive state
- Use `$derived()` for computed values instead of storing computed state

### 2. Component Optimization
- Use `{#key}` blocks for efficient list updates
- Implement proper cleanup in `$effect()` return functions
- Avoid unnecessary re-renders with proper dependency tracking

### 3. API Optimization
- Implement loading states to prevent duplicate requests
- Cache data in stores when appropriate
- Use polling judiciously (clear intervals on component destroy)

## Testing Patterns

### Component Testing
```typescript
// Add console.log statements for debugging
console.log('Component state:', { loading, data });

// Use browser dev tools for reactive state inspection
// Svelte 5 provides excellent dev tools integration
```

## Common Pitfalls and Solutions

### 1. Svelte 5 Migration Issues
- **Problem**: Using old `export let` syntax
- **Solution**: Use `let { prop } = $props()` pattern

### 2. Reactivity Issues
- **Problem**: State not updating in UI
- **Solution**: Ensure you're using `$state()` and not mutating objects directly

### 3. API Integration
- **Problem**: Type mismatches
- **Solution**: Always import types from `$lib/api/Api.ts` and use them consistently

### 4. Styling Issues
- **Problem**: Components not styled correctly
- **Solution**: Use shadcn-svelte components, don't create custom UI components

## Development Workflow

1. **Plan the feature** - Identify required API endpoints, data flow, and UI components
2. **Create/update stores** - Add necessary state management
3. **Build UI components** - Use shadcn-svelte components and Tailwind CSS
4. **Implement API integration** - Use the generated API client
5. **Add error handling** - Implement proper loading states and error messages
6. **Test functionality** - Use browser dev tools and console logging
7. **Optimize performance** - Ensure proper reactivity and cleanup

## Key Files to Understand

1. **`src/lib/api/Api.ts`** - Auto-generated API client (don't edit manually)
2. **`src/lib/api/client.ts`** - API client wrapper with error handling
3. **`src/lib/stores/assets.svelte.ts`** - Asset management store pattern
4. **`src/lib/stores/checklist.svelte.ts`** - Compliance management store pattern
5. **`src/routes/+layout.svelte`** - Root layout and navigation
6. **`src/routes/+page.svelte`** - Asset graph implementation
7. **`src/routes/compliance/+page.svelte`** - Compliance dashboard implementation

This guide should provide a comprehensive understanding of the frontendv2 project structure and development patterns for AI agents working on this codebase.
