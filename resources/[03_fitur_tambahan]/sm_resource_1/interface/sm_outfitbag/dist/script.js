var MODULE = 'sm_outfitbag';
var resourceName = null;

var state = { outfits: [], selectedId: null };

function post(cb, data) {
    if (!resourceName) return;
    fetch('https://' + resourceName + '/' + MODULE + ':' + cb, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data || {}),
    }).catch(function () {});
}

function el(id) { return document.getElementById(id); }

function setUseEnabled(enabled) {
    var btn = el('qbtnUse');
    if (btn) btn.disabled = !enabled;
}

function renderOutfits(outfits) {
    var grid = el('outfitGrid');
    var selectedName = el('selectedName');
    if (!grid) return;

    state.outfits = outfits || [];
    state.selectedId = null;

    if (!state.outfits.length) {
        grid.innerHTML = '<div class="outfit-empty">Belum ada outfit tersimpan.</div>';
        if (selectedName) selectedName.textContent = '-';
        return;
    }

    var html = '';
    for (var i = 0; i < state.outfits.length; i++) {
        var o = state.outfits[i];
        var label = (o.name || '').toString();
        html += '<div class="slot" data-id="' + o.id + '">';
        html += '<div class="slot-icon">' + (label ? label.toUpperCase() : '-') + '</div>';
        html += '<span class="slot-num">' + (i + 1) + '</span>';
        html += '</div>';
    }
    grid.innerHTML = html;
    if (selectedName) selectedName.textContent = '-';
    bindSlotClicks();
}

function bindSlotClicks() {
    var grid = el('outfitGrid');
    if (!grid) return;
    var slots = grid.querySelectorAll('.slot');
    for (var i = 0; i < slots.length; i++) {
        slots[i].onclick = function () {
            selectOutfit(this.getAttribute('data-id'));
        };
    }
}

function selectOutfit(id) {
    state.selectedId = id;
    var grid = el('outfitGrid');
    var selectedName = el('selectedName');
    if (!grid) return;
    var slots = grid.querySelectorAll('.slot');
    for (var i = 0; i < slots.length; i++) {
        slots[i].classList.toggle('slot-active', slots[i].getAttribute('data-id') === String(id));
    }
    var found = null;
    for (var j = 0; j < state.outfits.length; j++) {
        if (String(state.outfits[j].id) === String(id)) { found = state.outfits[j]; break; }
    }
    if (selectedName) selectedName.textContent = found ? found.name : '-';
    setUseEnabled(true);
    post('previewOutfit', { outfitId: id });
}

function showContainer(show) {
    var c = el('mainContainer');
    if (c) c.style.display = show ? 'flex' : 'none';
}

function renderOwner(owner) {
    owner = owner || {};
    var nameEl = el('ownerName');
    var cidEl = el('ownerCid');
    var name = (owner.name || '').toString().trim();
    if (nameEl) nameEl.textContent = name || 'Kamu';
    if (cidEl) cidEl.textContent = owner.cid ? ('CID ' + owner.cid) : '';
}

function openMenu(outfits) {
    if (window.resetBagZipper) window.resetBagZipper();
    state.selectedId = null;
    setUseEnabled(false);
    renderOutfits(outfits || []);
    showContainer(true);
}

function fadeOut() {
    if (window.resetBagZipper) window.resetBagZipper();
    showContainer(false);
}

function cancelMenu() {
    fadeOut();
    post('cancelPreview', {});
}

function confirmMenu() {
    if (!state.selectedId) return;
    fadeOut();
    post('confirmOutfit', { outfitId: state.selectedId });
}

window.addEventListener('message', function (event) {
    var data = event.data;
    if (!data) return;

    if (data.__frameInit) {
        if (data.resourceName) resourceName = data.resourceName;
        return;
    }

    switch (data.action) {
        case 'openMenu':
            renderOwner(data.owner);
            openMenu(data.outfits);
            break;
        case 'closeMenu':
            showContainer(false);
            break;
    }
});

document.addEventListener('keydown', function (event) {
    if (event.keyCode === 27) cancelMenu();
});

(function initActions() {
    var btnUse = el('qbtnUse');
    var btnCancel = el('qbtnCancel');
    var btnClose = el('menuClose');
    if (btnUse) btnUse.onclick = confirmMenu;
    if (btnCancel) btnCancel.onclick = cancelMenu;
    if (btnClose) btnClose.onclick = cancelMenu;
})();

(function initZipper() {
    var handle = el('zipperHandle');
    var progress = el('zipperProgress');
    var flap = el('bagFlap');
    var menu = el('bagMenu');
    var status = el('zipperStatus');
    var track = document.querySelector('.zipper-track-v');

    var isDragging = false;
    var hasUnlocked = false;

    function getTrackRect() {
        return track ? track.getBoundingClientRect() : { top: 0, height: 200 };
    }

    function updateUI(y, percent) {
        if (!handle || !progress) return;
        handle.style.top = y + 'px';
        progress.style.height = percent + '%';
        handle.style.boxShadow = '0 0 ' + (percent / 4) + 'vh rgba(0, 154, 183, 0.4)';
        if (status) status.style.opacity = percent > 80 ? '0' : '1';
    }

    function resetZipper() {
        handle.style.transition = 'top 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275)';
        progress.style.transition = 'height 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275)';
        updateUI(0, 0);
        setTimeout(function () {
            handle.style.transition = '';
            progress.style.transition = '';
            if (status) status.style.opacity = '1';
        }, 500);
    }

    function playZipperSound() {
        var audio = new Audio('./sound/zipper.mp3');
        audio.volume = 1;
        audio.play().catch(function () {});
    }

    function unlock() {
        if (hasUnlocked) return;
        hasUnlocked = true;
        playZipperSound();
        flap.classList.add('unzipping');
        setTimeout(function () {
            flap.classList.add('is-open');
            menu.classList.add('is-visible');
        }, 400);
    }

    function onMove(clientY) {
        var rect = getTrackRect();
        var y = clientY - rect.top;
        if (y < 0) y = 0;
        if (y > rect.height - 2) y = rect.height - 2;
        var percent = (y / rect.height) * 100;
        updateUI(y, percent);
        if (percent >= 95) unlock();
    }

    if (handle) {
        handle.addEventListener('mousedown', function (e) { e.preventDefault(); isDragging = true; });
        handle.addEventListener('touchstart', function (e) { e.preventDefault(); isDragging = true; });
    }

    function endDrag() {
        if (!isDragging) return;
        isDragging = false;
        var p = parseFloat(progress.style.height || '0');
        if (p < 95) resetZipper();
    }

    window.addEventListener('mouseup', endDrag);
    window.addEventListener('touchend', endDrag);
    window.addEventListener('mousemove', function (e) { if (isDragging) onMove(e.clientY); });
    window.addEventListener('touchmove', function (e) {
        if (isDragging && e.touches[0]) onMove(e.touches[0].clientY);
    }, { passive: false });

    window.resetBagZipper = function () {
        hasUnlocked = false;
        if (menu) menu.classList.remove('is-visible');
        if (flap) flap.classList.remove('is-open', 'unzipping');
        if (handle) handle.style.transition = '';
        if (progress) progress.style.transition = '';
        updateUI(0, 0);
        if (status) status.style.opacity = '1';
    };
})();
