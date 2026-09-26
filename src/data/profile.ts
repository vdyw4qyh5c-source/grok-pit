export const profile = {
  name: "Сергей Петрович",
  mark: "PITOMNIK",
  site: "pitomnikmoscow",
  handle: "pitomnikmoscow",
  role: "Руководитель питомника пуделей и дизайнерских пород",
  location: "Андреевка · Солнечногорск",
  bio: "Той, микро и миниатюрный пудель, тедди, мальтипу, бишон фризе, пушон и ши-тцу империал. Щенки от 70 000 ₽ до 2,5 млн ₽.",
  address: "141551, г. Солнечногорск, рп. Андреевка, ул. Цветочная, 23/1",
  map: "https://yandex.ru/navi?whatshere%5Bpoint%5D=37.128098%2C55.984234&whatshere%5Bzoom%5D=18.103397&ll=37.12819937670529%2C55.984478160986136&z=18.103397&si=mister.bsp",
  excursion: "https://pitomnikmoscow.online",
  survey: "https://pitomnikmoscow.online/survey",
  website: "https://pitomnikmoscow.ru/",
  maxChat: "https://max.ru/u/f9LHodD0cOIOVOT2hJ5HSSoFEL2JNelS8O2XlB7V1UUlkLo0PR44Sb0hFZs",
};

export const breeds = [
  { name: "Той-пудель", group: "Пудели" },
  { name: "Микропудель", group: "Пудели" },
  { name: "Миниатюрный пудель", group: "Пудели" },
  { name: "Тедди-пудель", group: "Пудели" },
  { name: "Мальтипу стандарт", group: "Дизайнерские" },
  { name: "Микро мальтипу", group: "Дизайнерские" },
  { name: "Пушон", group: "Дизайнерские" },
  { name: "Бишон фризе", group: "Компаньоны" },
  { name: "Ши-тцу империал", group: "Компаньоны" },
] as const;

export const priceFrom = "70 000 ₽";
export const priceTo = "2,5 млн ₽";

type BaseLink = {
  title: string;
  hint: string;
  icon: "calendar" | "book" | "pin" | "image" | "list";
  featured: boolean;
};

export type PageLink =
  | (BaseLink & { kind: "internal"; to: "/breeds" | "/visit" })
  | (BaseLink & { kind: "external"; href: string });

export const links: PageLink[] = [
  {
    kind: "external",
    href: profile.excursion,
    title: "Запись на экскурсию",
    hint: "Посмотреть щенков в питомнике",
    icon: "calendar",
    featured: true,
  },
  {
    kind: "internal",
    to: "/breeds",
    title: "Породы и цены",
    hint: "От 70 000 ₽ до 2,5 млн ₽",
    icon: "book",
    featured: false,
  },
  {
    kind: "external",
    href: profile.survey,
    title: "Готовы ли вы к щенку",
    hint: "Короткий тест перед решением",
    icon: "list",
    featured: false,
  },
  {
    kind: "external",
    href: profile.website,
    title: "Сайт питомника",
    hint: "pitomnikmoscow.ru",
    icon: "image",
    featured: false,
  },
  {
    kind: "internal",
    to: "/visit",
    title: "Как добраться",
    hint: "Андреевка, ул. Цветочная, 23/1",
    icon: "pin",
    featured: false,
  },
];

export const socials = [
  {
    id: "telegram",
    label: "Telegram",
    href: "https://t.me/pitomnikmoscow",
  },
  {
    id: "youtube",
    label: "YouTube",
    href: "https://youtube.com/@PitomnikMoscow?si=M1E27W8tb7uyS545",
  },
  {
    id: "vk",
    label: "ВКонтакте",
    href: "https://vk.ru/pitomnik_moscow",
  },
  {
    id: "max",
    label: "Канал в MAX",
    href: "https://max.ru/channel_pitomnikmoscow",
  },
] as const;
