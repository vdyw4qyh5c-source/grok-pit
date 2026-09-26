import { createFileRoute, Link } from "@tanstack/react-router";
import { CopyLinkButton, ThemeToggle } from "@/components/chrome";
import { ArrowIcon, LinkGlyph, SocialGlyph } from "@/components/icons";
import { links, profile, socials, type PageLink } from "@/data/profile";
import { cn } from "@/lib/cn";

export const Route = createFileRoute("/")({
  component: Home,
});

const delays = ["d2", "d3", "d4", "d5", "d6"] as const;

function Row({ item }: { item: PageLink }) {
  const className = cn(
    "link-card flex min-h-16 items-center gap-3 rounded-card py-3 pr-3 pl-3",
    item.featured && "link-feature",
  );
  const body = (
    <>
      <span
        className={cn(
          "grid size-11 shrink-0 place-items-center rounded-full",
          item.featured ? "bg-accent-fg/15" : "bg-bg",
        )}
      >
        <LinkGlyph name={item.icon} />
      </span>
      <span className="min-w-0 flex-1 text-left">
        <span className="block text-base font-medium">{item.title}</span>
        <span className={cn("block text-sm", item.featured ? "text-accent-fg/80" : "text-muted")}>
          {item.hint}
        </span>
      </span>
      <span className="nudge grid size-10 shrink-0 place-items-center">
        <ArrowIcon className="size-5" />
      </span>
    </>
  );

  if (item.kind === "external") {
    return (
      <a className={className} href={item.href} target="_top" rel="noreferrer">
        {body}
      </a>
    );
  }

  return (
    <Link className={className} to={item.to}>
      {body}
    </Link>
  );
}

function Home() {
  return (
    <div className="relative min-h-dvh">
      <div className="grain" aria-hidden="true" />
      <header className="stage mx-auto flex w-full max-w-5xl items-center justify-between px-5 pt-5 md:px-10">
        <p className="font-display text-lg tracking-tight">{profile.site}</p>
        <div className="flex items-center gap-2">
          <CopyLinkButton />
          <ThemeToggle />
        </div>
      </header>

      <main className="stage mx-auto grid w-full max-w-5xl gap-10 px-5 pt-8 pb-16 md:grid-cols-[minmax(0,0.92fr)_minmax(0,1.08fr)] md:items-center md:gap-16 md:px-10 md:pt-12">
        <section className="rise d1 flex flex-col items-center text-center md:items-start md:text-left">
          <img
            src="/portrait.jpg"
            alt="Сергей Петрович с щенком питомника"
            width={768}
            height={1280}
            className="portrait size-32 rounded-full object-cover md:size-44"
          />
          <h1 className="font-display mt-6 text-4xl leading-none font-medium tracking-tight italic md:text-6xl">
            {profile.name}
          </h1>
          <p className="mt-3 text-sm font-medium tracking-widest text-muted uppercase">
            {profile.location}
          </p>
          <p className="mt-4 max-w-sm text-base leading-relaxed text-fg/80">{profile.bio}</p>
          <Link
            to="/breeds"
            className="mt-5 inline-flex h-11 items-center rounded-full bg-surface px-4 text-sm font-medium text-fg shadow-elev"
          >
            Цены от 70 000 ₽
          </Link>
        </section>

        <section>
          <nav aria-label="Разделы">
            <ul className="flex flex-col gap-3">
              {links.map((item, index) => (
                <li key={item.title} className={cn("rise", delays[index])}>
                  <Row item={item} />
                </li>
              ))}
            </ul>
          </nav>

          <div className="rise d7 mt-8">
            <p className="mb-3 text-center text-xs font-medium tracking-widest text-muted uppercase md:text-left">
              В сети
            </p>
            <ul className="flex items-center justify-center gap-3 md:justify-start">
              {socials.map((item) => (
                <li key={item.id}>
                  <a
                    className="social grid size-11 place-items-center rounded-full"
                    href={item.href}
                    target="_top"
                    rel="noreferrer"
                    aria-label={item.label}
                  >
                    <SocialGlyph name={item.id} />
                  </a>
                </li>
              ))}
            </ul>
            <p className="mt-6 text-center text-sm text-muted md:text-left">{profile.role}</p>
          </div>
        </section>
      </main>
    </div>
  );
}
