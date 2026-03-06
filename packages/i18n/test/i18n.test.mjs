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

test("i18n: design control keys are localized in en and ru", () => {
  assert.equal(translate("console.design.reset", "en"), "Reset to defaults");
  assert.equal(translate("console.design.reset", "ru"), "Сбросить по умолчанию");
  assert.equal(translate("console.design.palette.high_contrast", "ru"), "Высокий контраст");
  assert.equal(translate("console.audio.effect.action_success", "en"), "Action success melody");
  assert.equal(
    translate("console.audio.legal.note", "ru"),
    "Используйте только звуки, на которые у вас есть права. Эффекты по умолчанию генерируются процедурно без сторонних аудиофайлов."
  );
  assert.equal(translate("console.settings.group.profiles", "en"), "Settings Profiles");
  assert.equal(translate("console.settings.policy.locked", "ru"), "Заблокировано");
});
