import test from "node:test";
import assert from "node:assert/strict";
import { dictionary, resolveLocale, translate } from "../dist/index.js";

test("i18n: default locale is en", () => {
  assert.equal(resolveLocale(undefined), "en");
  assert.equal(translate("panel0.core_down", resolveLocale(undefined)), "Core is unavailable");
});

test("i18n: ru switch works", () => {
  assert.equal(resolveLocale("ru"), "ru");
  assert.equal(translate("panel0.core_down", "ru"), "Core недоступен");
});

test("i18n: dictionary returns copy", () => {
  const dict = dictionary("en");
  dict["console.title"] = "mutated";
  assert.equal(translate("console.title", "en"), "Art Console");
});
