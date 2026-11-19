/* brofx_mansion_06 :: runtime env (node stub) */
const RESOURCE = GetCurrentResourceName();
const VERSION = '2.0.7';
const SHELLS = [
  { id: 'brofx_mansion06', ytyp: 'brofx_mansion06_ytyp', rooms: 24, garage: true }
];
on('onResourceStart', (res) => {
  if (res !== RESOURCE) return;
  console.log(`[${RESOURCE}] v${VERSION} siap, ${SHELLS.length} shell terdaftar`);
});
exports('GetShells', () => SHELLS);