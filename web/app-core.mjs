export const sampleCsv = `name,lang,quote
MoonBit,mbt,"fast, simple, fun"
Rust,rs,"safe systems"
JavaScript,js,"web everywhere"`;

export const EMPTY_TEXT = "暂无结果";
export const DEFAULT_FILE_NAME = "尚未选择文件";
export const DEFAULT_FILE_META = "支持 `.csv` 文本文件";

export function splitNames(value = "") {
  return String(value)
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
}

export function normalizePreviewLimitValue(raw, fallback = 5) {
  const value = Number(raw ?? fallback);
  if (!Number.isFinite(value) || value < 0) {
    return fallback;
  }
  return Math.floor(value);
}

export function linesCount(text = "") {
  if (!String(text).trim()) {
    return 0;
  }
  return String(text).split(/\r?\n/).length;
}

export function csvByteSize(text = "") {
  return new TextEncoder().encode(String(text)).length;
}

export function formatFileMeta(text = "") {
  return `${linesCount(text)} 行 · ${csvByteSize(text)} bytes`;
}

export function inspectionCsvForSelected(inspection) {
  return inspection?.selected_csv_text ?? inspection?.csv_text ?? "";
}

export function collectWarnings(requiredMissing = [], selectedMissing = []) {
  const items = [];
  if (requiredMissing.length) {
    items.push(`缺失必需表头：${requiredMissing.join(", ")}`);
  }
  if (selectedMissing.length) {
    items.push(`缺失选择列：${selectedMissing.join(", ")}`);
  }
  return items;
}

export function buildBridgePayload({
  csvText = "",
  delimiter = ",",
  strictColumnCount = false,
  requiredHeadersText = "",
  selectedColumnsText = "",
  previewLimitValue = 5,
} = {}) {
  return {
    csvText,
    delimiter,
    strictColumnCount: Boolean(strictColumnCount),
    requiredHeaders: splitNames(requiredHeadersText),
    selectedColumns: splitNames(selectedColumnsText),
    previewLimit: normalizePreviewLimitValue(previewLimitValue),
  };
}

export function deriveResultView(response) {
  const jsonText = JSON.stringify(response, null, 2);

  if (!response?.ok) {
    return {
      ok: false,
      statusLabel: "解析失败",
      statusType: "error",
      message: response?.message ?? "CSV 解析失败",
      jsonText,
      header: [],
      previewRows: [],
      previewRecords: [],
      requiredMissing: [],
      selectedMissing: [],
      rowCount: 0,
      columnCount: 0,
      selectedText: EMPTY_TEXT,
    };
  }

  const inspection = response.inspection ?? {};
  const header = inspection.header ?? [];
  const previewRows = inspection.preview_rows ?? [];
  const previewRecords = inspection.preview_records ?? [];
  const requiredMissing = inspection.missing_required_headers ?? [];
  const selectedMissing = inspection.selected_missing_headers ?? [];
  const warnings = collectWarnings(requiredMissing, selectedMissing);

  return {
    ok: true,
    statusLabel: warnings.length ? "已解析，存在提醒" : "解析成功",
    statusType: warnings.length ? "idle" : "success",
    message: warnings.length
      ? warnings.join("；")
      : "解析完成，可以继续复制、下载规范化结果或列选择结果。",
    jsonText,
    header,
    previewRows,
    previewRecords,
    requiredMissing,
    selectedMissing,
    rowCount: inspection.row_count ?? 0,
    columnCount: inspection.column_count ?? 0,
    selectedText: inspectionCsvForSelected(inspection) || EMPTY_TEXT,
  };
}
