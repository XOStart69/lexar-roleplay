const $ = (id) => document.getElementById(id);

const ICONS = {
	play: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M8 5.5v13a1 1 0 0 0 1.5.86l10.5-6.5a1 1 0 0 0 0-1.72L9.5 4.64A1 1 0 0 0 8 5.5z"/></svg>',
	pause: '<svg viewBox="0 0 24 24" fill="currentColor"><rect x="6" y="5" width="4" height="14" rx="1"/><rect x="14" y="5" width="4" height="14" rx="1"/></svg>',
	volume: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 5 6 9H2v6h4l5 4V5z"/><path d="M15.5 8.5a5 5 0 0 1 0 7"/><path d="M19 5a10 10 0 0 1 0 14"/></svg>',
	mute: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 5 6 9H2v6h4l5 4V5z"/><path d="m22 9-6 6"/><path d="m16 9 6 6"/></svg>',
	prev: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m15 18-6-6 6-6"/></svg>',
	next: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m9 18 6-6-6-6"/></svg>',
	discord: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M20.32 4.37A19.8 19.8 0 0 0 15.4 2.85a13.7 13.7 0 0 0-.63 1.29 18.4 18.4 0 0 0-5.53 0 12.6 12.6 0 0 0-.64-1.29 19.7 19.7 0 0 0-4.92 1.52C.53 9.05-.32 13.6.1 18.1a19.9 19.9 0 0 0 6.03 3.05 14.7 14.7 0 0 0 1.29-2.1 12.9 12.9 0 0 1-2.03-.97l.5-.39a14.2 14.2 0 0 0 12.2 0l.5.39c-.65.38-1.33.71-2.04.98.37.74.8 1.44 1.29 2.1a19.8 19.8 0 0 0 6.04-3.06c.5-5.2-.84-9.72-3.56-13.72zM8.02 15.33c-1.18 0-2.16-1.08-2.16-2.42 0-1.33.96-2.42 2.16-2.42 1.21 0 2.18 1.1 2.16 2.42 0 1.34-.96 2.42-2.16 2.42zm7.97 0c-1.19 0-2.16-1.08-2.16-2.42 0-1.33.95-2.42 2.16-2.42 1.2 0 2.17 1.1 2.16 2.42 0 1.34-.95 2.42-2.16 2.42z"/></svg>',
	link: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>'
};

const THEMES = {
	cyan:   { main: "38, 187, 183",  line: "0, 175, 170", img: "blue.jpg" },
	orange: { main: "255, 150, 0",   img: "orange.jpg" },
	red:    { main: "255, 70, 70",   img: "red.jpg" },
	blue:   { main: "0, 163, 255",   img: "blue.jpg" },
	green:  { main: "65, 220, 90",   img: "green.jpg" },
	pink:   { main: "255, 122, 237", img: "pink.jpg" },
	purple: { main: "193, 67, 255",  img: "purple.jpg" }
};

const STAGES = {
	INIT_CORE: "Loading game core",
	INIT_BEFORE_MAP_LOADED: "Preparing world",
	MAP: "Loading map",
	INIT_AFTER_MAP_LOADED: "Loading city assets",
	INIT_SESSION: "Joining session"
};
const STAGE_ORDER = Object.keys(STAGES);

const SOCIAL_LABELS = {
	discord: "Discord", instagram: "Instagram", youtube: "YouTube", twitter: "Twitter",
	tiktok: "TikTok", facebook: "Facebook", twitch: "Twitch", github: "GitHub"
};

const bg = $("bg");
const themeCfg = THEMES[theme] || THEMES.cyan;
document.documentElement.style.setProperty("--accent", themeCfg.main);
document.documentElement.style.setProperty("--accent-line", themeCfg.line || themeCfg.main);
bg.style.backgroundImage = `url('assets/img/${enableWinterUpdate ? "winter.jpg" : themeCfg.img}')`;

$("brandName").innerHTML = name;
$("brandSub").innerHTML = underName;
$("brandDesc").textContent = desc;

const socials = { discord, instagram, youtube, twitter, tiktok, facebook, twitch, github };
Object.keys(SOCIAL_LABELS).forEach((key) => {
	const url = socials[key];
	if (!url) return;
	const a = document.createElement("a");
	a.href = url;
	a.innerHTML = (ICONS[key] || ICONS.link) + `<span>${SOCIAL_LABELS[key]}</span>`;
	a.addEventListener("click", (e) => {
		e.preventDefault();
		if (window.invokeNative) window.invokeNative("openUrl", url);
	});
	$("socials").appendChild(a);
});

let displayPct = 0;
let targetPct = 0;
let pctAnim = 0;

function tickPct() {
	displayPct += (targetPct - displayPct) * 0.12;
	if (Math.abs(targetPct - displayPct) < 0.5) displayPct = targetPct;
	$("loadPct").textContent = Math.round(displayPct) + "%";
	pctAnim = displayPct !== targetPct ? requestAnimationFrame(tickPct) : 0;
}

