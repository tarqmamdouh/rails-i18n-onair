class CreateTranslators < ActiveRecord::Migration[6.0]
  def change
    create_table :rails_i18n_onair_translators do |t|
      t.string :username, null: false
      t.string :password_digest, null: false

      t.timestamps
    end

    add_index :rails_i18n_onair_translators, :username, unique: true
  end
end
