# frozen_string_literal: true

module AwesomeJsonbTranslate
  module ActiveRecord
    def translates(*attrs)
      include InstanceMethods

      class_attribute :translated_attributes, :translated_accessors, :translation_options
      self.translated_attributes = attrs.map(&:to_sym)
      self.translated_accessors = translated_attributes.flat_map do |attr_name|
        I18n.available_locales.map do |locale|
          ["#{attr_name}_#{locale}", "#{attr_name}_#{locale}="]
        end
      end.flatten.map(&:to_sym)
      self.translation_options = {}

      attrs.each do |attr_name|
        define_translation_accessors(attr_name)
        define_translation_writer(attr_name)
        define_translation_reader(attr_name)
        define_raw_accessor(attr_name)
      end

      extend FindByMethods
    end

    def define_translation_accessors(attr_name)
      I18n.available_locales.each do |locale|
        define_translation_reader_for_locale(attr_name, locale)
        define_translation_writer_for_locale(attr_name, locale)
      end
    end

    def define_translation_reader_for_locale(attr_name, locale)
      define_method("#{attr_name}_#{locale}") do
        read_translation(attr_name, locale)
      end
    end

    def define_translation_writer_for_locale(attr_name, locale)
      define_method("#{attr_name}_#{locale}=") do |value|
        write_translation(attr_name, locale, value)
      end
    end

    def define_translation_reader(attr_name)
      define_method(attr_name) do
        read_translation(attr_name, I18n.locale)
      end
    end

    def define_translation_writer(attr_name)
      define_method("#{attr_name}=") do |value|
        normalized_value = value.is_a?(Hash) ? value.stringify_keys : { I18n.locale.to_s => value }
        write_attribute(attr_name, (send("#{attr_name}_raw") || {}).merge(normalized_value))
      end
    end

    def define_raw_accessor(attr_name)
      define_method("#{attr_name}_raw") do
        raw_value = read_attribute(attr_name)
        raw_value.is_a?(Hash) ? raw_value : {}
      end
    end

    module InstanceMethods
      def translated?(attr_name, locale = I18n.locale)
        value = read_translation_without_fallback(attr_name, locale)
        translation_available?(attr_name, locale) && value.present?
      end

      def translation_available?(attr_name, locale = I18n.locale)
        self.class.translated_attributes.include?(attr_name.to_sym) &&
          send("#{attr_name}_raw").key?(locale.to_s)
      end

      def available_translations(attr_name)
        return [] unless self.class.translated_attributes.include?(attr_name.to_sym)

        send("#{attr_name}_raw").keys
      end

      def available_locales
        locales = self.class.translated_attributes.flat_map do |attr_name|
          available_translations(attr_name)
        end.uniq
        locales.map(&:to_sym)
      end

      def read_translation(attr_name, locale)
        translations = send("#{attr_name}_raw")
        value = translations[locale.to_s]

        if value.blank? && locale != I18n.default_locale
          translations[I18n.default_locale.to_s]
        else
          value
        end
      end

      def read_translation_without_fallback(attr_name, locale)
        translations = send("#{attr_name}_raw")
        translations[locale.to_s]
      end

      def write_translation(attr_name, locale, value)
        translations = send("#{attr_name}_raw").dup
        translations[locale.to_s] = value
        write_attribute(attr_name, translations)
      end
    end

    module FindByMethods
      # Override find_by to handle translated attributes
      def find_by(attributes)
        # Check if any of the keys represent translated attributes
        has_translated_attrs = attributes.keys.any? do |key|
          translated_accessors.include?(key.to_sym)
        end

        # If no translated attributes, use default implementation
        return super unless has_translated_attrs

        translated_attrs = {}
        regular_attrs = {}

        attributes.each do |key, value|
          key_s = key.to_s
          if key_s.include?('_') && !key_s.end_with?('=')
            parts = key_s.split('_')
            locale = parts.last
            attr_name = parts[0..-2].join('_')

            if translated_attributes.include?(attr_name.to_sym)
              translated_attrs[attr_name] ||= {}
              translated_attrs[attr_name][locale] = value
            else
              regular_attrs[key] = value
            end
          else
            regular_attrs[key] = value
          end
        end

        scope = where(regular_attrs)

        translated_attrs.each do |attr_name, locales|
          locales.each do |locale, value|
            scope = scope.where("#{attr_name}->>'#{locale}' = ?", value)
          end
        end

        scope.first
      end

      # Override find_or_initialize_by to handle translated attributes
      def find_or_initialize_by(attributes)
        result = find_by(attributes)
        return result if result

        # If no record found, initialize with the given attributes
        new_record = new
        new_record.assign_attributes(attributes)
        new_record
      end

      # Override find_or_create_by to handle translated attributes
      def find_or_create_by(attributes)
        result = find_by(attributes)
        return result if result

        # If no record found, create with the given attributes
        create(attributes)
      end
    end
  end
end

ActiveRecord::Base.extend AwesomeJsonbTranslate::ActiveRecord