function setProgress(pct) {
	targetPct = Math.max(targetPct, Math.min(100, pct));
	$("loadBar").style.transform = `scaleX(${targetPct / 100})`;
	if (!pctAnim) pctAnim = requestAnimationFrame(tickPct);
}

function setStage(type, text) {
	const step = STAGE_ORDER.indexOf(type);
	if (step >= 0) $("loadStep").textContent = `Step ${step + 1} / ${STAGE_ORDER.length}`;
	$("loadStage").textContent = text;
}

window.addEventListener("message", (e) => {
	const d = e.data;
	if (!d) return;
	if (d.eventName === "loadProgress") {
		setProgress(d.loadFraction * 100);
	} else if (d.eventName === "startInitFunctionOrder" && STAGES[d.type]) {
		setStage(d.type, STAGES[d.type]);
	} else if (d.eventName === "startDataFileEntries") {
		$("loadStage").textContent = "Loading data";
	} else if (d.eventName === "performMapLoadFunction") {
		setStage("MAP", STAGES.MAP);
	}
});

if (showStaffTeam && staff_team.length) {
	const groups = [];
	const byRank = {};
	staff_team.forEach((m) => {
		if (!byRank[m.rank]) {
			byRank[m.rank] = [];
			groups.push(m.rank);
		}
		byRank[m.rank].push(m);
	});

	const list = $("teamList");
	groups.forEach((rank) => {
		const group = document.createElement("div");
		group.className = "team-group";
		group.innerHTML = `<div class="team-rank label"></div>`;
		group.querySelector(".team-rank").textContent = rank;
		const grid = document.createElement("div");
		grid.className = "team-grid";
		byRank[rank].forEach((m) => {
			const row = document.createElement("div");
			row.className = "member";
			row.innerHTML = `<img src="${m.image}" alt=""><span></span>`;
			row.lastChild.textContent = m.name;
			grid.appendChild(row);
		});
		group.appendChild(grid);
		list.appendChild(group);
	});

	$("teamCount").textContent = staff_team.length + " Member";
	$("team").hidden = false;
}

let tipIndex = 0;
let tipStart = 0;
let tipRemaining = 0;
let tipTimer = 0;
let tipPaused = false;

function tipDuration(i) {
	return (tipsConfig[i].timeout || 10) * 1000;
}

function tipImage(img) {
	if (!img) return "";
	if (img.startsWith("/tips")) return `<img src="assets/img${img}" alt="">`;
	return `<img src="${img}" alt="">`;
}

function runTipBar() {
	const bar = $("tipBar");
	const total = tipDuration(tipIndex);
	bar.style.transition = "none";
	bar.style.transform = `scaleX(${(total - tipRemaining) / total})`;
	tipStart = Date.now();
	requestAnimationFrame(() => requestAnimationFrame(() => {
		if (tipPaused) return;
		bar.style.transition = `transform ${tipRemaining / 1000}s linear`;
		bar.style.transform = "scaleX(1)";
	}));
	clearTimeout(tipTimer);
	tipTimer = setTimeout(() => showTip(tipIndex + 1), tipRemaining);
}

function showTip(i) {
	const count = tipsConfig.length;
	tipIndex = (i + count) % count;
	const tip = tipsConfig[tipIndex];
	const body = $("tipBody");

	body.classList.add("fade");
	setTimeout(() => {
		body.innerHTML = `${tipImage(tip.img)}<h3 class="display"></h3><div class="accent-bar"></div><p></p>`;
		body.querySelector("h3").textContent = tip.title;
		body.querySelector("p").textContent = tip.text;
		body.classList.remove("fade");
	}, 150);

	$("tipCounter").textContent = `${String(tipIndex + 1).padStart(2, "0")} / ${String(count).padStart(2, "0")}`;
	$("tipDots").querySelectorAll("span").forEach((dot, n) => dot.classList.toggle("active", n === tipIndex));

	tipRemaining = tipDuration(tipIndex);
	if (!tipPaused) runTipBar();
}

if (showTipList && tipsConfig.length) {
	const dots = $("tipDots");
	tipsConfig.forEach((_, i) => {
		const dot = document.createElement("span");
		dot.addEventListener("click", () => showTip(i));
		dots.appendChild(dot);
	});

	$("tipPrev").innerHTML = ICONS.prev;
	$("tipNext").innerHTML = ICONS.next;
	$("tipPrev").addEventListener("click", () => showTip(tipIndex - 1));
	$("tipNext").addEventListener("click", () => showTip(tipIndex + 1));

	const card = $("tips");
	card.addEventListener("mouseenter", () => {
		if (tipPaused) return;
		tipPaused = true;
		clearTimeout(tipTimer);
		tipRemaining = Math.max(tipRemaining - (Date.now() - tipStart), 0);
		const total = tipDuration(tipIndex);
		const bar = $("tipBar");
		bar.style.transition = "none";
		bar.style.transform = `scaleX(${(total - tipRemaining) / total})`;
	});
	card.addEventListener("mouseleave", () => {
		if (!tipPaused) return;
		tipPaused = false;
		runTipBar();
	});

	card.hidden = false;
	showTip(0);
}

