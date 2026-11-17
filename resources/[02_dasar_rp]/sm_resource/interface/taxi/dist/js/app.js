const taximeter   = document.getElementById('taximeter');
const fareEl      = document.getElementById('fare');
const distanceEl  = document.getElementById('distance');
const modal       = document.getElementById('historyModal');
const histList    = document.getElementById('historyList');
const closeHist   = document.getElementById('closeHistory');

const formatRupiah = n => '$ ' + Math.floor(n).toLocaleString('id-ID');
const formatDist   = m => m >= 1000 ? (m / 1000).toFixed(2) + ' km' : Math.floor(m) + ' m';

const setActiveButton = id =>
    ['start', 'pause', 'reset'].forEach(b =>
        document.getElementById(b).classList.toggle('active', b === id)
    );

const renderHistory = history => {
    histList.innerHTML = '';
    [...history].reverse().forEach(({ fare, distance }) => {
        const li = document.createElement('li');
        li.innerHTML = `<span class="hist-fare">${formatRupiah(fare)}</span><span class="hist-distance">${formatDist(distance)}</span>`;
        histList.appendChild(li);
    });
};

window.addEventListener('message', ({ data }) => {
    const { action } = data;

    if (action === 'ui') {
        taximeter.classList.toggle('hidden', !data.status);
    } else if (action === 'update') {
        fareEl.textContent    = formatRupiah(data.fare);
        distanceEl.textContent = formatDist(data.distance);
    } else if (action === 'updateHistory') {
        renderHistory(data.history);
    } else if (action === 'historyUI') {
        modal.classList.toggle('hidden', !data.status);
    } else if (action === 'setActive') {
        setActiveButton(data.button);
    }
});

closeHist.addEventListener('click', () => modal.classList.add('hidden'));
modal.addEventListener('click', e => { if (e.target === modal) modal.classList.add('hidden'); });