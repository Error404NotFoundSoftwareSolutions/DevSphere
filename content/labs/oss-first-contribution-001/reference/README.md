# pyslug

Tiny helpers for turning text into URL slugs and short previews.

## Install

```
pip install pyslug
```

## Usage

```python
from pyslug import slugify, truncate_words

slugify("Hello, World!")  # 'hello-world'
truncate_words("one two three four", 2)  # 'one two...'
```

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) before you open a pull request.

## License

MIT
