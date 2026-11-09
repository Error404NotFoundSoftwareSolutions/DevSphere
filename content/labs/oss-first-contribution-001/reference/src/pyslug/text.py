"""Text helpers used to build URLs and previews."""


def slugify(text: str) -> str:
    """Turn a title into a URL-friendly slug, for example "Hello, World!" -> "hello-world"."""
    out: list[str] = []
    for ch in text.lower():
        if ch.isalnum():
            out.append(ch)
        elif out and out[-1] != "-":
            out.append("-")
    return "".join(out).strip("-")


def truncate_words(text: str, limit: int, suffix: str = "...") -> str:
    """Keep at most `limit` words of `text`. Add `suffix` only when words were removed."""
    if limit < 0:
        raise ValueError("limit must be 0 or more")
    words = text.split()
    if len(words) <= limit:
        return text
    return " ".join(words[:limit]) + suffix
