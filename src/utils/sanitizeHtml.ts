import DOMPurify from 'dompurify';

const RICH_TEXT_CONFIG = {
  ALLOWED_TAGS: [
    'a', 'b', 'blockquote', 'br', 'code', 'del', 'em', 'h1', 'h2', 'h3', 'h4',
    'hr', 'i', 'img', 'li', 'ol', 'p', 'pre', 's', 'strong', 'table', 'tbody',
    'td', 'tfoot', 'th', 'thead', 'tr', 'u', 'ul', 'iframe',
  ],
  ALLOWED_ATTR: [
    'alt', 'class', 'colspan', 'height', 'href', 'loading', 'rel', 'rowspan',
    'src', 'target', 'title', 'width', 'allow', 'allowfullscreen', 'frameborder',
    'referrerpolicy',
  ],
  ALLOW_DATA_ATTR: false,
};

DOMPurify.addHook('uponSanitizeAttribute', (node, data) => {
  if (node.nodeName.toLowerCase() !== 'iframe' || data.attrName.toLowerCase() !== 'src') return;
  try {
    const source = new URL(data.attrValue, window.location.origin);
    const allowedHosts = ['www.youtube.com', 'youtube.com', 'www.youtube-nocookie.com', 'youtube-nocookie.com', 'player.vimeo.com'];
    if (source.protocol !== 'https:' || !allowedHosts.includes(source.hostname.toLowerCase())) {
      data.keepAttr = false;
    }
  } catch {
    data.keepAttr = false;
  }
});

/** Sanitize admin-authored rich text before rendering it as HTML. */
export function sanitizeHtml(value: unknown): string {
  if (typeof value !== 'string' || value.length === 0) return '';
  return DOMPurify.sanitize(value, RICH_TEXT_CONFIG);
}
