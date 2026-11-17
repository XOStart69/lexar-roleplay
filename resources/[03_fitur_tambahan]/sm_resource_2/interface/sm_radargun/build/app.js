const gun = document.getElementById('radarGun');
const scope = document.getElementById('gunScope');
const fields = ['speed', 'range', 'speedPrefix', 'rangePrefix', 'fastsl', 'slowsl', 'triggeredSpeed', 'plate'];
const nodes = {};
fields.forEach((id) => { nodes[id] = document.getElementById(id); });
const scopeSpeed = document.getElementById('scopeSpeed');

window.addEventListener('message', (event) => {
    const data = event.data || {};

    if (data.action === 'open') gun.classList.add('visible');
    else if (data.action === 'close') gun.classList.remove('visible');

    if (data.zoom === 'open') scope.classList.add('visible');
    else if (data.zoom === 'close') scope.classList.remove('visible');

    fields.forEach((id) => {
        if (data[id] !== undefined) nodes[id].textContent = data[id];
    });
    if (data.speed !== undefined) scopeSpeed.textContent = data.speed;
});
