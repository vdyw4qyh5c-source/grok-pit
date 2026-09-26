import { createFileRoute } from "@tanstack/react-router";
import { PageFrame } from "@/components/chrome";
import { profile } from "@/data/profile";

export const Route = createFileRoute("/visit")({
  head: () => ({ meta: [{ title: "Как добраться — Питомник Москва" }] }),
  component: VisitPage,
});

function VisitPage() {
  return (
    <PageFrame>
      <p className="text-sm font-medium tracking-widest text-muted uppercase">Адрес</p>
      <h1 className="font-display mt-2 text-4xl font-medium tracking-tight italic md:text-5xl">
        Андреевка
      </h1>
      <p className="mt-4 text-base leading-relaxed">{profile.address}</p>
      <img
        src="/portrait.jpg"
        alt="Сергей Петрович у питомника со щенком"
        width={768}
        height={1280}
        className="portrait mt-6 w-full max-w-sm rounded-card"
      />
      <div className="mt-6 flex flex-col gap-3">
        <a
          href={profile.map}
          target="_top"
          rel="noreferrer"
          className="link-card link-feature inline-flex h-12 items-center justify-center rounded-full px-5 text-sm font-medium"
        >
          Открыть в Яндекс Навигаторе
        </a>
        <a
          href={profile.excursion}
          target="_top"
          rel="noreferrer"
          className="link-card inline-flex h-12 items-center justify-center rounded-full px-5 text-sm font-medium"
        >
          Записаться на экскурсию
        </a>
        <a
          href={profile.maxChat}
          target="_top"
          rel="noreferrer"
          className="link-card inline-flex h-12 items-center justify-center rounded-full px-5 text-sm font-medium"
        >
          Написать в MAX
        </a>
      </div>
    </PageFrame>
  );
}
