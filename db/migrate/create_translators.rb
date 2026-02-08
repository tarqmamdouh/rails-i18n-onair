class CreateTranslators < ActiveRecord::Migration[6.0]
  def change
    create_table :translators do |t|
      t.string :username, null: false
      t.string :password_digest, null: false

      t.timestamps
    end

    add_index :translators, :username, unique: true
  end
end
