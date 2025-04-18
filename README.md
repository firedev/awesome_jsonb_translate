# Awesome JSONB Translate

This gem uses PostgreSQL's JSONB datatype and ActiveRecord models to translate model data. In memory of
- [`hstore_translate`](https://github.com/Leadformance/hstore_translate)
- [`json_translate`](https://github.com/cfabianski/json_translate)
- [`awesome_hstore_translate`](https://github.com/openscript/awesome_hstore_translate).

- No extra columns or tables needed to operate
- Clean naming in the database model
- Everything is well tested
- Uses modern JSONB type for better performance and flexibility
- Falls back to default locale

## Features

- [x] `v0.1.0` Attributes override / Raw attributes

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
p = Page.new(title { en: 'English title', de: 'Deutscher Titel'})
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

# Behavior with empty string
p = Page.new(title_en: 'English title', title_de: '')
I18n.with_locale(:de) { p.title } # => 'English title' (falls back since German is empty)
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

### Ordering Records

```ruby
# Sort by translated field in current locale
Page.order("title->>'en' ASC")
```

### Other Useful Methods

```ruby
# List translated attributes
Page.translated_attribute_names # => [:title, :content]

# List all accessor methods
Page.translated_accessor_names # => [:title_en, :title_de, :content_en, :content_de]

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
class Page < ApplicationRecord
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
p = Page.new(title: {en: 'English title', de: 'Deutscher Titel')

p.title_raw # => {'en' => 'English title', 'de' => 'Deutscher Titel'}
```

### Find

`awesome_jsonb_translate` created a `find_by` helper.

```ruby
Page.create!(:title_en => 'English title', :title_de => 'Deutscher Titel')
Page.create!(:title_en => 'Another English title', :title_de => 'Noch ein Deutscher Titel')

Page.find_by(title: 'English title')  # => Find by a specific language
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
Page.where(title: 'Titre français').first_or_create!
```

A workaround is:

```ruby
Page.find_by(title_en: 'Titre français').first_or_create!(title_en: 'Titre français')
```
