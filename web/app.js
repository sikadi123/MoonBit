const sampleCsv = `name,lang,quote
MoonBit,mbt,"fast, simple, fun"
Rust,rs,"safe systems"
JavaScript,js,"web everywhere"`;

const state = {
  lastResponse: null,
};

const elements = {
  csvFile: document.getElementById("csv-file"),
  fileName: document.getElementById("file-name"),
  csvInput: document.getElementById("csv-input"),
  delimiter: document.getElementById("delimiter"),
  previewLimit: document.getElementById("preview-limit"),
  requiredHeaders: document.getElementById("required-headers"),
  selectedColumns: document.getElementById("selected-columns"),
  strictColumnCount: document.getElementById("strict-column-count"),
  analyzeButton: document.getElementById("analyze-button"),
  clearButton: document.getElementById("clear-button"),
  loadSampleButton: document.getElementById("load-sample"),
  statusBadge: document.getElementById("status-badge"),
  messageBox: document.getElementById("message-box"),
  statRows: document.getElementById("stat-rows"),
  statColumns: document.getElementById("stat-columns"),
  statRequiredMissing: document.getElementById("stat-required-missing"),
  statSelectedMissing: document.getElementById("stat-selected-missing"),
  headerChips: document.getElementById("header-chips"),
  previewTable: document.getElementById("preview-table"),
  selectedOutput: document.getElementById("selected-output"),
  jsonOutput: document.getElementById("json-output"),
  copyNormalized: document.getElementById("copy-normalized"),
  copySelected: document.getElementById("copy-selected"),
};

function splitNames(value) {
  return value
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
}

function setStatus(label, type) {
  elements.statusBadge.textContent = label;
  elements.statusBadge.className = `status-badge ${type}`;
}

function setMessage(text, type = "info") {
  if (!text) {
    elements.messageBox.classList.add("hidden");
    elements.messageBox.textContent = "";
    elements.messageBox.className = "message-box hidden";
    return;
  }
  elements.messageBox.textContent = text;
  elements.messageBox.className = `message-box ${type}`;
}

function resetResults() {
  state.lastResponse = null;
  setStatus("等待输入", "idle");
  setMessage("");
  elements.statRows.textContent = "-";
  elements.statColumns.textContent = "-";
  elements.statRequiredMissing.textContent = "-";
  elements.statSelectedMissing.textContent = "-";
  elements.headerChips.innerHTML = "";
  elements.previewTable.textContent = "暂无结果";
  elements.previewTable.className = "table-shell empty-state";
  elements.selectedOutput.textContent = "暂无结果";
  elements.jsonOutput.textContent = "暂无结果";
}

function renderPreviewTable(header, rows) {
  if (!header.length && !rows.length) {
    elements.previewTable.textContent = "暂无结果";
    elements.previewTable.className = "table-shell empty-state";
    return;
  }

  const table = document.createElement("table");
  const thead = document.createElement("thead");
  const tbody = document.createElement("tbody");
  const headRow = document.createElement("tr");
  const effectiveHeader = header.length
    ? header
    : rows[0]?.map((_, index) => `Column ${index + 1}`) ?? [];

  effectiveHeader.forEach((name) => {
    const th = document.createElement("th");
    th.textContent = name;
    headRow.appendChild(th);
  });
  thead.appendChild(headRow);

  rows.forEach((row) => {
    const tr = document.createElement("tr");
    const size = Math.max(effectiveHeader.length, row.length);
    for (let index = 0; index < size; index += 1) {
      const td = document.createElement("td");
      td.textContent = row[index] ?? "";
      tr.appendChild(td);
    }
    tbody.appendChild(tr);
  });

  table.append(thead, tbody);
  elements.previewTable.innerHTML = "";
  elements.previewTable.className = "table-shell";
  elements.previewTable.appendChild(table);
}

