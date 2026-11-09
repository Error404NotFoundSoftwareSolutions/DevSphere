"""Text helpers used to build URLs and previews."""


def slugify(text: str) -> str:
    """Turn a title into a URL-friendly slug, for example "Hello, World!" -> "hello-world"."""
    out = []
    for ch in text.lower():
        out.append(ch if ch.isalnum() else "-")
    return "".join(out)


def truncate_words(text: str, limit: int, suffix: str = "...") -> str:
    """Keep at most `limit` words of `text`. Add `suffix` only when words were removed."""
    words = text.split()
    if len(words) <= limit:
        return text
    return " ".join(words[: limit + 1]) + suffix
