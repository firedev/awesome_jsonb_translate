# Awesome JSONB Translate [![Gem Version](https://badge.fury.io/rb/awesome_jsonb_translate.svg)](https://badge.fury.io/rb/awesome_jsonb_translate)

This gem uses PostgreSQL's JSONB datatype and ActiveRecord models to translate model data.

- No extra columns or tables needed to operate
- Clean naming in the database model
- Everything is well tested
- Uses modern JSONB type for better performance and flexibility
- Falls back to default locale

## Features

- [x] `v0.2.0` Support for raw JSONB syntax in find_by queries
- [x] `v0.1.3` Fix redundant fallbacks when translation is nil

## Requirements

- I18n
- PostgreSQL with JSONB support (9.4+)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'awesome_jsonb_translate'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install awesome_jsonb_translate

## Usage

Include `AwesomeJsonbTranslate` in your model class.

Use `translates` in your models, to define the attributes, which should be translateable:


```rb
class Model < ApplicationRecord
  include AwesomeJsonbTranslate
  translates :title, :description
end
```

---

## Examples of Supported Usage

### Assigning and Retrieving Translations

```ruby
p = Page.new(title_en: 'English title', title_de: 'Deutscher Titel')
p = Page.new(title: { en: 'English title', de: 'Deutscher Titel'})
p.title_en # => 'English title'
p.title_de # => 'Deutscher Titel'

I18n.with_locale(:en) { p.title } # => 'English title'
I18n.with_locale(:de) { p.title } # => 'Deutscher Titel'
```

### Fallbacks

It always falls back to default locale

```ruby
# Behavior with fallbacks enabled
p = Page.new(title_en: 'English title')
I18n.with_locale(:de) { p.title } # => 'English title' (falls back to English)
p.title_de # => nil

# Behavior with empty string
p = Page.new(title_en: 'English title', title_de: '')
I18n.with_locale(:de) { p.title } # => 'English title' (falls back since German is empty)
p.title_de # => ''
```

### Assigning a Hash Directly

```ruby
p = Page.new(title: { en: 'English title', de: 'Deutscher Titel' })
p.title_raw # => { 'en' => 'English title', 'de' => 'Deutscher Titel' }
```

### Locale Accessors

```ruby
p.title_en = 'Updated English title'
p.title_de = 'Aktualisierter Deutscher Titel'
```

### Querying by Translated Value (JSONB-aware)

**Hash-based queries (recommended for most use cases):**

```ruby
# Find records by current locale value
Page.find_by(title_en: 'English title')

# which transforms to
Page.where("title->>'en' = ?", 'English title') # queries current locale

# Use with other conditions
Page.find_by(title_en: 'English title', author: 'John')

# which transforms to
Page.where("title->>'en' = ?", 'English title').where(author: 'John')
```

**Raw JSONB syntax queries (for advanced use cases):**

You can also use raw PostgreSQL JSONB syntax directly with `find_by`:

```ruby
# Direct JSONB query syntax
Page.find_by("title->>'en' = ?", 'English title')

# Complex JSONB queries with operators
Page.find_by("title->>'en' ILIKE ?", '%title%')

# Case-insensitive search
Page.find_by("LOWER(title->>'en') = ?", 'english title')
```

**Important:** Raw SQL string syntax is only supported with `find_by`. The methods `find_or_initialize_by` and `find_or_create_by` require hash-based syntax because they need to know which attributes to set when creating/initializing new records.

For these methods, use hash syntax with translated accessors:
```ruby
# Correct - uses hash syntax
Page.find_or_initialize_by(title_en: 'English title')
Page.find_or_create_by(title_de: 'Deutscher Titel')

# Incorrect - string syntax not supported
# Page.find_or_create_by("title->>'en' = ?", 'English title')  # Will not work
```

When using raw JSONB syntax with `find_by`, the gem delegates to ActiveRecord's native query methods, giving you full access to PostgreSQL's JSONB operators and functions.

### Finding or Initializing Records

