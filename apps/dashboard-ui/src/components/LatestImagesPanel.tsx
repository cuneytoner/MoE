import type { ImageInfo } from "../types";

type Props = {
  images: ImageInfo[];
};

export function LatestImagesPanel({ images }: Props) {
  return (
    <section className="panel">
      <h2>Latest Images</h2>
      <div className="rows">
        {images.map((image) => (
          <div className="row image-row" key={image.path}>
            <div>
              <strong>{image.name}</strong>
              <span>{image.path}</span>
            </div>
            <div className="image-meta">
              <code>{formatBytes(image.size_bytes)}</code>
              <span>{new Date(image.modified).toLocaleString()}</span>
            </div>
          </div>
        ))}
        {images.length === 0 ? <p className="empty">No generated image paths reported yet.</p> : null}
      </div>
    </section>
  );
}

function formatBytes(value: number) {
  if (value < 1024) {
    return `${value} B`;
  }
  if (value < 1024 * 1024) {
    return `${(value / 1024).toFixed(1)} KB`;
  }
  return `${(value / 1024 / 1024).toFixed(1)} MB`;
}
