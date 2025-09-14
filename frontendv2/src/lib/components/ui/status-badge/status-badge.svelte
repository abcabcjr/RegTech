<script lang="ts">
	import { Badge } from '$lib/components/ui/badge';

	type Status = 'yes' | 'no' | 'na';

	interface Props {
		status: Status;
	}

	let { status }: Props = $props();

	const statusConfig = {
		yes: {
			class: '!bg-green-50 !text-green-700 !border-green-200 hover:!bg-green-100',
			label: 'Yes - Compliant'
		},
		no: {
			class: '!bg-red-50 !text-red-700 !border-red-200 hover:!bg-red-100',
			label: 'No - Non-Compliant'
		},
		na: {
			class: '!bg-gray-50 !text-gray-700 !border-gray-200 hover:!bg-gray-100',
			label: 'Not Applicable'
		}
	};

	let config = $derived(statusConfig[status] || statusConfig.na);
</script>

<Badge class={config.class}>
	{config.label}
</Badge>
