<script lang="ts">
	import { Button } from '$lib/components/ui/button';
	import { Badge } from '$lib/components/ui/badge';
	import * as Dialog from '$lib/components/ui/dialog';
	import { Input } from '$lib/components/ui/input';
	import { Textarea } from '$lib/components/ui/textarea';
	import type { FileAttachment } from '$lib/types';
	import { apiClient } from '$lib/api/client';
	
	// Lucide Icons
	import FileText from '@lucide/svelte/icons/file-text';
	import Image from '@lucide/svelte/icons/image';
	import FileSpreadsheet from '@lucide/svelte/icons/file-spreadsheet';
	import Archive from '@lucide/svelte/icons/archive';
	import FileIcon from '@lucide/svelte/icons/file';

	interface Props {
		checklistKey: string;
		attachments: FileAttachment[];
		onFileUploaded: (attachment: FileAttachment) => void;
		onFileDeleted: (fileId: string) => void;
		readOnly?: boolean;
	}

	let { checklistKey, attachments, onFileUploaded, onFileDeleted, readOnly = false }: Props = $props();

	let fileInput = $state<HTMLInputElement>();
	let uploading = $state(false);
	let uploadError = $state<string | null>(null);
	let showUploadDialog = $state(false);
	let fileDescription = $state('');
	let selectedFile: File | null = $state(null);
	let showDeleteDialog = $state(false);
	let fileToDelete: FileAttachment | null = $state(null);
	let isDragOver = $state(false);
	let dragCounter = $state(0);

	// Supported file types
	const supportedTypes = [
		'image/jpeg', 'image/png', 'image/gif', 'image/webp',
		'application/pdf', 'text/plain', 'text/csv',
		'application/json', 'application/xml',
		'application/msword',
		'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
		'application/vnd.ms-excel',
		'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
		'application/zip', 'application/x-zip-compressed'
	];

	const maxFileSize = 50 * 1024 * 1024; // 50MB

	function validateAndSelectFile(file: File) {
		// Validate file type
		if (!supportedTypes.includes(file.type)) {
			uploadError = `File type "${file.type}" is not supported`;
			return false;
		}

		// Validate file size
		if (file.size > maxFileSize) {
			uploadError = `File size exceeds maximum allowed size of ${Math.round(maxFileSize / 1024 / 1024)}MB`;
			return false;
		}

		selectedFile = file;
		uploadError = null;
		showUploadDialog = true;
		return true;
	}

	function handleFileSelect(event: Event) {
		const input = event.target as HTMLInputElement;
		const file = input.files?.[0];
		
		if (!file) return;
		
		// Validate and select the file
		validateAndSelectFile(file);
		
		// Reset the input value so the same file can be selected again
		input.value = '';
	}

	// Drag and drop handlers
	function handleDragEnter(event: DragEvent) {
		event.preventDefault();
		event.stopPropagation();
		dragCounter++;
		if (event.dataTransfer?.types.includes('Files')) {
			isDragOver = true;
		}
	}

	function handleDragLeave(event: DragEvent) {
		event.preventDefault();
		event.stopPropagation();
		dragCounter--;
		if (dragCounter === 0) {
			isDragOver = false;
		}
	}

	function handleDragOver(event: DragEvent) {
		event.preventDefault();
		event.stopPropagation();
		if (event.dataTransfer) {
			event.dataTransfer.dropEffect = 'copy';
		}
	}

	function handleDrop(event: DragEvent) {
		event.preventDefault();
		event.stopPropagation();
		isDragOver = false;
		dragCounter = 0;

		const files = event.dataTransfer?.files;
		if (files && files.length > 0) {
			const file = files[0];
			validateAndSelectFile(file);
		}
	}

	async function uploadFile() {
		if (!selectedFile) return;

		uploading = true;
		uploadError = null;

		try {
			const formData = new FormData();
			formData.append('checklist_key', checklistKey);
			formData.append('description', fileDescription);
			formData.append('file', selectedFile);

			const response = await fetch(`${apiClient.baseUrl}/files/upload`, {
				method: 'POST',
				body: formData
			});

			if (!response.ok) {
				const error = await response.json();
				throw new Error(error.error || 'Upload failed');
			}

			const uploadResult = await response.json();
			
			// Create FileAttachment object from upload result
			const attachment: FileAttachment = {
				id: uploadResult.file_id,
				file_name: uploadResult.file_name,
				original_name: selectedFile.name,
				content_type: uploadResult.content_type,
				file_size: uploadResult.file_size,
				uploaded_at: uploadResult.uploaded_at,
				description: fileDescription,
				status: uploadResult.status
			};

			onFileUploaded(attachment);
			
			// Reset form
			selectedFile = null;
			fileDescription = '';
			showUploadDialog = false;
			// Clear the file input
			if (fileInput) {
				fileInput.value = '';
			}

		} catch (error) {
			console.error('File upload failed:', error);
			uploadError = error instanceof Error ? error.message : 'Upload failed';
		} finally {
			uploading = false;
		}
	}

	async function deleteFile(attachment: FileAttachment) {
		try {
			const response = await fetch(`${apiClient.baseUrl}/files/${attachment.id}`, {
				method: 'DELETE'
			});

			if (!response.ok) {
				const error = await response.json();
				throw new Error(error.error || 'Delete failed');
			}

			onFileDeleted(attachment.id);
			showDeleteDialog = false;
			fileToDelete = null;

		} catch (error) {
			console.error('File delete failed:', error);
			uploadError = error instanceof Error ? error.message : 'Delete failed';
		}
	}

	function downloadFile(attachment: FileAttachment) {
		// Create a temporary link to trigger download
		const link = document.createElement('a');
		link.href = `${apiClient.baseUrl}/files/${attachment.id}/download`;
		link.download = attachment.original_name;
		document.body.appendChild(link);
		link.click();
		document.body.removeChild(link);
	}

	function formatFileSize(bytes: number): string {
		if (bytes === 0) return '0 Bytes';
		const k = 1024;
		const sizes = ['Bytes', 'KB', 'MB', 'GB'];
		const i = Math.floor(Math.log(bytes) / Math.log(k));
		return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
	}

	function getFileIcon(contentType: string) {
		if (contentType.startsWith('image/')) return Image;
		if (contentType === 'application/pdf') return FileText;
		if (contentType.includes('word') || contentType.includes('document')) return FileText;
		if (contentType.includes('excel') || contentType.includes('spreadsheet')) return FileSpreadsheet;
		if (contentType.includes('zip')) return Archive;
		return FileIcon;
	}
