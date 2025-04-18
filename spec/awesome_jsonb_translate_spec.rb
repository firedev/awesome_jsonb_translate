# frozen_string_literal: true

require 'spec_helper'

# Database connection is set up in spec_helper.rb

class CreatePages < ActiveRecord::Migration[6.1]
  def self.up
    create_table :pages, force: true do |t|
      t.jsonb :title
      t.jsonb :content
      t.string :slug
    end
  end
end

class Page < ActiveRecord::Base
  include AwesomeJsonbTranslate
  translates :title, :content
end

RSpec.describe AwesomeJsonbTranslate do
  before(:all) do
    CreatePages.up unless ActiveRecord::Base.connection.table_exists?(:pages)
  end

  after do
    Page.delete_all
  end

  describe 'accessors' do
    it 'creates getter and setter methods for each locale' do
      page = Page.new

      I18n.available_locales.each do |locale|
        expect(page).to respond_to("title_#{locale}")
        expect(page).to respond_to("title_#{locale}=")
        expect(page).to respond_to("content_#{locale}")
        expect(page).to respond_to("content_#{locale}=")
      end
    end

    it 'allows setting and getting translated attributes' do
      page = Page.new(title_en: 'English title', title_de: 'Deutscher Titel')

      expect(page.title_en).to eq('English title')
      expect(page.title_de).to eq('Deutscher Titel')

      I18n.with_locale(:en) do
        expect(page.title).to eq('English title')
      end

      I18n.with_locale(:de) do
        expect(page.title).to eq('Deutscher Titel')
      end
    end

    it 'allows setting translations as a hash' do
      page = Page.new(title: { en: 'English title', de: 'Deutscher Titel' })

      expect(page.title_en).to eq('English title')
      expect(page.title_de).to eq('Deutscher Titel')
      expect(page.title_raw).to eq({ 'en' => 'English title', 'de' => 'Deutscher Titel' })
    end
  end

  describe 'fallbacks' do
    it 'falls back to default locale' do
      page = Page.new(title_en: 'English title')

      I18n.with_locale(:de) do
        expect(page.title).to eq('English title')
      end
    end

    it 'falls back when translation is an empty string' do
      page = Page.new(title_en: 'English title', title_de: '')

      I18n.with_locale(:de) do
        expect(page.title).to eq('English title')
      end
    end
  end

  describe 'querying' do
    before do
      Page.create!(title_en: 'First page', title_de: 'Erste Seite', slug: 'first')
      Page.create!(title_en: 'Second page', title_de: 'Zweite Seite', slug: 'second')
    end

    it 'can find records by translated attribute' do
      result = Page.find_by(title_en: 'First page')
      expect(result.slug).to eq('first')

      result = Page.find_by(title_de: 'Zweite Seite')
      expect(result.slug).to eq('second')
    end

    it 'can query by translated attributes in combination with regular ones' do
      result = Page.find_by(title_en: 'First page', slug: 'first')
      expect(result).to be_present

      result = Page.find_by(title_en: 'First page', slug: 'second')
      expect(result).to be_nil
    end

    it 'can find_or_initialize_by with translated attributes' do
      # Finding existing record
      result = Page.find_or_initialize_by(title_en: 'First page')
      expect(result.slug).to eq('first')
      expect(result.persisted?).to be true

      # Initializing new record
      result = Page.find_or_initialize_by(title_en: 'New page title', slug: 'new')
      expect(result.title_en).to eq('New page title')
      expect(result.slug).to eq('new')
      expect(result.persisted?).to be false
    end

    it 'can find_or_initialize_by with translated attributes and regular ones' do
      # Finding existing record with combined attributes
      result = Page.find_or_initialize_by(title_en: 'First page', slug: 'first')
      expect(result.slug).to eq('first')
      expect(result.persisted?).to be true

      # Not finding because of mismatched regular attribute
      result = Page.find_or_initialize_by(title_en: 'First page', slug: 'not-found')
      expect(result.title_en).to eq('First page')
      expect(result.slug).to eq('not-found')
      expect(result.persisted?).to be false

      # Not finding because of mismatched translated attribute
      result = Page.find_or_initialize_by(title_en: 'Not found', slug: 'first')
      expect(result.title_en).to eq('Not found')
      expect(result.slug).to eq('first')
      expect(result.persisted?).to be false
    end

    it 'can find_or_create_by with translated attributes' do
      # Finding existing record
      result = Page.find_or_create_by(title_en: 'First page')
      expect(result.slug).to eq('first')
      expect(result.persisted?).to be true

      # Creating new record
      expect do
        result = Page.find_or_create_by(title_en: 'Created page', slug: 'created')
        expect(result.title_en).to eq('Created page')
        expect(result.slug).to eq('created')
        expect(result.persisted?).to be true
      end.to change(Page, :count).by(1)
    end

    it 'can find_or_create_by with translated attributes and regular ones' do
      # Finding existing record with combined attributes
      result = Page.find_or_create_by(title_en: 'First page', slug: 'first')
      expect(result.slug).to eq('first')
      expect(result.persisted?).to be true

      # Creating when not found due to mismatched attributes
      expect do
        result = Page.find_or_create_by(title_en: 'First page', slug: 'first-alt')
        expect(result.title_en).to eq('First page')
        expect(result.slug).to eq('first-alt')
        expect(result.persisted?).to be true
      end.to change(Page, :count).by(1)
    end
  end

  describe 'helper methods' do
    it 'lists translated attribute names' do
      expect(Page.translated_attributes).to match_array(%i[title content])
    end

    it 'lists translated accessor names' do
      expected_accessors = []
      %i[title content].each do |attr|
        I18n.available_locales.each do |locale|
          expected_accessors << :"#{attr}_#{locale}"
          expected_accessors << :"#{attr}_#{locale}="
        end
      end

      expect(Page.translated_accessors).to match_array(expected_accessors)
    end

    it 'checks if a translation is available' do
      page = Page.new(title_en: 'English title')

      expect(page.translation_available?(:title, :en)).to be true
      expect(page.translation_available?(:title, :de)).to be false
    end

    it 'checks if an attribute is translated' do
      page = Page.new(title_en: 'English title', title_de: '')

      expect(page.translated?(:title, :en)).to be true
      expect(page.translated?(:title, :de)).to be false
    end

    it 'lists available translations for an attribute' do
      page = Page.new(title_en: 'English title', title_de: 'Deutscher Titel')

      expect(page.available_translations(:title)).to match_array(%w[en de])
    end

    it 'lists all available locales for a record' do
      page = Page.new(title_en: 'English title', content_de: 'Deutscher Inhalt')

      expect(page.available_locales).to match_array(%i[en de])
    end
  end
end
