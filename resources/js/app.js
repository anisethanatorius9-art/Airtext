document.addEventListener('livewire:init', () => {
	Livewire.on('call-number', ({ number }) => {
		window.location.href = `tel:${number}`;
	});

	Livewire.on('share-call-number', ({ number }) => {
		navigator.clipboard?.writeText(number);
	});
});

const detectDeviceDetails = async () => {
	const display = document.querySelector('[data-device-display]');
	if (!display || display.dataset.detected || display.dataset.detecting) return;
	display.dataset.detecting = 'true';

	const userAgent = navigator.userAgent;
	const userAgentData = navigator.userAgentData;
	let model = userAgentData?.model?.trim() || '';
	let platform = userAgentData?.platform || '';
	let platformVersion = '';
	let browserVersion = '';

	if (userAgentData?.getHighEntropyValues) {
		try {
			const details = await userAgentData.getHighEntropyValues(['platformVersion', 'model', 'fullVersionList']);
			model ||= details.model?.trim() || '';
			platformVersion = details.platformVersion || '';
			browserVersion = details.fullVersionList?.find((item) => item.brand === 'Google Chrome')?.version || '';
		} catch {
			platformVersion = '';
		}
	}

	const android = userAgent.match(/Android[\s/]([\d.]+)(?:;\s*([^;)]+))?/i);
	const ios = userAgent.match(/(?:CPU (?:iPhone )?OS|iPhone OS) ([\d_]+)/i);
	const mac = userAgent.match(/Mac OS X ([\d_\.]+)/i);
	const windows = userAgent.match(/Windows NT ([\d.]+)/i);
	const chrome = userAgent.match(/(?:Chrome|CriOS)\/([\d.]+)/i);
	const edge = userAgent.match(/Edg(?:e|A|iOS)?\/([\d.]+)/i);
	const firefox = userAgent.match(/(?:Firefox|FxiOS)\/([\d.]+)/i);
	const safari = userAgent.match(/Version\/([\d.]+).*Safari/i);
	const isTablet = /iPad/i.test(userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);

	if (/iPhone/i.test(userAgent)) {
		platform = 'iPhone';
		model ||= 'iPhone';
	} else if (isTablet) {
		platform = 'iPad';
		model ||= 'iPad';
	} else if (android) {
		platform = 'Android';
		model ||= android[2]?.replace(/\s+Build\/.*$/i, '').trim() || '';
	} else if (/Windows/i.test(platform) || windows) {
		platform = 'Windows PC';
	} else if (/macOS|Mac OS/i.test(platform) || mac) {
		platform = 'Mac';
	} else if (/CrOS/i.test(userAgent)) {
		platform = 'ChromeOS';
	} else if (/Linux/i.test(userAgent)) {
		platform = 'Linux PC';
	}

	let osVersion = android?.[1]
		|| ios?.[1]?.replaceAll('_', '.')
		|| (platform === 'Mac' && platformVersion ? platformVersion : mac?.[1]?.replaceAll('_', '.'))
		|| '';
	if (windows) {
		const windowsVersion = Number.parseInt(platformVersion.split('.')[0] || '', 10);
		if (windowsVersion >= 13) {
			platform = 'Windows 11 PC';
			osVersion = '';
		} else if (windowsVersion >= 10) {
			platform = 'Windows 10 PC';
			osVersion = '';
		} else {
			osVersion = windows[1];
		}
	}
	if (!osVersion && platformVersion && !windows) osVersion = platformVersion;

	let browser = 'Browser';
	let detectedBrowserVersion = '';
	if (edge) {
		browser = 'Microsoft Edge';
		detectedBrowserVersion = edge[1];
	} else if (/OPR\//i.test(userAgent)) {
		browser = 'Opera';
		detectedBrowserVersion = userAgent.match(/OPR\/([\d.]+)/i)?.[1] || '';
	} else if (/SamsungBrowser\//i.test(userAgent)) {
		browser = 'Samsung Internet';
		detectedBrowserVersion = userAgent.match(/SamsungBrowser\/([\d.]+)/i)?.[1] || '';
	} else if (firefox) {
		browser = 'Firefox';
		detectedBrowserVersion = firefox[1];
	} else if (chrome) {
		browser = 'Chrome';
		detectedBrowserVersion = browserVersion || chrome[1];
	} else if (safari) {
		browser = 'Safari';
		detectedBrowserVersion = safari[1];
	}

	const modelLabel = model || (platform === 'Mac' ? 'Mac computer' : platform.includes('PC') ? platform : platform || 'Device');
	display.querySelector('[data-device-name]').textContent = modelLabel;
	display.querySelector('[data-device-os]').textContent = `${platform || 'Device'}${osVersion ? ` ${osVersion}` : ''}`;
	display.querySelector('[data-device-browser]').textContent = `${browser}${detectedBrowserVersion ? ` ${detectedBrowserVersion}` : ''}`;
	display.querySelector('[data-device-note]').textContent = model
		? 'Detected from this browser. Device models may be limited by browser privacy settings.'
		: 'Exact hardware model is not exposed by this browser; OS and browser details are shown instead.';
	display.dataset.detecting = 'false';
	display.dataset.detected = 'true';
};

const deviceDisplayObserver = new MutationObserver(() => {
	if (document.querySelector('[data-device-display]:not([data-detected]):not([data-detecting="true"])')) {
		void detectDeviceDetails();
	}
});

deviceDisplayObserver.observe(document.documentElement, { childList: true, subtree: true });
void detectDeviceDetails();
