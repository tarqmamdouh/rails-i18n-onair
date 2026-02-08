class CreateTranslations < ActiveRecord::Migration[6.0]
  def change
    create_table :translations do |t|
      t.string :language, null: false
      t.jsonb :translation, null: false, default: {}

      t.timestamps
    end

    add_index :translations, :language, unique: true
    add_index :translations, :translation, using: :gin
  end
end
