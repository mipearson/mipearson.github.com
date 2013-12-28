---
layout: post
title: "Live Destructive Database Migrations: Doing the Two Step"
date: 2012-10-08 07:43
comments: true
categories:
---

By "**destructive**", I mean "removes or renames a column in use by the current application". By "**live**", I mean "while your application is in use".

## Original Migration

If Rails' ActiveRecord notices that a table has the columns `created_at` and `updated_at` it will automatically populate or change their values on model creation or modification. Our application doesn't take advantage of this: it uses a hand-rolled `creation_date` field. I'm going to change this column to `created_at` and add an `updated_at` column.

If I were doing this via downtime and maintenance page the migration would look like this:

```ruby
class AddCreatedUpdatedColumns < ActiveRecord::Migration
  def up
    %w{all the tables}.each do |table|
      change_column table, :creation_date, :created_at, :datetime, :null => false
      add_column table, :updated_at, :datetime, :null => false

      connection.execute("UPDATE #{table} SET updated_at = created_at")
    end
  end

  def down
    %w{all the tables}.each do |table|
      change_column table, :created_at, :creation_date, :datetime, :null => false
      drop_column table, :updated_at
    end
  end
end
```

This migration couldn't be run on a live system. Between the time that the schema begins to be changed and the application restarts these errors would occur:

  * ActiveRecord would try to set values on a creation_date column that no longer exists
  * Scopes that have `order(:creation_date)` stanzas would fail to load entirely

## Do the Two-Step

To work around this I'm going to split the above migration and prepare for multiple deployments:

  * My first migration will create new `created_at` and `updated_at` columns and deploy code to use these new columns instead.

  * My second migration will remove the now unused `creation_date` column.

Simple, yeah? I let our running application use the new column name before I remove the old one.

### Our First Migration

```ruby
class AddCreatedUpdatedColums < ActiveRecord::Migration
  def up
    %w{all the tables}.each do |table|
      add_column table, :created_at, :datetime, "DEFAULT now() NOT NULL"
      add_column table, :updated_at, :datetime, "DEFAULT now() NOT NULL"
      change_column table, :creation_date, :datetime, :null => true

      connection.execute("UPDATE #{table} SET created_at = creation_date, updated_at = creation_date")
    end
  end

  def down
    %w{all the tables}.each do |table|
      change_column table, :creation_date, :datetime, :null => false
      drop_column table, :created_at
      drop_column table, :updated_at
    end

  end
end
```

Once I've run `rake db:migrate`  on my development box I'll run a global find and replace all instances of `creation_date` with `created_at`. I'll then run our test suite and commit.

I'll push that out to our test system, play around with some records to make sure that `created_at` and `updated_at` get set properly, and then push it to production.

### Our Second Migration

In the above case the first migration would take up to five minutes to run on our slow fixed HDDs in production. While it was running I created a branch to write our second migration, just in case I needed to fix something in `master` before pushing this new migration.

```ruby
class RemoveCreationDate < ActiveRecord::Migration
  def up
    %w{some tables}.each do |table|
      change_column table, :created_at, :datetime, :null => false
      change_column table, :updated_at, :datetime, :null => false
      remove_column table, :creation_date
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
```

Note the use of `IrreversibleMigration` above. I prefer to flag that a migration can't be reversed this way rather than leave a `down` method that provides a false positive. I will also remove the `DEFAULT now()`: ActiveRecord will always set these values, any other behaviour should be considered an error.

This migration gets pushed to our test system only when the first migration and deploy has successfully run on both our test and production systems and all automated tests have passed.

## Gotchas

The code above has been adapted based on a couple of things that went wrong during pre-production testing:

  * The created columns were set to `:null => true` rather than having intelligent defaults. This gave us some grief after the first migration was run: some code depended on `creation_date` & `created_at` not being nil.
  * I'd forgotten to change `creation_date` to allow nulls in the first migration. This meant that once the new code was deployed records were being saved without a `creation_date`, causing MySQL to return a `column 'creation_date' cannot be NULL` failure.

I also had to modify an existing index and manually re-create a couple of views. Check your `db/schema.rb` diff after you run `rake migrate` on your own machine before pushing.

In our codebase migrations are immutable one they hit pre-production, so they're there for other BikeExchange developers to point and laugh forever (or until the next old-migrations purge).
