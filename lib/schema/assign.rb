# frozen_string_literal: true

module Schema
  # Schema::Assign adds schema assignment methods to a class
  module Assign
    def self.update_model(schema:, model:, include_filter: nil, exclude_filter: nil)
      schema.class.each_attribute do |field_name, field_options|
        if field_options[:association]
          update_association(
            schema: schema,
            model: model,
            field_name: field_name,
            field_options: field_options,
            include_filter: include_filter,
            exclude_filter: exclude_filter
          )
          next
        end

        value = schema.public_send(field_options[:getter])

        next if include_filter && !include_filter.call(schema, model, field_name, value, field_options)
        next if exclude_filter && exclude_filter.call(schema, model, field_name, value, field_options)

        model.public_send(field_options[:setter], value)
      end
    end

    def self.update_association(schema:, model:, field_name:, field_options:, include_filter: nil, exclude_filter: nil)
      if field_options[:type] == :has_one
        update_has_one_association(
            schema: schema,
            model: model,
            field_name: field_name,
            field_options: field_options,
            include_filter: include_filter,
            exclude_filter: exclude_filter
        )
      elsif field_options[:type] == :has_many
        update_has_many_association(
            schema: schema,
            model: model,
            field_name: field_name,
            field_options: field_options,
            include_filter: include_filter,
            exclude_filter: exclude_filter
        )
      else
        raise UnknownAssociationTypeException.new("unhandled association type #{field_options[:type]}")
      end
    end

    def self.update_has_one_association(schema:, model:, field_name:, field_options:, include_filter: nil, exclude_filter: nil)
      schema_association = schema.public_send(field_options[:getter])
      return unless schema_association

      model_association = model.public_send(field_options[:getter]) || model.public_send("build_#{field_options[:getter]}")
      update_model(
        schema: schema_association,
        model: model_association,
        include_filter: include_filter,
        exclude_filter: exclude_filter
      )
    end

    def self.update_has_many_association(schema:, model:, field_name:, field_options:, include_filter: nil, exclude_filter: nil)
      schema_associations = schema.public_send(field_options[:getter])
      return unless schema_associations

      model_associations = model.public_send(field_options[:getter])

      get_model_association = proc do |schema_association|
        model_associations.detect { |model_association| model_association.id == schema_association.id } ||
          model_associations.new
      end

      schema_associations.each do |schema_association|
        model_association = get_model_association.call(schema_association)

        update_model(
          schema: schema_association,
          model: model_association,
          include_filter: include_filter,
          exclude_filter: exclude_filter
        )
      end
    end

    def self.was_set_filter
      proc do |schema, model, field_name, value, field_options|
        schema.public_send(field_options[:was_set])
      end
    end
  end
end
