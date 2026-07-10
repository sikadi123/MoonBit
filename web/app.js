import {
  DEFAULT_FILE_META,
  DEFAULT_FILE_NAME,
  EMPTY_TEXT,
  buildBridgePayload,
  collectWarnings,
  deriveResultView,
  formatFileMeta,
  inspectionCsvForSelected,
  normalizePreviewLimitValue,
  sampleCsv,
} from "./app-core.mjs";

const state = {
  lastResponse: null,
};

const elements = {
  uploadBox: document.querySelector(".upload-box"),
  csvFile: document.getElementById("csv-file"),
  fileName: document.getElementById("file-name"),
  fileMeta: document.getElementById("file-meta"),
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
  issueList: document.getElementById("issue-list"),
  previewTable: document.getElementById("preview-table"),
  previewRecords: document.getElementById("preview-records"),
  selectedOutput: document.getElementById("selected-output"),
  jsonOutput: document.getElementById("json-output"),
  copyNormalized: document.getElementById("copy-normalized"),
  downloadNormalized: document.getElementById("download-normalized"),
  copySelected: document.getElementById("copy-selected"),
  downloadSelected: document.getElementById("download-selected"),
  copyJson: document.getElementById("copy-json"),
};

function setStatus(label, type) {
  elements.statusBadge.textContent = label;
  elements.statusBadge.className = `status-badge ${type}`;
}

function setMessage(text, type = "info") {
  if (!text) {
    elements.messageBox.textContent = "";
    elements.messageBox.className = "message-box hidden";
    return;
  }
  elements.messageBox.textContent = text;
  elements.messageBox.className = `message-box ${type}`;
}

function emptyNode(node, className, text = EMPTY_TEXT) {
  node.innerHTML = "";
  node.textContent = text;
  node.className = className;
}

function normalizePreviewLimit() {
  const normalized = normalizePreviewLimitValue(elements.previewLimit.value, 5);
  elements.previewLimit.value = String(normalized);
  return normalized;
}

function setFileMeta(name, text) {
  elements.fileName.textContent = name;
  elements.fileMeta.textContent = formatFileMeta(text);
}

function resetFileMeta() {
  elements.fileName.textContent = DEFAULT_FILE_NAME;
  elements.fileMeta.textContent = DEFAULT_FILE_META;
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
  elements.issueList.innerHTML = "<li>当前没有校验提醒</li>";
  elements.issueList.className = "issue-list empty-list";
  emptyNode(elements.previewTable, "table-shell empty-state");
  emptyNode(elements.previewRecords, "record-grid empty-state");
  elements.selectedOutput.textContent = EMPTY_TEXT;
  elements.jsonOutput.textContent = EMPTY_TEXT;
}

function renderHeaderChips(header) {
  elements.headerChips.innerHTML = "";
  if (!header.length) {
    const chip = document.createElement("span");
    chip.className = "chip chip-muted";
    chip.textContent = "空表头";
    elements.headerChips.appendChild(chip);
    return;
  }
  header.forEach((name) => {
    const chip = document.createElement("span");
    chip.className = "chip";
    chip.textContent = name;
    elements.headerChips.appendChild(chip);
  });
}

function renderIssues(requiredMissing, selectedMissing) {
  const items = collectWarnings(requiredMissing, selectedMissing);

  elements.issueList.innerHTML = "";
  if (!items.length) {
    elements.issueList.className = "issue-list empty-list";
    elements.issueList.innerHTML = "<li>当前没有校验提醒</li>";
    return;
  }

  elements.issueList.className = "issue-list";
  items.forEach((item) => {
    const li = document.createElement("li");
    li.textContent = item;
    elements.issueList.appendChild(li);
  });
}

