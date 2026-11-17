var hideTimeout = null;
var activeSiren = null;
var frameId = null;
var resourceName = null;

window.addEventListener('message', function(event) {
    if (event.data && event.data.__frameInit) {
        frameId = event.data.frameId;
        resourceName = event.data.resourceName;
    }
    if (!event.data || !event.data.action) return;
    if (event.data.action === 'siaga1:show') showAlert(event.data.data);
});

function stopSiren() {
    if (!activeSiren) return;
    try { activeSiren.pause(); } catch (e) {}
    activeSiren = null;
}

function playSiren() {
    stopSiren();
    var audio = new Audio('audio/siren.ogg');
    audio.loop = true;
    audio.volume = 0.3;
    activeSiren = audio;
    audio.play().catch(function() {});
}

function showAlert(data) {
    var bar = document.getElementById('alertBar');

    if (hideTimeout) {
        clearTimeout(hideTimeout);
        hideTimeout = null;
    }

    stopSiren();

    document.getElementById('scrollText').textContent = data.message;
    bar.classList.remove('hidden', 'closing');

    playSiren();

    hideTimeout = setTimeout(function() {
        bar.classList.add('closing');
        stopSiren();
        setTimeout(function() {
            bar.classList.add('hidden');
            bar.classList.remove('closing');
        }, 400);
        hideTimeout = null;
    }, data.duration || 60000);
}
