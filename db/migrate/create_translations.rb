class CreateTranslations < ActiveRecord::Migration[6.0]
  def change
    create_table :rails_i18n_onair_translations do |t|
      t.string :language, null: false
      t.json :translation, null: false, default: {}

      t.timestamps
    end

    add_index :rails_i18n_onair_translations, :language, unique: true
  end
end
