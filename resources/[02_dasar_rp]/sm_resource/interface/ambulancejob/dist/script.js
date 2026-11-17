import { fetchNuiFrame } from "../../wrapper/lib/index.js";

$(document).ready(function() {
    window.addEventListener('message', handleMessage);
});

const config = {
    respawnHoldTime: 5000, 
    progressUpdateInterval: 50, 
    emsCooldown: 300,
    helpMeCooldown: 5,
    ragdollCooldown: 5, // ADDED: 5 second cooldown for ragdoll
    billCost: 2000
};

let state = {
    timeRemaining: 0,
    isCritical: true,
    isSpaceHeld: false,
    emsCooldown: false,
    helpMeCooldown: false,
    ragdollCooldown: false, // ADDED
    respawnStartTime: 0,
    respawnTimerId: null,
    emsTimerId: null,
    helpMeTimerId: null,
    ragdollTimerId: null, // ADDED
    emsTimeRemaining: 0,
    helpMeTimeRemaining: 0,
    ragdollTimeRemaining: 0, // ADDED
    canRespawn: false
};

function formatTime(seconds) {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes.toString().padStart(2, '0')}:${remainingSeconds.toString().padStart(2, '0')}`;
}

function handleMessage(event) {
    const data = event.data;
    
    switch (data.action) {
        case 'hide':
            resetState();
            $('#inventory-warning').removeClass('active');
            $('body').fadeOut();
            break;

        case 'initState':
            resetState();
            $('#inventory-warning').removeClass('active');
            if (data.eventMode) {
                $('body').addClass('event-mode');
                if (data.eventCommand) {
                    $('#event-key').text(data.eventCommand);
                }
                if (data.eventHint) {
                    $('#event-text').text(data.eventHint);
                }
                $('#event-instruction').addClass('active');
            } else {
                $('body').removeClass('event-mode');
                $('#event-instruction').removeClass('active');
            }
            if (data.emsCooldown) {
                config.emsCooldown = data.emsCooldown;
            }
            if (data.billCost) {
                config.billCost = data.billCost;
                $('.time-value').text(`$${data.billCost}`);
            }
            if (data.show) {
                $('body').fadeIn();
            }
            if (typeof data.time === 'number') {
                updateTimer(data.time);
            }
            setCriticalState(true);
            break;

        case 'resetUI':
            resetState();
            $('#inventory-warning').removeClass('active');
            $('body').fadeOut();
            break;

        case 'show':
            resetState();
            $('#inventory-warning').removeClass('active');
            $('body').fadeIn();
            break;

        case 'updateTimer':
            updateTimer(data.time);
            break;

        case 'enableRespawn':
            enableRespawn();
            break;

        case 'setStatus':
            setStatus(data.status);
            break;
            
        case 'startRespawn':
            if (state.canRespawn) {
                state.isSpaceHeld = true;
                $('.key:contains("Space")').addClass('pressed');
                startRespawnTimer();
            }
            break;
            
        case 'holdRespawn':
            break;
            
        case 'cancelRespawn':
            state.isSpaceHeld = false;
            $('.key:contains("Space")').removeClass('pressed');
            cancelRespawnTimer();
            break;
            
        case 'helpMeCooldown':
            setHelpMeCooldown();
            break;
            
        // ADDED: Ragdoll cooldown
        case 'ragdollCooldown':
            setRagdollCooldown();
            break;
    }
}

function resetState() {
    state.isSpaceHeld = false;
    state.canRespawn = false;
    state.emsCooldown = false;
    state.helpMeCooldown = false;
    state.ragdollCooldown = false; // ADDED
    state.emsTimeRemaining = 0;
    state.helpMeTimeRemaining = 0;
    state.ragdollTimeRemaining = 0; // ADDED
    
    if (state.respawnTimerId) {
        clearInterval(state.respawnTimerId);
        state.respawnTimerId = null;
    }
    
    if (state.emsTimerId) {
        clearInterval(state.emsTimerId);
        state.emsTimerId = null;
    }

    if (state.helpMeTimerId) {
        clearInterval(state.helpMeTimerId);
        state.helpMeTimerId = null;
    }
    
    // ADDED
    if (state.ragdollTimerId) {
        clearInterval(state.ragdollTimerId);
        state.ragdollTimerId = null;
    }
    
    $('.key').removeClass('pressed');
    $('.progress-container').removeClass('active').hide();
    $('#respawn-instruction').removeClass('active');
    
    $('#respawn-progress').css('width', '0%');
    
    updateInstructionText();
    updateRagdollText(); // ADDED
}

function updateInstructionText() {
    let emsText = '';
    let helpText = '';
    
    if (state.emsCooldown) {
        const emsMinutes = Math.floor(state.emsTimeRemaining / 60);
        const emsSeconds = state.emsTimeRemaining % 60;
        emsText = `EMS Called - Wait ${emsMinutes}:${emsSeconds.toString().padStart(2, '0')} to call again`;
    } else {
        emsText = `<span class="initial-text">Press </span><span class="key" id="e-key">E</span> <span id="ems-text">to call EMS</span>`;
    }
    
    if (state.helpMeCooldown) {
        const helpMinutes = Math.floor(state.helpMeTimeRemaining / 60);
        const helpSeconds = state.helpMeTimeRemaining % 60;
        helpText = `Wait ${helpMinutes}:${helpSeconds.toString().padStart(2, '0')} for /helpme`;
    } else {
        helpText = `<span class="key" id="h-key">H</span> <span>for /helpme</span>`;
    }
    
    $('#ems-instruction').html(`
        ${emsText} or ${helpText}
    `);
    
    if (state.emsCooldown || state.helpMeCooldown) {
        $('#ems-instruction').addClass('ems-waiting');
    } else {
        $('#ems-instruction').removeClass('ems-waiting');
    }
}

// ADDED: Update ragdoll text
function updateRagdollText() {
    if (state.ragdollCooldown) {
        const ragdollSeconds = state.ragdollTimeRemaining;
        $('#ragdoll-instruction').html(`
            <span id="ragdoll-text">Wait ${ragdollSeconds}s to refresh body again</span>
        `).addClass('ems-waiting');
    } else {
        $('#ragdoll-instruction').html(`
            <span class="initial-text">Press </span><span class="key" id="g-key">G</span> <span id="ragdoll-text">to refresh body</span>
        `).removeClass('ems-waiting');
    }
}

function updateTimer(time) {
    state.timeRemaining = time;
    $('#timer').text(formatTime(Math.max(0, time)));
    
    if (time <= 0) {
        state.canRespawn = true;
        $('#respawn-instruction').addClass('active');
        $('#inventory-warning').addClass('active'); // ADDED
    } else {
        state.canRespawn = false;
        $('#respawn-instruction').removeClass('active');
        $('#inventory-warning').removeClass('active'); // ADDED
    }
}

function enableRespawn() {
    state.canRespawn = true;
    $('#respawn-instruction').addClass('active');
    $('#inventory-warning').addClass('active'); // ADDED
}

function setCriticalState(critical) {
    state.isCritical = critical;
    
    if (critical) {
        $('#status-text').html('You are <span class="critical">unconscious</span>');
        $('#timer').addClass('critical');
        
        updateInstructionText();
        updateRagdollText(); // ADDED
        $('#ems-instruction').removeClass('hidden');
        $('#ragdoll-instruction').removeClass('hidden'); // ADDED
        $('#emergency-instruction').removeClass('hidden');
    }
}

function setStatus(status) {
    if (status === 'ems_called') {
        state.emsCooldown = true;
        state.emsTimeRemaining = config.emsCooldown;
        
        if (state.emsTimerId) {
            clearInterval(state.emsTimerId);
        }
        
        state.emsTimerId = setInterval(updateEmsTimer, 1000);
        updateInstructionText();
        
    } else if (status === 'ems_accepted') {
        if (state.emsTimerId) {
            clearInterval(state.emsTimerId);
            state.emsTimerId = null;
        }
        state.emsCooldown = false;
        $('#ems-instruction').html(`
            <span id="ems-text">EMS are on their way - Press </span>
            <span class="key" id="h-key">H</span> <span>for /helpme</span>
        `).addClass('ems-waiting');
    }
}

function setHelpMeCooldown() {
    state.helpMeCooldown = true;
    state.helpMeTimeRemaining = config.helpMeCooldown;
    
    if (state.helpMeTimerId) {
        clearInterval(state.helpMeTimerId);
    }
    
    state.helpMeTimerId = setInterval(updateHelpMeTimer, 1000);
    updateInstructionText();
}

// ADDED: Set ragdoll cooldown
function setRagdollCooldown() {
    state.ragdollCooldown = true;
    state.ragdollTimeRemaining = config.ragdollCooldown;
    
    if (state.ragdollTimerId) {
        clearInterval(state.ragdollTimerId);
    }
    
    state.ragdollTimerId = setInterval(updateRagdollTimer, 1000);
    updateRagdollText();
}

function updateEmsTimer() {
    if (state.emsTimeRemaining <= 0) {
        if (state.emsTimerId) {
            clearInterval(state.emsTimerId);
            state.emsTimerId = null;
        }
        
        state.emsCooldown = false;
        state.emsTimeRemaining = 0;
        updateInstructionText();
        return;
    }

    state.emsTimeRemaining--;
    updateInstructionText();
}

function updateHelpMeTimer() {
    if (state.helpMeTimeRemaining <= 0) {
        if (state.helpMeTimerId) {
            clearInterval(state.helpMeTimerId);
            state.helpMeTimerId = null;
        }
        
        state.helpMeCooldown = false;
        state.helpMeTimeRemaining = 0;
        updateInstructionText();
        return;
    }

    state.helpMeTimeRemaining--;
    updateInstructionText();
}

// ADDED: Update ragdoll timer
function updateRagdollTimer() {
    if (state.ragdollTimeRemaining <= 0) {
        if (state.ragdollTimerId) {
            clearInterval(state.ragdollTimerId);
            state.ragdollTimerId = null;
        }
        
        state.ragdollCooldown = false;
        state.ragdollTimeRemaining = 0;
        updateRagdollText();
        return;
    }

    state.ragdollTimeRemaining--;
    updateRagdollText();
}

function startRespawnTimer() {
    if (!state.canRespawn || !state.isSpaceHeld) {
        return;
    }

    $('.progress-container').show().addClass('active');
    $('.progress-container').css({
        'display': 'block',
        'opacity': '1',
        'visibility': 'visible'
    });
    
    $('#respawn-progress').css('width', '0%');
    
    state.respawnStartTime = Date.now();
    
    if (state.respawnTimerId) {
        clearInterval(state.respawnTimerId);
        state.respawnTimerId = null;
    }
    
    state.respawnTimerId = setInterval(() => {
        if (!state.isSpaceHeld) {
            cancelRespawnTimer();
            return;
        }
        
        const elapsedTime = Date.now() - state.respawnStartTime;
        const progress = Math.min((elapsedTime / config.respawnHoldTime) * 100, 100);
        
        $('#respawn-progress').css({
            'width': `${progress}%`,
            'background': 'linear-gradient(90deg, #0078ff, #00a8ff)',
            'opacity': '1'
        });
        
        if (progress >= 100) {
            fetchNuiFrame("completeRespawn", {});
            cancelRespawnTimer();
        }
    }, config.progressUpdateInterval);
}

function cancelRespawnTimer() {
    if (state.respawnTimerId) {
        clearInterval(state.respawnTimerId);
        state.respawnTimerId = null;
    }
    
    $('#respawn-progress').css('width', '0%');
    $('.progress-container').removeClass('active').hide();
}