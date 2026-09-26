import type { SVGProps } from "react";

type IconProps = SVGProps<SVGSVGElement>;

function base(props: IconProps) {
  return {
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: "currentColor",
    strokeWidth: 1.75,
    strokeLinecap: "round" as const,
    strokeLinejoin: "round" as const,
    "aria-hidden": true,
    ...props,
  };
}

export function CameraIcon(props: IconProps) {
  return (
    <svg {...base(props)}>
      <path d="M4 8.5h3l1.2-2h7.6L17 8.5h3v9.5H4z" />
      <circle cx="12" cy="13" r="3" />
    </svg>
  );
}

export function BookIcon(props: IconProps) {
  return (
    <svg {...base(props)}>
      <path d="M5 5.5h6.2A2.8 2.8 0 0 1 14 8.3V19a2.4 2.4 0 0 0-2.2-1.5H5z" />
      <path d="M19 5.5h-6.2A2.8 2.8 0 0 0 10 8.3V19a2.4 2.4 0 0 1 2.2-1.5H19z" />
    </svg>
  );
}

export function CalendarIcon(props: IconProps) {
  return (
    <svg {...base(props)}>
      <rect x="4" y="5.5" width="16" height="14" rx="2" />
      <path d="M8 4v3M16 4v3M4 10h16" />
    </svg>
  );
}

export function ImageIcon(props: IconProps) {
  return (
    <svg {...base(props)}>
      <rect x="4" y="5" width="16" height="14" rx="2" />
      <circle cx="9" cy="10" r="1.3" />
      <path d="m7 16 3.2-3.2a1 1 0 0 1 1.4 0L16 16" />
    </svg>
  );
}

export function MailIcon(props: IconProps) {
  return (
    <svg {...base(props)}>
      <rect x="3.5" y="6" width="17" height="12" rx="2" />
      <path d="m4 7 8 6 8-6" />
    </svg>
  );
}

export function ArrowIcon(props: IconProps) {
  return (
    <svg {...base(props)}>
      <path d="M6 12h12M13 7l5 5-5 5" />
    </svg>
  );
}

export function ArrowLeftIcon(props: IconProps) {
  return (
    <svg {...base(props)}>
      <path d="M18 12H6M11 7l-5 5 5 5" />
    </svg>
  );
}

export function SunIcon(props: IconProps) {
  return (
    <svg {...base(props)}>
      <circle cx="12" cy="12" r="3.2" />
      <path d="M12 3.5v1.8M12 18.7v1.8M3.5 12h1.8M18.7 12h1.8M6 6l1.3 1.3M16.7 16.7 18 18M18 6l-1.3 1.3M7.3 16.7 6 18" />
    </svg>
  );
}

export function MoonIcon(props: IconProps) {
  return (
    <svg {...base(props)}>
      <path d="M15.5 4.5a7 7 0 1 0 4 12.2A7.5 7.5 0 0 1 15.5 4.5z" />
    </svg>
  );
}

export function LinkIcon(props: IconProps) {
  return (
    <svg {...base(props)}>
      <path d="M10 13.5a4 4 0 0 0 5.7.4l2.2-2.2a4 4 0 0 0-5.7-5.6L11 7.3" />
      <path d="M14 10.5a4 4 0 0 0-5.7-.4L6.1 12.3a4 4 0 0 0 5.7 5.6L13 16.7" />
    </svg>
  );
}

export function CheckIcon(props: IconProps) {
  return (
    <svg {...base(props)}>
      <path d="m5 12.5 4.2 4.2L19 7.5" />
    </svg>
  );
}

export function InstagramIcon(props: IconProps) {
  return (
    <svg {...base(props)}>
      <rect x="4" y="4" width="16" height="16" rx="4.5" />
      <circle cx="12" cy="12" r="3.4" />
      <circle cx="16.6" cy="7.4" r="0.7" fill="currentColor" stroke="none" />
    </svg>
  );
}

export function TelegramIcon(props: IconProps) {
  return (
    <svg {...base({ ...props, fill: "currentColor", stroke: "none" })}>
      <path d="M20.2 5.3 3.7 11.5c-1.1.4-1.1 1.1-.2 1.4l4.2 1.3 9.8-6.2c.5-.3.9-.1.5.2l-7.9 7.1-.3 4.2c.4 0 .6-.2.9-.4l2.2-2.1 4.5 3.3c.8.5 1.4.2 1.6-.8l2.8-13.4c.3-1.2-.4-1.7-1.6-1.2z" />
    </svg>
  );
}

export function YouTubeIcon(props: IconProps) {
  return (
    <svg {...base(props)}>
      <rect x="3" y="7" width="18" height="10.5" rx="3" />
      <path d="m11 10.2 4 2.1-4 2.1z" fill="currentColor" stroke="none" />
    </svg>
  );
}

export function PinIcon(props: IconProps) {
  return (
    <svg {...base(props)}>
      <path d="M12 20.5s5.5-4.8 5.5-9.2a5.5 5.5 0 1 0-11 0c0 4.4 5.5 9.2 5.5 9.2z" />
      <circle cx="12" cy="11.2" r="1.7" />
    </svg>
  );
}

export function ListIcon(props: IconProps) {
  return (
    <svg {...base(props)}>
      <path d="M9 7.5h10M9 12h10M9 16.5h10" />
      <path d="M5.5 7.5h.01M5.5 12h.01M5.5 16.5h.01" />
    </svg>
  );
}

export function VkIcon(props: IconProps) {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" {...props}>
      <path
        fill="currentColor"
        d="M4.2 7.4h2.3c.1 3.3 1.5 5.2 2.7 6.1V7.4h2.2v3.5c1.1-.1 2.3-1.6 2.7-3.5h2.2c-.3 1.5-1.3 3-2.3 3.9 1 .8 2.2 2.3 2.7 4.3h-2.4c-.4-1.3-1.4-2.6-2.9-3v3h-.2c-4.7 0-7.4-3.2-7.5-8.7z"
      />
    </svg>
  );
}

export function MaxIcon(props: IconProps) {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" {...props}>
      <text
        x="12"
        y="16"
        textAnchor="middle"
        fontSize="8"
        fontFamily="Outfit, sans-serif"
        fontWeight="600"
        fill="currentColor"
      >
        MAX
      </text>
    </svg>
  );
}

const linkIcons = {
  camera: CameraIcon,
  book: BookIcon,
  calendar: CalendarIcon,
  image: ImageIcon,
  mail: MailIcon,
  pin: PinIcon,
  list: ListIcon,
} as const;

export function LinkGlyph({ name }: { name: keyof typeof linkIcons }) {
  const Icon = linkIcons[name];
  return <Icon className="size-5" />;
}

const socialIcons = {
  instagram: InstagramIcon,
  telegram: TelegramIcon,
  youtube: YouTubeIcon,
  mail: MailIcon,
  vk: VkIcon,
  max: MaxIcon,
} as const;

export function SocialGlyph({
  name,
}: {
  name: keyof typeof socialIcons;
}) {
  const Icon = socialIcons[name];
  return <Icon className="size-5" />;
}
