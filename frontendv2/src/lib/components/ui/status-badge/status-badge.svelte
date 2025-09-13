<script lang="ts">
	import { Badge } from '$lib/components/ui/badge';

	type Status = 'yes' | 'no' | 'na';

	interface Props {
		status: Status;
	}

	let { status }: Props = $props();

	const statusConfig = {
		yes: {
			variant: 'default' as const,
			class: 'bg-green-50 text-green-700 border-green-200',
			label: 'Yes - Compliant'
		},
		no: {
			variant: 'destructive' as const,
			class: 'bg-red-50 text-red-700 border-red-200',
			label: 'No - Non-Compliant'
		},
		na: {
			variant: 'secondary' as const,
			class: 'bg-gray-50 text-gray-700 border-gray-200',
			label: 'Not Applicable'
		}
	};

	let config = $derived(statusConfig[status] || statusConfig.na);
</script>

<Badge variant={config.variant} className={config.class}>
	{config.label}
</Badge>
