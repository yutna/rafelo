import { isSafeUrl } from "./safe_url";

type ImageProps = {
  src: string;
  alt: string;
  className?: string;
};

export function Image({ src, alt, className }: ImageProps) {
  return isSafeUrl(src) ? <img src={src} alt={alt} className={className} /> : null;
}
