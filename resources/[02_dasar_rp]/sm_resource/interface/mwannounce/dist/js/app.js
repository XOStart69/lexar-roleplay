var hideTimeout = null;
var tickInterval = null;
var activeAudio = null;

window.addEventListener('message', function(event) {
    if (!event.data || !event.data.action) return;
    if (event.data.action === 'mwannounce:show') showAnnounce(event.data.data);
});

function stopAudio() {
    if (!activeAudio) return;
    try { activeAudio.pause(); } catch (e) {}
    activeAudio = null;
}

function playAudio(volume) {
    stopAudio();
    var audio = new Audio('audio/danger.ogg');
    audio.loop = true;
    audio.volume = Math.min(Math.max(typeof volume === 'number' ? volume : 0.04, 0), 1);
    activeAudio = audio;
    audio.play().catch(function() {});
}

function clearTimers() {
    if (hideTimeout) { clearTimeout(hideTimeout); hideTimeout = null; }
    if (tickInterval) { clearInterval(tickInterval); tickInterval = null; }
}

function showAnnounce(data) {
    var bar = document.getElementById('mwBar');
    var timer = document.getElementById('mwTimer');
    var fill = document.getElementById('mwProgress');
    var duration = data.duration || 30000;
    var endAt = Date.now() + duration;

    clearTimers();

    document.getElementById('mwText').textContent = data.message;
    timer.textContent = Math.ceil(duration / 1000);
    fill.style.transition = 'none';
    fill.style.transform = 'scaleX(1)';
    bar.classList.remove('hidden', 'closing');

    void fill.offsetWidth;
    fill.style.transition = 'transform ' + duration + 'ms linear';
    fill.style.transform = 'scaleX(0)';

    playAudio(data.volume);

    tickInterval = setInterval(function() {
        timer.textContent = Math.max(0, Math.ceil((endAt - Date.now()) / 1000));
    }, 1000);

    hideTimeout = setTimeout(function() {
        clearTimers();
        stopAudio();
        bar.classList.add('closing');
        setTimeout(function() {
            bar.classList.add('hidden');
            bar.classList.remove('closing');
        }, 350);
    }, duration);
}
