-- Stub kompatibilitas global. se_v2 memanggil TriggerTokenEvent,
-- resource penyedianya tidak ada di instalasi ini.
if type(TriggerTokenEvent) ~= 'function' then
    function TriggerTokenEvent(name, ...)
        TriggerEvent(name, ...)
    end
end