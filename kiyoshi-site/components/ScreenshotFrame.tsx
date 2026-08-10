import Image from "next/image";

type Props = {
  src: string;
  alt: string;
  priority?: boolean;
  className?: string;
};

/**
 * Frames a real app screenshot (already includes the window's own title bar)
 * in the same glass treatment used across the rest of the site — rounded
 * corners + soft ambient shadow, no extra chrome needed.
 */
export function ScreenshotFrame({ src, alt, priority, className }: Props) {
  return (
    <div className={`glass overflow-hidden rounded-2xl ${className ?? ""}`}>
      <Image
        src={src}
        alt={alt}
        width={1920}
        height={1020}
        priority={priority}
        className="h-auto w-full"
      />
    </div>
  );
}
