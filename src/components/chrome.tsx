import { Link } from "@tanstack/react-router";
import { useState, type ReactNode } from "react";
import { ArrowLeftIcon, CheckIcon, LinkIcon, MoonIcon, SunIcon } from "@/components/icons";
import { cn } from "@/lib/cn";

const THEME_KEY = "pitomnik-theme";

function paintTheme(dark: boolean) {
  document.documentElement.classList.toggle("dark", dark);
  const meta = document.querySelector('meta[name="theme-color"]');
  if (meta) meta.setAttribute("content", dark ? "#14110f" : "#f3ece3");
}

export function toggleTheme() {
  const next = !document.documentElement.classList.contains("dark");
  paintTheme(next);
  localStorage.setItem(THEME_KEY, next ? "dark" : "light");
}

function SwapIcon({ on, children }: { on: boolean; children: ReactNode }) {
  return (
    <span
      className={cn(
        "icon-swap absolute inset-0 grid place-items-center",
        on ? "scale-100 opacity-100 blur-none" : "scale-[0.25] opacity-0 blur-sm",
      )}
    >
      {children}
    </span>
  );
}

export function ThemeToggle() {
  return (
    <button
      type="button"
      onClick={toggleTheme}
      aria-label="Переключить тему"
      className="grid size-11 place-items-center rounded-full bg-surface text-fg shadow-elev"
    >
      <span className="relative block size-5">
        <SunIcon className="icon-swap absolute inset-0 size-5 scale-[0.25] opacity-0 blur-sm dark:scale-100 dark:opacity-100 dark:blur-none" />
        <MoonIcon className="icon-swap absolute inset-0 size-5 dark:scale-[0.25] dark:opacity-0 dark:blur-sm" />
      </span>
    </button>
  );
}

export function CopyLinkButton() {
  const [copied, setCopied] = useState(false);

  async function copy() {
    const url = `${window.location.origin}/`;
    try {
      await navigator.clipboard.writeText(url);
    } catch {
      const input = document.createElement("textarea");
      input.value = url;
      document.body.appendChild(input);
      input.select();
      document.execCommand("copy");
      input.remove();
    }
    setCopied(true);
    window.setTimeout(() => setCopied(false), 1600);
  }

  return (
    <button
      type="button"
      onClick={copy}
      aria-label={copied ? "Ссылка скопирована" : "Скопировать ссылку на страницу"}
      className="grid size-11 place-items-center rounded-full bg-surface text-fg shadow-elev"
    >
      <span className="relative block size-5">
        <SwapIcon on={!copied}>
          <LinkIcon className="size-5" />
        </SwapIcon>
        <SwapIcon on={copied}>
          <CheckIcon className="size-5" />
        </SwapIcon>
      </span>
    </button>
  );
}

export function TopBar({ back = false }: { back?: boolean }) {
  return (
    <header className="stage mx-auto flex w-full max-w-5xl items-center justify-between px-5 pt-5 md:px-10">
      {back ? (
        <Link
          to="/"
          className="inline-flex h-11 items-center gap-2 rounded-full bg-surface pr-4 pl-3 text-sm font-medium text-fg shadow-elev"
        >
          <ArrowLeftIcon className="size-4" />
          На главную
        </Link>
      ) : (
        <p className="font-display text-lg tracking-tight">pitomnikmoscow</p>
      )}
      <div className="flex items-center gap-2">
        <CopyLinkButton />
        <ThemeToggle />
      </div>
    </header>
  );
}

export function PageFrame({
  children,
  wide = false,
}: {
  children: ReactNode;
  wide?: boolean;
}) {
  return (
    <div className="relative min-h-dvh">
      <div className="grain" aria-hidden="true" />
      <TopBar back />
      <main
        className={cn(
          "stage mx-auto w-full px-5 pt-8 pb-16 md:px-10",
          wide ? "max-w-5xl" : "max-w-xl",
        )}
      >
        {children}
      </main>
    </div>
  );
}

export function Field({ label, children }: { label: string; children: ReactNode }) {
  return (
    <label className="grid gap-2 text-sm font-medium">
      {label}
      {children}
    </label>
  );
}

export const fieldClass =
  "h-12 w-full rounded-xl bg-surface px-4 text-base font-normal text-fg shadow-elev outline-none";

export function Study({ tone, label }: { tone: string; label: string }) {
  return (
    <div className={cn("frame", tone)} role="img" aria-label={label}>
      <span className="sun" />
      <span className="window" />
      <span className="horizon" />
    </div>
  );
}
