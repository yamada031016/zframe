const convert = (obj) => {
  const inputValue = this.document.getElementById("input");

    //const offset = obj.instance.exports.getOffset();
    const memory = obj.instance.exports.memory;
    const memoryBuffer = new Uint8Array(memory.buffer, obj.instance.exports.MEMORY.value, 65536);

    const encoder = new TextEncoder();
    const encodedData = encoder.encode(inputValue.value);

    // メモリへの書き込み先のオフセット
  //console.log(offset);

    // メモリにデータをコピー
  const offset=0
  memoryBuffer.set(encodedData, offset);
  console.log(Object.keys(obj.instance.exports));
  const len = obj.instance.exports.hash(offset, encodedData.length);
  console.log(len)
  const res = memoryBuffer.slice(offset+encodedData.length, len);
  const hashValue = Array.from(res)
    .map(byte => byte.toString(16).padStart(2, '0'))
    .join('');
  console.log(encodedData);
  console.log(memoryBuffer);
  console.log(hashValue);
  const p = this.document.getElementById("result");
  p.textContent = hashValue;
}

const wasm = async (obj) => {
  const fileInput = this.document.getElementById("input");

  const file = fileInput.files[0];
  const wasmBinary = await file.arrayBuffer(); // Read the file as an ArrayBuffer

  const memory = obj.instance.exports.memory;
  const memoryBuffer = new Uint8ClampedArray(memory.buffer, obj.instance.exports.MEMORY.value, 65536);

  const offset=0
  const wasm_data = new Uint8Array(wasmBinary);
  memoryBuffer.set(wasm_data, offset);
  console.log("memoryBuffer", memoryBuffer)

  const len = obj.instance.exports.wasmAnalyze(offset, wasm_data.length);
  console.log("len", len)

  const newBuffer = new Uint8Array(memory.buffer, obj.instance.exports.MEMORY.value, 65536);
  console.log("newBuffer", newBuffer)
  console.log("wasm", wasmBinary.byteLength)
  console.log("hoge", newBuffer.length)
  const res = newBuffer.slice(wasm_data.length, wasm_data.length+len);
  console.log("res", res)

  const decoder = new TextDecoder("utf-8");
  const resultString = decoder.decode(res);
  console.log("resultString", resultString)

  const p = this.document.getElementById("result");
  p.textContent = resultString;
}
