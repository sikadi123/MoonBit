import test from "node:test";
import assert from "node:assert/strict";

import {
  EMPTY_TEXT,
  buildBridgePayload,
  collectWarnings,
  deriveResultView,
  formatFileMeta,
  normalizePreviewLimitValue,
  splitNames,
} from "./app-core.mjs";

test("splitNames trims items and removes empty entries", () => {
  assert.deepEqual(splitNames(" name, lang , ,quote "), ["name", "lang", "quote"]);
});

test("normalizePreviewLimitValue floors numbers and falls back on invalid values", () => {
  assert.equal(normalizePreviewLimitValue("4.9"), 4);
  assert.equal(normalizePreviewLimitValue("-1"), 5);
  assert.equal(normalizePreviewLimitValue("abc", 3), 3);
});

test("formatFileMeta reports line count and byte size", () => {
  assert.equal(formatFileMeta("a,b\n1,2"), "2 行 · 7 bytes");
});

test("buildBridgePayload normalizes user input", () => {
  assert.deepEqual(
    buildBridgePayload({
      csvText: "name,lang",
      delimiter: "tab",
      strictColumnCount: 1,
      requiredHeadersText: "name, lang",
      selectedColumnsText: "name, quote",
      previewLimitValue: "6.8",
    }),
    {
      csvText: "name,lang",
      delimiter: "tab",
      strictColumnCount: true,
      requiredHeaders: ["name", "lang"],
      selectedColumns: ["name", "quote"],
      previewLimit: 6,
    },
  );
});

test("collectWarnings aggregates missing headers", () => {
  assert.deepEqual(
    collectWarnings(["id"], ["quote"]),
    ["缺失必需表头：id", "缺失选择列：quote"],
  );
});

test("deriveResultView summarizes successful analysis with warnings", () => {
  const view = deriveResultView({
    ok: true,
    inspection: {
      header: ["name", "lang"],
      preview_rows: [["MoonBit", "mbt"]],
      preview_records: [[
        { name: "name", value: "MoonBit" },
        { name: "lang", value: "mbt" },
      ]],
      missing_required_headers: ["quote"],
      selected_missing_headers: [],
      row_count: 1,
      column_count: 2,
      csv_text: "name,lang\nMoonBit,mbt",
      selected_csv_text: null,
    },
  });

  assert.equal(view.statusLabel, "已解析，存在提醒");
  assert.equal(view.statusType, "idle");
  assert.equal(view.message, "缺失必需表头：quote");
  assert.equal(view.rowCount, 1);
  assert.equal(view.columnCount, 2);
  assert.equal(view.selectedText, "name,lang\nMoonBit,mbt");
});

test("deriveResultView summarizes failed analysis", () => {
  const view = deriveResultView({
    ok: false,
    message: "line 2 has inconsistent column count",
  });

  assert.equal(view.statusLabel, "解析失败");
  assert.equal(view.statusType, "error");
  assert.equal(view.message, "line 2 has inconsistent column count");
  assert.equal(view.selectedText, EMPTY_TEXT);
});
