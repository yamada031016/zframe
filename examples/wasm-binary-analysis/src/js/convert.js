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
  const offset = 0
  memoryBuffer.set(encodedData, offset);
  console.log(Object.keys(obj.instance.exports));
  const len = obj.instance.exports.hash(offset, encodedData.length);
  console.log(len)
  const res = memoryBuffer.slice(offset + encodedData.length, len);
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
  const wasmBinary = await file.arrayBuffer();

  const memory = obj.instance.exports.memory;
  const memoryBuffer = new Uint8ClampedArray(memory.buffer, obj.instance.exports.MEMORY.value, 65536);

  const offset = 0
  const wasm_data = new Uint8Array(wasmBinary);
  memoryBuffer.set(wasm_data, offset);
  console.log("memoryBuffer", memoryBuffer)

  const start = performance.now();
  const len = obj.instance.exports.wasmAnalyze(offset, wasm_data.length);
  const function_time = performance.now() - start
  console.log("function time: [ms]", (function_time));
  console.log("len", len)

  const newBuffer = new Uint8Array(memory.buffer, obj.instance.exports.MEMORY.value, 65536);
  console.log("newBuffer", newBuffer)
  console.log("wasm", wasmBinary.byteLength)
  console.log("hoge", newBuffer.length)
  const res_len = newBuffer[wasm_data.length];
  const res = newBuffer.slice(wasm_data.length + 1, wasm_data.length + 1 + len);
  console.log("res", res_len, res)

  const type_section_list = []
  var buffer_offset = 0;
  for (let i = 0; i < res_len; i++) {
    const { type_section, len } = TypeSecInfo.fromBytes(res.buffer, buffer_offset);
    buffer_offset += len;
    type_section_list.push(type_section);
  }
  console.log("type_section_list", type_section_list)

  const analysisTable = document.querySelector('div[is="analysis-table"]');
  if (analysisTable) {
    analysisTable.data = type_section_list
  } else {
    console.error('Element not found: div[is="analysis-table"]');
  }
}

class TypeSecInfo {
  constructor(args_type = [], result_type = []) {
    // args_typeとresult_typeはTypeEnumの配列
    this.args_type = args_type;      // 入力の型
    this.result_type = result_type;  // 出力の型
  }

  toBytes() {
    const buffer = new ArrayBuffer(256);
    const dataView = new DataView(buffer);
    let offset = 0;
    dataView.setInt32(offset, this.id, true);
    offset += 4;
    dataView.setFloat32(offset, this.value, true);
    offset += 4;
    for (let i = 0; i < 3; i++) {
      dataView.setUint8(offset, this.strings[i]?.charCodeAt(0) || 0);
      offset += 1;
    }
    return new Uint8Array(buffer);
  }

  static fromBytes(buffer, buffer_offset) {
    const dataView = new DataView(buffer, buffer_offset);
    let offset = 0;
    const args = [];
    const argsTypeLen = dataView.getUint8(offset, true)
    offset += 1;
    for (let i = 0; i < argsTypeLen; i++) {
      const argsLen = dataView.getUint8(offset, true)
      offset += 1;
      var args_output = ""
      for (let i = 0; i < argsLen; i++) {
        args_output += String.fromCharCode(dataView.getUint8(offset + i)); // バイトを文字に変換
      }
      offset += argsLen;
      args.push(args_output);
    }

    const result = [];
    const resultTypeLen = dataView.getUint8(offset, true)
    offset += 1;
    for (let i = 0; i < resultTypeLen; i++) {
      const resLen = dataView.getUint8(offset, true)
      offset += 1;
      var res_output = ""
      for (let i = 0; i < resLen; i++) {
        res_output += String.fromCharCode(dataView.getUint8(offset + i)); // バイトを文字に変換
      }
      offset += resLen;
      result.push(res_output);
    }

    return { type_section: new TypeSecInfo(args, result), len: offset };
  }
}
