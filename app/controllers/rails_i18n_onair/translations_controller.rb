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
      @parsed_data = @translation.translation || {}
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
      @parsed_data = @translation.translation || {}
    end

    def update
      # Convert nested form params back to hash
      new_translation_data = reconstruct_hash_from_params(params[:translations] || {})

      if new_translation_data.empty?
        flash.now[:alert] = "No translation data received. Please ensure all fields are filled."
        @parsed_data = @translation.translation || {}
        render :edit, status: :unprocessable_entity
        return
      end

      if @translation.update(translation: new_translation_data)
        # Invalidate only the updated locale's cache
        reload_backend_locale(@translation.language)

        redirect_to translation_path(@translation), notice: "Translation updated successfully"
      else
        flash.now[:alert] = "Failed to update translation"
        @parsed_data = new_translation_data
        render :edit, status: :unprocessable_entity
      end
    rescue StandardError => e
      flash.now[:alert] = "Error processing translations: #{e.message}"
      @parsed_data = @translation.translation || {}
      render :edit, status: :unprocessable_entity
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
          parsed = parse_translation_input(whitelisted[:translation_data])
          language = whitelisted[:language]

          # Wrap with language key if not already present (to match YAML file structure)
          if language.present? && parsed.is_a?(Hash) && !parsed.key?(language)
            whitelisted[:translation] = { language => parsed }
          else
            whitelisted[:translation] = parsed
          end

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

    def reconstruct_hash_from_params(params_hash)
      result = {}

      params_hash.each do |key, value|
        if value.is_a?(ActionController::Parameters) || value.is_a?(Hash)
          result[key] = reconstruct_hash_from_params(value)
        else
          result[key] = value
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
