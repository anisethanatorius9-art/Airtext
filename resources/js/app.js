document.addEventListener('livewire:init', () => {
	Livewire.on('call-number', ({ number }) => {
		window.location.href = `tel:${number}`;
	});
});
