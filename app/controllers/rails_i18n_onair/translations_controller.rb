module RailsI18nOnair
  class TranslationsController < ApplicationController
    before_action :set_translation, only: [:show, :edit, :update, :destroy]

    def index
      @translations = RailsI18nOnair::Translation.order(:language)

      if params[:search].present?
        @translations = @translations.where("language ILIKE ?", "%#{params[:search]}%")
      end
    end

    def show
      @translation_keys = flatten_hash(@translation.translation)
    end

    def new
      @translation = RailsI18nOnair::Translation.new
    end

    def create
      @translation = RailsI18nOnair::Translation.new(translation_params)

      if @translation.save
        # Invalidate cache for the newly created locale
        reload_backend_locale(@translation.language)

        redirect_to translations_path, notice: "Translation for #{@translation.language} created successfully"
      else
        flash.now[:alert] = "Failed to create translation"
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @translation_json = JSON.pretty_generate(@translation.translation)
    end

    def update
      begin
        # Parse JSON/YAML input
        new_translation_data = parse_translation_input(params[:translation][:translation_data])

        if @translation.update(translation: new_translation_data)
          # Invalidate only the updated locale's cache
          reload_backend_locale(@translation.language)

          redirect_to translation_path(@translation), notice: "Translation updated successfully"
        else
          flash.now[:alert] = "Failed to update translation"
          render :edit, status: :unprocessable_entity
        end
      rescue JSON::ParserError, Psych::SyntaxError => e
        flash.now[:alert] = "Invalid JSON/YAML format: #{e.message}"
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      language = @translation.language

      if @translation.destroy
        # Invalidate cache for the deleted locale
        reload_backend_locale(language)

        redirect_to translations_path, notice: "Translation for #{language} deleted successfully"
      else
        redirect_to translations_path, alert: "Failed to delete translation"
      end
    end

    private

    def set_translation
      @translation = RailsI18nOnair::Translation.find(params[:id])
    end

    def translation_params
      params.require(:translation).permit(:language, :translation_data).tap do |whitelisted|
        if whitelisted[:translation_data].present?
          whitelisted[:translation] = parse_translation_input(whitelisted[:translation_data])
          whitelisted.delete(:translation_data)
        end
      end
    end

    def parse_translation_input(input)
      # Try JSON first
      begin
        JSON.parse(input)
      rescue JSON::ParserError
        # Try YAML if JSON fails
        YAML.safe_load(input, permitted_classes: [Symbol], aliases: true)
      end
    end

    def flatten_hash(hash, parent_key = "", result = {})
      hash.each do |key, value|
        new_key = parent_key.empty? ? key.to_s : "#{parent_key}.#{key}"

        if value.is_a?(Hash)
          flatten_hash(value, new_key, result)
        else
          result[new_key] = value
        end
      end
      result
    end

    def reload_backend_locale(locale)
      # Reload only the specific locale in the I18n backend
      if I18n.backend.respond_to?(:reload!)
        I18n.backend.reload!(locale: locale)
      end
    end
  end
end
