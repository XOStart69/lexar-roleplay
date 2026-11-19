/* crestview_Mansion :: patcher stub (node) */
const SHELLS = [
  { id: 'int_srg_crest_02', exterior: 'crestview_02', rooms: 12, garage: true }
];
on('onResourceStart', (res) => {
  if (res !== GetCurrentResourceName()) return;
  console.log(`[crestview_Mansion] patcher siap, ${SHELLS.length} interior`);
});
exports('GetShells', () => SHELLS);