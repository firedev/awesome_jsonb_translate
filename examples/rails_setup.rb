# frozen_string_literal: true

# In your Gemfile
gem 'awesome_jsonb_translate'

# In your migration
class CreatePages < ActiveRecord::Migration[6.1]
  def change
    create_table :pages do |t|
      t.jsonb :title
      t.jsonb :content
      t.string :slug

      t.timestamps
    end

    # Optional: Add indexes for better performance when querying by translations
    add_index :pages, "title->>'en'", using: :btree
    add_index :pages, "content->>'en'", using: :btree
  end
end

# In your model
class Page < ApplicationRecord
  include AwesomeJsonbTranslate
  translates :title, :content

  # Optional: Use slug as to_param for SEO-friendly URLs
  def to_param
    slug
  end
end

# In your controller
class PagesController < ApplicationController
  def index
    @pages = Page.all
  end

  def show
    @page = Page.find_by(slug: params[:id])
  end

  def create
    @page = Page.new(page_params)

    if @page.save
      redirect_to @page, notice: 'Page was successfully created.'
    else
      render :new
    end
  end

  private

  def page_params
    params.require(:page).permit(
      :slug,
      :title_en, :title_de,
      :content_en, :content_de
    )
  end
end

__END__
# In your view (app/views/pages/_form.html.erb)
<%= form_with(model: page) do |form| %>
  <div class="field">
    <%= form.label :slug %>
    <%= form.text_field :slug %>
  </div>

  <div class="field">
    <%= form.label :title_en, "English title" %>
    <%= form.text_field :title_en %>
  </div>

  <div class="field">
    <%= form.label :title_de, "German title" %>
    <%= form.text_field :title_de %>
  </div>

  <div class="field">
    <%= form.label :content_en, "English content" %>
    <%= form.text_area :content_en %>
  </div>

  <div class="field">
    <%= form.label :content_de, "German content" %>
    <%= form.text_area :content_de %>
  </div>

  <div class="actions">
    <%= form.submit %>
  </div>
<% end %>

# In your view (app/views/pages/show.html.erb)
<h1><%= @page.title %></h1>
<div><%= @page.content %></div>

<div>
  Available in:
  <% @page.available_translations(:title).each do |locale| %>
    <%= link_to locale, url_for(locale: locale) if @page.translated?(:title, locale) %>
  <% end %>
</div>