function renderPreviewTable(header, rows) {
  if (!header.length && !rows.length) {
    emptyNode(elements.previewTable, "table-shell empty-state");
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

function renderPreviewRecords(records) {
  if (!records.length) {
    emptyNode(elements.previewRecords, "record-grid empty-state");
    return;
  }

  elements.previewRecords.innerHTML = "";
  elements.previewRecords.className = "record-grid";
  records.forEach((record, index) => {
    const card = document.createElement("article");
    card.className = "record-card";

    const title = document.createElement("h4");
    title.textContent = `第 ${index + 1} 条记录`;
    card.appendChild(title);

    record.forEach((field) => {
      const row = document.createElement("div");
      row.className = "record-row";

      const label = document.createElement("span");
      label.className = "record-key";
      label.textContent = field.name;

      const value = document.createElement("span");
      value.className = "record-value";
      value.textContent = field.value || "(空)";

      row.append(label, value);
      card.appendChild(row);
    });

    elements.previewRecords.appendChild(card);
  });
}

function createDownload(filename, text) {
  const blob = new Blob([text], { type: "text/csv;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = filename;
  anchor.click();
  URL.revokeObjectURL(url);
}

function renderResponse(response) {
  state.lastResponse = response;
  const view = deriveResultView(response);
  elements.jsonOutput.textContent = view.jsonText;
  setStatus(view.statusLabel, view.statusType);
  setMessage(view.message, view.ok ? "info" : "error");
  elements.statRows.textContent = String(view.rowCount);
  elements.statColumns.textContent = String(view.columnCount);
  elements.statRequiredMissing.textContent = String(view.requiredMissing.length);
  elements.statSelectedMissing.textContent = String(view.selectedMissing.length);
  renderHeaderChips(view.header);
  renderIssues(view.requiredMissing, view.selectedMissing);
  renderPreviewTable(view.header, view.previewRows);
  renderPreviewRecords(view.previewRecords);
  elements.selectedOutput.textContent = view.selectedText;
}

async function runMoonBitBridge() {
  const payload = buildBridgePayload({
    csvText: elements.csvInput.value,
    delimiter: elements.delimiter.value,
    strictColumnCount: elements.strictColumnCount.checked,
    requiredHeadersText: elements.requiredHeaders.value,
    selectedColumnsText: elements.selectedColumns.value,
    previewLimitValue: elements.previewLimit.value,
  });
  elements.previewLimit.value = String(payload.previewLimit);

  globalThis.__moonbitCsvBridgeInput = payload;
  globalThis.__moonbitCsvBridgeOutput = "";

  try {
    await import(`../_build/js/debug/build/cmd/webbridge/webbridge.js?t=${Date.now()}`);
  } catch {
    throw new Error(
      "无法加载 MoonBit 前端桥接文件。请先在仓库根目录运行：moon build --target js src/cmd/webbridge",
    );
  }

  if (!globalThis.__moonbitCsvBridgeOutput) {
    throw new Error("MoonBit 桥接没有返回结果，请确认 webbridge 构建成功。");
  }

  try {
    return JSON.parse(globalThis.__moonbitCsvBridgeOutput);
  } catch {
    throw new Error("MoonBit 桥接返回了无法解析的 JSON。");
  }
}

function clearDragState() {
  elements.uploadBox?.classList.remove("is-dragging");
}

async function populateCsvFromFile(file) {
  const text = await file.text();
  elements.csvInput.value = text;
  setFileMeta(file.name, text);
  resetResults();
}

async function analyzeCsv() {
  const text = elements.csvInput.value;
  if (!text.trim()) {
    setStatus("缺少输入", "error");
    setMessage("请先上传 CSV 文件，或直接粘贴 CSV 内容。", "error");
    return;
  }

  setFileMeta(elements.fileName.textContent, text);
  setStatus("分析中", "idle");
  setMessage("正在调用 MoonBit 编译出的解析逻辑，请稍候。", "info");

  try {
    const response = await runMoonBitBridge();
    renderResponse(response);
  } catch (error) {
    setStatus("运行失败", "error");
    setMessage(error?.message || String(error), "error");
  }
}

function loadSample() {
  elements.csvInput.value = sampleCsv;
  elements.requiredHeaders.value = "name,lang,quote";
  elements.selectedColumns.value = "name,quote";
  elements.previewLimit.value = "5";
  elements.delimiter.value = ",";
  elements.strictColumnCount.checked = false;
  setFileMeta("示例数据", sampleCsv);
  resetResults();
}

async function copyText(value, emptyMessage) {
  if (!value || value === EMPTY_TEXT) {
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

function downloadText(text, filename, emptyMessage) {
  if (!text || text === EMPTY_TEXT) {
    setMessage(emptyMessage, "info");
    return;
  }
  createDownload(filename, text);
  setMessage(`已触发下载：${filename}`, "info");
}

elements.csvFile.addEventListener("change", async (event) => {
  const [file] = event.target.files ?? [];
  if (!file) {
    resetFileMeta();
    return;
  }

  await populateCsvFromFile(file);
});

elements.csvInput.addEventListener("input", () => {
  setFileMeta(elements.fileName.textContent, elements.csvInput.value);
});

elements.csvInput.addEventListener("keydown", (event) => {
  if (event.key === "Enter" && event.ctrlKey) {
    event.preventDefault();
    analyzeCsv();
  }
});

elements.previewLimit.addEventListener("change", normalizePreviewLimit);
elements.uploadBox?.addEventListener("dragenter", (event) => {
  event.preventDefault();
  elements.uploadBox.classList.add("is-dragging");
});
elements.uploadBox?.addEventListener("dragover", (event) => {
  event.preventDefault();
  elements.uploadBox.classList.add("is-dragging");
});
elements.uploadBox?.addEventListener("dragleave", (event) => {
  if (!elements.uploadBox.contains(event.relatedTarget)) {
    clearDragState();
  }
});
elements.uploadBox?.addEventListener("drop", async (event) => {
  event.preventDefault();
  clearDragState();
  const [file] = event.dataTransfer?.files ?? [];
  if (!file) {
    return;
  }
  elements.csvFile.files = event.dataTransfer.files;
  await populateCsvFromFile(file);
});
elements.loadSampleButton.addEventListener("click", loadSample);
elements.clearButton.addEventListener("click", () => {
  elements.csvInput.value = "";
  elements.requiredHeaders.value = "";
  elements.selectedColumns.value = "";
  elements.previewLimit.value = "5";
  elements.delimiter.value = ",";
  elements.strictColumnCount.checked = false;
  resetFileMeta();
  resetResults();
});
elements.analyzeButton.addEventListener("click", analyzeCsv);
elements.copyNormalized.addEventListener("click", () =>
  copyText(
    state.lastResponse?.inspection?.csv_text,
    "当前没有可复制的规范化 CSV。",
  ),
);
elements.downloadNormalized.addEventListener("click", () =>
  downloadText(
    state.lastResponse?.inspection?.csv_text,
    "normalized.csv",
    "当前没有可下载的规范化 CSV。",
  ),
);
elements.copySelected.addEventListener("click", () =>
  copyText(
    inspectionCsvForSelected(state.lastResponse?.inspection),
    "当前没有可复制的列选择结果。",
  ),
);
elements.downloadSelected.addEventListener("click", () =>
  downloadText(
    inspectionCsvForSelected(state.lastResponse?.inspection),
    "selected.csv",
    "当前没有可下载的列选择结果。",
  ),
);
elements.copyJson.addEventListener("click", () =>
  copyText(elements.jsonOutput.textContent, "当前没有可复制的 JSON 输出。"),
);

resetFileMeta();
loadSample();
