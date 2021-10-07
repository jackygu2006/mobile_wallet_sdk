/* eslint-disable */
import './wasm_exec';
import isArrayBuffer from 'is-array-buffer';

export const fetchSleeveGenerator = (bytesBuffer) => new Promise(async (res, rej) => {
  if (window.newSleeve) {
    res(window.newSleeve);
  }
  const go = new Go();
  if(isArrayBuffer(bytesBuffer)) {
    const result = await WebAssembly.instantiate(bytesBuffer, go.importObject);
    go.run(result.instance);
    res(window.newSleeve);
  } else {
    rej(false);
  }
});

(async () => {

})();
