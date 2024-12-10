const pcap = (obj) => {
  const fileInput = document.getElementById('pcapFile');
  const file = fileInput.files[0];
  // Read the file content as an ArrayBuffer
  const arrayBuffer = await file.arrayBuffer();
  const uint8Array = new Uint8Array(arrayBuffer);

    // WASMメモリにデータをコピー
    const memoryBuffer = new Uint8Array(wasm.instance.exports.memory.buffer);
    memoryBuffer.set(sampleData, 0); // メモリの先頭にデータを配置

  var res = obj.instance.exports.processPcap(uint8Array);
  console.log(res)
}
