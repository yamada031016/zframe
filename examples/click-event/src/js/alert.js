const test = (obj) => {
  const inputValue = this.document.getElementById("input");
  var res = obj.instance.exports.hash(inputValue);
  const p = this.document.getElementById("result");
  p.textContent = res;
  console.log(res);
}