</script>

<div class="space-y-3">
	<!-- File Upload Section -->
	{#if !readOnly}
		<div class="space-y-3">
			<h4 class="text-sm font-medium">Evidence Files</h4>
			
			<!-- Drag and Drop Zone -->
			<div
				class="relative border-2 border-dashed rounded-lg p-6 transition-all duration-200 {isDragOver 
					? 'border-primary bg-primary/5 scale-[1.02]' 
					: 'border-muted-foreground/25 hover:border-muted-foreground/50 hover:bg-muted/20'} {uploading ? 'opacity-50 pointer-events-none' : 'cursor-pointer'}"
				ondragenter={handleDragEnter}
				ondragleave={handleDragLeave}
				ondragover={handleDragOver}
				ondrop={handleDrop}
				onclick={(e) => {
					// Ensure we don't interfere with the file input
					if (e.target !== fileInput) {
						fileInput?.click();
					}
				}}
				role="button"
				tabindex="0"
				aria-label="Upload file by clicking or dragging and dropping"
				onkeydown={(e) => {
					if (e.key === 'Enter' || e.key === ' ') {
						e.preventDefault();
						if (fileInput) {
							fileInput.click();
						}
					}
				}}
			>
				<input
					bind:this={fileInput}
					type="file"
					class="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
					accept={supportedTypes.join(',')}
					onchange={handleFileSelect}
					disabled={uploading}
				/>
				
				<div class="flex flex-col items-center justify-center text-center">
					{#if uploading}
						<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mb-3"></div>
						<p class="text-sm text-muted-foreground">Uploading...</p>
					{:else if isDragOver}
						<svg class="h-8 w-8 text-primary mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
						</svg>
						<p class="text-sm font-medium text-primary">Drop file here</p>
					{:else}
						<svg class="h-8 w-8 text-muted-foreground mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
						</svg>
						<p class="text-sm font-medium text-foreground mb-1">
							Drag and drop a file here, or click to browse
						</p>
						<p class="text-xs text-muted-foreground">
							Supports images, PDFs, documents, and archives up to 50MB
						</p>
					{/if}
				</div>
			</div>
		</div>
	{/if}

	<!-- Error Message -->
	{#if uploadError}
		<div class="p-3 bg-red-50 border border-red-200 rounded-md">
			<div class="flex items-center">
				<svg class="h-4 w-4 text-red-600 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
				</svg>
				<span class="text-red-800 text-sm">{uploadError}</span>
						<button
							onclick={() => uploadError = null}
							class="ml-auto text-red-600 hover:text-red-800"
							aria-label="Dismiss error message"
						>
					<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
					</svg>
				</button>
			</div>
		</div>
	{/if}

	<!-- Attachments List -->
	{#if attachments.length > 0}
		<div class="space-y-2">
			{#each attachments as attachment}
				<div class="flex items-center justify-between p-3 bg-muted/30 rounded-md border">
					<div class="flex items-center gap-3 flex-1">
						{#each [getFileIcon(attachment.content_type)] as IconComponent}
							<IconComponent class="w-4 h-4 text-muted-foreground" />
						{/each}
						<div class="flex-1 min-w-0">
							<div class="flex items-center gap-2">
								<button
									class="text-sm font-medium text-primary hover:underline truncate"
									onclick={() => downloadFile(attachment)}
									title="Click to download"
								>
									{attachment.original_name}
								</button>
								<Badge variant="outline" class="text-xs">
									{formatFileSize(attachment.file_size)}
								</Badge>
								{#if attachment.status === 'uploading'}
									<Badge variant="secondary" class="text-xs">Uploading...</Badge>
								{:else if attachment.status === 'failed'}
									<Badge variant="destructive" class="text-xs">Failed</Badge>
								{/if}
							</div>
							{#if attachment.description}
								<p class="text-xs text-muted-foreground truncate">{attachment.description}</p>
							{/if}
							<p class="text-xs text-muted-foreground">
								Uploaded {new Date(attachment.uploaded_at).toLocaleDateString()}
							</p>
						</div>
					</div>
					{#if !readOnly && attachment.status === 'uploaded'}
						<Button
							variant="ghost"
							size="sm"
							onclick={() => {
								fileToDelete = attachment;
								showDeleteDialog = true;
							}}
							class="text-destructive hover:text-destructive"
							title="Delete file"
						>
							<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
							</svg>
						</Button>
					{/if}
				</div>
			{/each}
		</div>
	{:else}
		<div class="text-sm text-muted-foreground p-4 bg-muted/10 rounded-md text-center border border-muted-foreground/10">
			<svg class="h-6 w-6 text-muted-foreground/50 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
				<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
			</svg>
			No evidence files uploaded yet
		</div>
	{/if}
</div>

<!-- Upload Dialog -->
		<Dialog.Root open={showUploadDialog} onOpenChange={(open) => showUploadDialog = open}>
	<Dialog.Content class="sm:max-w-md">
		<Dialog.Header>
			<Dialog.Title>Upload Evidence File</Dialog.Title>
			<Dialog.Description>
				Add a file as evidence for this compliance requirement.
			</Dialog.Description>
		</Dialog.Header>
		
		{#if selectedFile}
			<div class="space-y-4">
				<div class="p-3 bg-muted/30 rounded-md">
					<div class="flex items-center gap-2">
						{#each [getFileIcon(selectedFile.type)] as IconComponent}
							<IconComponent class="w-4 h-4 text-muted-foreground" />
						{/each}
						<div>
							<p class="text-sm font-medium">{selectedFile.name}</p>
							<p class="text-xs text-muted-foreground">
								{formatFileSize(selectedFile.size)} • {selectedFile.type}
							</p>
						</div>
					</div>
				</div>

				<div>
					<label for="file-description" class="text-sm font-medium mb-2 block">
						Description (optional)
					</label>
					<Textarea
						id="file-description"
						placeholder="Describe what this file contains..."
						value={fileDescription}
						onchange={(e) => fileDescription = (e.target as HTMLTextAreaElement)?.value || ''}
						rows={2}
					/>
				</div>
			</div>
		{/if}

		<Dialog.Footer>
			<Button
				variant="outline"
				onclick={() => {
					showUploadDialog = false;
					selectedFile = null;
					fileDescription = '';
					// Clear the file input
					if (fileInput) {
						fileInput.value = '';
					}
				}}
			>
				Cancel
			</Button>
			<Button
				onclick={uploadFile}
				disabled={!selectedFile || uploading}
			>
				{#if uploading}
					<div class="animate-spin rounded-full h-4 w-4 border-b-2 border-current mr-2"></div>
				{/if}
				Upload
			</Button>
		</Dialog.Footer>
	</Dialog.Content>
</Dialog.Root>

<!-- Delete Confirmation Dialog -->
<Dialog.Root open={showDeleteDialog} onOpenChange={(open) => showDeleteDialog = open}>
	<Dialog.Content class="sm:max-w-md">
		<Dialog.Header>
			<Dialog.Title>Delete File</Dialog.Title>
			<Dialog.Description>
				Are you sure you want to delete this file? This action cannot be undone.
			</Dialog.Description>
		</Dialog.Header>
		
		{#if fileToDelete}
			<div class="p-3 bg-muted/30 rounded-md">
				<div class="flex items-center gap-2">
					{#each [getFileIcon(fileToDelete.content_type)] as IconComponent}
						<IconComponent class="w-4 h-4 text-muted-foreground" />
					{/each}
					<div>
						<p class="text-sm font-medium">{fileToDelete.original_name}</p>
						<p class="text-xs text-muted-foreground">
							{formatFileSize(fileToDelete.file_size)}
						</p>
					</div>
				</div>
			</div>
		{/if}

		<Dialog.Footer>
			<Button
				variant="outline"
				onclick={() => {
					showDeleteDialog = false;
					fileToDelete = null;
				}}
			>
				Cancel
			</Button>
			<Button
				variant="destructive"
				onclick={() => fileToDelete && deleteFile(fileToDelete)}
			>
				Delete
			</Button>
		</Dialog.Footer>
	</Dialog.Content>
</Dialog.Root>
