export type Locale = "en" | "ru";

export const DEFAULT_LOCALE: Locale = "en";

const MESSAGES: Record<Locale, Record<string, string>> = {
  en: {
    "console.title": "Art Console",
    "console.subtitle": "Incident OS foundation shell",
    "console.locale.switch": "Switch language",
    "console.surface.command_center": "Command Center",
    "console.surface.event_river": "Event River",
    "console.surface.incident_room": "Incident Room",
    "console.surface.scenario_view": "Scenario View",
    "console.surface.time_field": "Time Field",
    "console.surface.audit_explorer": "Audit Explorer",
    "console.surface.action_studio": "Action Studio",
    "console.analytics.title": "Analytics Memory",
    "console.analytics.charts": "Charts Data",
    "console.analytics.instructions": "Auto Instructions",
    "console.tooltip.surface": "Open surface",
    "console.tooltip.evidence": "Open evidence source",
    "panel0.title": "Art Panel0",
    "panel0.subtitle": "Embedded emergency panel",
    "panel0.core_down": "Core is unavailable",
    "panel0.reload": "Reload"
  },
  ru: {
    "console.title": "Art Console",
    "console.subtitle": "Базовая оболочка Incident OS",
    "console.locale.switch": "Сменить язык",
    "console.surface.command_center": "Command Center",
    "console.surface.event_river": "Event River",
    "console.surface.incident_room": "Incident Room",
    "console.surface.scenario_view": "Scenario View",
    "console.surface.time_field": "Time Field",
    "console.surface.audit_explorer": "Audit Explorer",
    "console.surface.action_studio": "Action Studio",
    "console.analytics.title": "Память аналитики",
    "console.analytics.charts": "Данные для графиков",
    "console.analytics.instructions": "Авто-инструкции",
    "console.tooltip.surface": "Открыть рабочую поверхность",
    "console.tooltip.evidence": "Открыть первичное evidence",
    "panel0.title": "Art Panel0",
    "panel0.subtitle": "Embedded аварийная панель",
    "panel0.core_down": "Core недоступен",
    "panel0.reload": "Перезагрузить"
  }
};

export function resolveLocale(input?: string | null): Locale {
  const normalized = String(input || "").trim().toLowerCase();
  return normalized === "ru" ? "ru" : DEFAULT_LOCALE;
}

export function translate(key: string, locale: Locale = DEFAULT_LOCALE): string {
  const table = MESSAGES[locale] || MESSAGES[DEFAULT_LOCALE];
  return table[key] ?? MESSAGES[DEFAULT_LOCALE][key] ?? key;
}

export function dictionary(locale: Locale = DEFAULT_LOCALE): Record<string, string> {
  return { ...MESSAGES[locale] };
}