let audio = null;
let video = null;
let isMuted = false;
let isPaused = false;
const startVol = (musicConfig.defaultVolume ?? 100) / 100;

if (localAudio) {
	audio = new Audio("audio.mp3");
	audio.loop = true;
	audio.volume = startVol;
	audio.play().catch(() => {});
}

if (enableLocalVideo) {
	bg.style.background = "#000";

	function spawnVideo() {
		if (video) {
			clearInterval(video._watch);
			video.remove();
		}
		const el = document.createElement("video");
		el.autoplay = true;
		el.muted = localAudio || isMuted;
		el.setAttribute("playsinline", "");
		el.volume = startVol;
		el.style.filter = videoBlur ? `blur(${videoBlur}px)` : "";
		el.src = "video.webm?" + Date.now();
		el.addEventListener("ended", spawnVideo);

		let lastTime = 0;
		let stalled = 0;
		el._watch = setInterval(() => {
			if (el.readyState < 2) return;
			const dur = el.duration;
			if (isFinite(dur) && dur > 0 && el.currentTime >= dur - 0.3) return spawnVideo();
			if (el.paused) return;
			if (el.currentTime <= lastTime) {
				if (++stalled >= 4) return spawnVideo();
			} else {
				stalled = 0;
			}
			lastTime = el.currentTime;
		}, 250);

		bg.appendChild(el);
		el.play().catch(() => {});
		video = el;
		if (isPaused) el.pause();
	}

	spawnVideo();
} else if (youtubeVideo.startsWith("https://www.youtube.com")) {
	const id = new URL(youtubeVideo).searchParams.get("v");
	if (id) {
		const frame = document.createElement("iframe");
		frame.allow = "autoplay; encrypted-media";
		frame.src = `https://www.youtube.com/embed/${id}?autoplay=1&controls=0&disablekb=1&loop=1&playlist=${id}${localAudio ? "&mute=1" : ""}`;
		frame.style.opacity = showYoutubeVideo ? 1 : 0;
		frame.style.filter = videoBlur ? `blur(${videoBlur}px)` : "";
		if (showYoutubeVideo) bg.style.background = "#000";
		bg.appendChild(frame);
	}
	if (!showYoutubeVideo) document.body.classList.add("still");
} else {
	document.body.classList.add("still");
}

function syncMusicUi() {
	$("btnPlay").innerHTML = isPaused ? ICONS.play : ICONS.pause;
	$("btnMute").innerHTML = isMuted ? ICONS.mute : ICONS.volume;
	$("music").classList.toggle("playing", !isPaused && !isMuted);
}

function setVolume(v) {
	if (audio) audio.volume = v / 100;
	if (video) video.volume = v / 100;
	$("volText").textContent = v + "%";
	$("volFill").style.transform = `scaleX(${v / 100})`;
}

if (musicConfig.enabled && musicConfig.showMusicPlayer) {
	$("songTitle").textContent = musicConfig.songTitle;
	$("songArtist").textContent = musicConfig.artist;

	$("btnPlay").addEventListener("click", () => {
		isPaused = !isPaused;
		[audio, video].forEach((m) => m && (isPaused ? m.pause() : m.play().catch(() => {})));
		syncMusicUi();
	});

	$("btnMute").addEventListener("click", () => {
		isMuted = !isMuted;
		if (audio) audio.muted = isMuted;
		if (video) video.muted = localAudio || isMuted;
		syncMusicUi();
	});

	const vol = $("volume");
	vol.value = Math.round(startVol * 100);
	vol.addEventListener("input", () => setVolume(+vol.value));
	setVolume(+vol.value);
	syncMusicUi();
	$("music").hidden = false;
}

if (enableWinterUpdate) {
	const canvas = $("snow");
	const ctx = canvas.getContext("2d");
	let flakes = [];

	function resize() {
		canvas.width = innerWidth;
		canvas.height = innerHeight;
		flakes = Array.from({ length: 140 }, () => ({
			x: Math.random() * canvas.width,
			y: Math.random() * canvas.height,
			r: Math.random() * 2 + 0.6,
			s: Math.random() * 0.8 + 0.4,
			d: Math.random() * 0.6 - 0.3
		}));
	}

	function draw() {
		ctx.clearRect(0, 0, canvas.width, canvas.height);
		ctx.fillStyle = "rgba(255,255,255,0.6)";
		ctx.beginPath();
		flakes.forEach((f) => {
			f.y += f.s;
			f.x += f.d;
			if (f.y > canvas.height) { f.y = -4; f.x = Math.random() * canvas.width; }
			ctx.moveTo(f.x, f.y);
			ctx.arc(f.x, f.y, f.r, 0, Math.PI * 2);
		});
		ctx.fill();
		requestAnimationFrame(draw);
	}

	addEventListener("resize", resize);
	resize();
	canvas.style.display = "block";
	draw();
}
