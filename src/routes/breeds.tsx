import { createFileRoute } from "@tanstack/react-router";
import { PageFrame } from "@/components/chrome";
import { breeds, priceFrom, priceTo, profile } from "@/data/profile";

export const Route = createFileRoute("/breeds")({
  head: () => ({ meta: [{ title: "Породы и цены — Питомник Москва" }] }),
  component: BreedsPage,
});

function BreedsPage() {
  const poodles = breeds.filter((item) => item.group === "Пудели");
  const designer = breeds.filter((item) => item.group === "Дизайнерские");
  const companions = breeds.filter((item) => item.group === "Компаньоны");

  return (
    <PageFrame>
      <p className="text-sm font-medium tracking-widest text-muted uppercase">Питомник</p>
      <h1 className="font-display mt-2 text-4xl font-medium tracking-tight italic md:text-5xl">
        Породы и цены
      </h1>
      <p className="mt-3 text-base text-muted">
        Щенки Сергея Петровича: от {priceFrom} до {priceTo}. Точную стоимость называем по конкретному малышу — на экскурсии или на сайте.
      </p>

      <h2 className="font-display mt-8 text-2xl font-medium italic">Пудели</h2>
      <ul className="mt-3 flex flex-col gap-2">
        {poodles.map((item) => (
          <li key={item.name} className="link-card rounded-card px-4 py-3 font-medium">
            {item.name}
          </li>
        ))}
      </ul>

      <h2 className="font-display mt-8 text-2xl font-medium italic">Дизайнерские породы</h2>
      <ul className="mt-3 flex flex-col gap-2">
        {designer.map((item) => (
          <li key={item.name} className="link-card rounded-card px-4 py-3 font-medium">
            {item.name}
          </li>
        ))}
      </ul>

      <h2 className="font-display mt-8 text-2xl font-medium italic">Компаньоны</h2>
      <ul className="mt-3 flex flex-col gap-2">
        {companions.map((item) => (
          <li key={item.name} className="link-card rounded-card px-4 py-3 font-medium">
            {item.name}
          </li>
        ))}
      </ul>

      <a
        href={profile.website}
        target="_top"
        rel="noreferrer"
        className="link-card link-feature mt-8 inline-flex h-12 items-center rounded-full px-5 text-sm font-medium"
      >
        Смотреть на сайте
      </a>
    </PageFrame>
  );
}
