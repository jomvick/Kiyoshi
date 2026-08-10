type Props = {
  size?: number;
  className?: string;
};

/**
 * The three-petal mark from BotanicalLogoPainter (lib/src/shared/widgets/botanical_logo.dart),
 * ported to SVG at the same path coordinates so the wordmark stays identical to the app icon.
 */
export function BotanicalLogo({ size = 40, className }: Props) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 100 100"
      fill="currentColor"
      className={className}
      aria-hidden="true"
    >
      <path d="M50 15 C64 40 62 70 50 78 C38 70 36 40 50 15 Z" />
      <path d="M44 78 C28 72 18 60 15 45 C26 52 36 64 44 78 Z" />
      <path d="M56 78 C72 72 82 60 85 45 C74 52 64 64 56 78 Z" />
    </svg>
  );
}
