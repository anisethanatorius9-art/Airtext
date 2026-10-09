document.addEventListener('livewire:init', () => {
	Livewire.on('call-number', ({ number }) => {
		window.location.href = `tel:${number}`;
	});

	Livewire.on('share-call-number', ({ number }) => {
		navigator.clipboard?.writeText(number);
	});
});