function renderResponse(response) {
  state.lastResponse = response;
  elements.jsonOutput.textContent = JSON.stringify(response, null, 2);

  if (!response.ok) {
    setStatus("解析失败", "error");
    setMessage(response.message ?? "CSV 解析失败", "error");
    elements.selectedOutput.textContent = "暂无结果";
    return;
  }

  const inspection = response.inspection;
  const header = inspection?.header ?? [];
  const previewRows = inspection?.preview_rows ?? [];
  const requiredMissing = inspection?.missing_required_headers ?? [];
  const selectedMissing = inspection?.selected_missing_headers ?? [];
  const warnings = [];

  if (requiredMissing.length) {
    warnings.push(`缺失必需表头: ${requiredMissing.join(", ")}`);
  }
  if (selectedMissing.length) {
    warnings.push(`缺失选择列: ${selectedMissing.join(", ")}`);
  }

  setStatus(warnings.length ? "已解析，存在提醒" : "解析成功", warnings.length ? "idle" : "success");
  setMessage(
    warnings.length
      ? warnings.join("；")
      : "解析完成，可以继续查看规范化结果与列投影。",
    warnings.length ? "info" : "info",
  );

  elements.statRows.textContent = String(inspection?.row_count ?? 0);
  elements.statColumns.textContent = String(inspection?.column_count ?? 0);
  elements.statRequiredMissing.textContent = String(requiredMissing.length);
  elements.statSelectedMissing.textContent = String(selectedMissing.length);

  elements.headerChips.innerHTML = "";
  header.forEach((name) => {
    const chip = document.createElement("span");
    chip.className = "chip";
    chip.textContent = name;
    elements.headerChips.appendChild(chip);
  });

  renderPreviewTable(header, previewRows);
  elements.selectedOutput.textContent =
    inspection?.selected_csv_text ?? inspection?.csv_text ?? "暂无结果";
}

async function runMoonBitBridge() {
  const payload = {
    csvText: elements.csvInput.value,
    delimiter: elements.delimiter.value,
    strictColumnCount: elements.strictColumnCount.checked,
    requiredHeaders: splitNames(elements.requiredHeaders.value),
    selectedColumns: splitNames(elements.selectedColumns.value),
    previewLimit: Number(elements.previewLimit.value || 5),
  };

  globalThis.__moonbitCsvBridgeInput = payload;
  globalThis.__moonbitCsvBridgeOutput = "";

  try {
    await import(`../_build/js/debug/build/cmd/webbridge/webbridge.js?t=${Date.now()}`);
  } catch (error) {
    throw new Error(
      "无法加载 MoonBit 前端桥接文件。请先在仓库根目录运行: moon build --target js src/cmd/webbridge",
    );
  }

  if (!globalThis.__moonbitCsvBridgeOutput) {
    throw new Error("MoonBit 桥接未返回结果，请确认 webbridge 构建成功。");
  }

  return JSON.parse(globalThis.__moonbitCsvBridgeOutput);
}

async function analyzeCsv() {
  if (!elements.csvInput.value.trim()) {
    setStatus("缺少输入", "error");
    setMessage("请先上传 CSV 文件或粘贴 CSV 内容。", "error");
    return;
  }

  setStatus("分析中", "idle");
  setMessage("正在调用 MoonBit 编译出的解析逻辑，请稍候。", "info");

  try {
    const response = await runMoonBitBridge();
    renderResponse(response);
  } catch (error) {
    setStatus("运行失败", "error");
    setMessage(error.message || String(error), "error");
  }
}

function loadSample() {
  elements.csvInput.value = sampleCsv;
  elements.requiredHeaders.value = "name,lang,quote";
  elements.selectedColumns.value = "name,quote";
  elements.previewLimit.value = "5";
  elements.delimiter.value = ",";
  elements.strictColumnCount.checked = false;
  elements.fileName.textContent = "示例数据";
  resetResults();
}

async function copyText(value, emptyMessage) {
  if (!value || value === "暂无结果") {
    setMessage(emptyMessage, "info");
    return;
  }

  try {
    await navigator.clipboard.writeText(value);
    setMessage("已复制到剪贴板。", "info");
  } catch {
    setMessage("复制失败，请检查浏览器权限。", "error");
  }
}

elements.csvFile.addEventListener("change", async (event) => {
  const [file] = event.target.files ?? [];
  if (!file) {
    elements.fileName.textContent = "尚未选择文件";
    return;
  }

  elements.fileName.textContent = file.name;
  elements.csvInput.value = await file.text();
  resetResults();
});

elements.loadSampleButton.addEventListener("click", loadSample);
elements.clearButton.addEventListener("click", () => {
  elements.csvInput.value = "";
  elements.requiredHeaders.value = "";
  elements.selectedColumns.value = "";
  elements.previewLimit.value = "5";
  elements.strictColumnCount.checked = false;
  elements.fileName.textContent = "尚未选择文件";
  resetResults();
});
elements.analyzeButton.addEventListener("click", analyzeCsv);
elements.copyNormalized.addEventListener("click", () =>
  copyText(state.lastResponse?.inspection?.csv_text, "当前没有可复制的规范化 CSV。"),
);
elements.copySelected.addEventListener("click", () =>
  copyText(
    state.lastResponse?.inspection?.selected_csv_text ??
      state.lastResponse?.inspection?.csv_text,
    "当前没有可复制的列选择结果。",
  ),
);

loadSample();