```ruby
# Find existing record by translated attribute
Page.find_or_initialize_by(title_en: 'English title')

# Initialize new record if not found
new_page = Page.find_or_initialize_by(title_en: 'New Page', slug: 'new')
new_page.persisted? # => false

# Find with combined attributes
Page.find_or_initialize_by(title_en: 'English title', slug: 'english-title')

# Find or create records
existing = Page.find_or_create_by(title_en: 'English title')
new_record = Page.find_or_create_by(title_en: 'Brand New', slug: 'brand-new') # Creates and saves the record
```

### Ordering Records

```ruby
# Sort by translated field in current locale
Page.order("title->>'en' ASC")
```

### Other Useful Methods

```ruby
# List translated attributes
Page.translated_attributes # => [:title, :content]

# List all accessor methods
Page.translated_accessors # => [:title_en, :title_de, :content_en, :content_de]

# Check translation presence
page.translated?(:title) # => true
page.translated?(:title, :fr) # => false

# Check translation availability
page.translation_available?(:title, :en) # => true

# Get all locales that have a translation
page.available_translations(:title) # => ["en", "de"]

# Get all available locales for the record
page.available_locales # => [:en, :de]
```

---

```ruby
class Page < ActiveRecord::Base
  include AwesomeJsonbTranslate
  translates :title, :content
end
```

Make sure that the datatype of this columns is `jsonb`:

```ruby
class CreatePages < ActiveRecord::Migration
  def change
    create_table :pages do |t|
      t.column :title, :jsonb
      t.column :content, :jsonb
      t.timestamps
    end
  end
end
```

Use the model attributes per locale:

```ruby
p = Page.create(title_en: "English title", title_de: "Deutscher Titel")

I18n.locale = :en
p.title # => English title

I18n.locale = :de
p.title # => Deutscher Titel

I18n.with_locale :en do
  p.title # => English title
end
```

The raw data is available via the suffix `_raw`:

```ruby
p = Page.new(title: {en: 'English title', de: 'Deutscher Titel'})

p.title_raw # => {'en' => 'English title', 'de' => 'Deutscher Titel'}
```

### Find

`awesome_jsonb_translate` created a `find_by` helper.

```ruby
Page.create!(:title_en => 'English title', :title_de => 'Deutscher Titel')
Page.create!(:title_en => 'Another English title', :title_de => 'Noch ein Deutscher Titel')

Page.find_by(title_en: 'English title')  # => Find by a specific language
```

### To Param

For generating URLs with translated slugs:

```ruby
class Page < ActiveRecord::Base
  translates :title

  def to_param
    # Or use parameterize for URL-friendly slugs
    title_en.parameterize
  end
end
```

### Limitations

`awesome_jsonb_translate` patches ActiveRecord, which create the limitation, that a with `where` chained `first_or_create` and `first_or_create!` **doesn't work** as expected.
Here is an example, which **won't** work:

```ruby
Page.where(title_en: 'Titre français').first_or_create!
```

A workaround is:

```ruby
Page.find_or_create_by(title_en: 'Titre français')
```

## Development

```
bundle
bin/setup
bundle exec rspec
```

## Testing

To run the tests:

1. Ensure PostgreSQL is installed and running
2. Set up the test environment:

```bash
bin/setup
```

This script will:
- Install required gem dependencies
- Create the PostgreSQL test database if it doesn't exist

3. Run the tests:

```bash
bundle exec rspec
```

You can also set custom database connection details with environment variables:

```bash
DB_NAME=custom_db_name DB_USER=your_username DB_PASSWORD=your_password bundle exec rspec
```

## Troubleshooting

If you encounter issues running tests:

1. Make sure PostgreSQL is installed and running
2. Ensure the user has permissions to create databases
3. Check that the database 'awesome_jsonb_translate_test' exists or can be created
4. Run `bin/setup` to prepare the test environment
5. For more detailed database errors, run with debug flag:
   ```bash
   DB_DEBUG=true bundle exec rspec
   ```
