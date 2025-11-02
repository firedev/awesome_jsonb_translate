# Changelog

## [0.2.0] - 2025-11-02

- **Breaking Change**: `find_by`, `find_or_initialize_by`, and `find_or_create_by` now support raw SQL string queries
- Added support for raw PostgreSQL JSONB syntax in `find_by` method
- String-based queries (e.g., `find_by("title->>'en' = ?", 'value')`) now work correctly
- Fixed bug where `find_by` would crash when called with string arguments instead of hashes
- Added comprehensive tests for raw JSONB query syntax
- Updated documentation with examples of both hash-based and string-based queries
- Improved RuboCop configuration and code quality
- Added module documentation comments
- Added required_ruby_version to gemspec (>= 2.7.0)

## [0.1.3] - 2025-04-20

- Fixed redundant fallbacks when translation is nil

## [0.1.0] - 2025-04-20

- Initial release
- Support for translating ActiveRecord model attributes using PostgreSQL's JSONB datatype
- Locale-specific accessor methods for translated attributes
- Fallback to default locale
- Methods for checking translation availability and presence
- Support for querying by translated attributes

## [0.1.1] - 2025-04-20
- Updated gemspec for better compatibility

## [0.1.2] - 2025-04-20
- Updated homepage in gemspec
