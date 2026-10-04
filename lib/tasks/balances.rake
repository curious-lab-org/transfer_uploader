# frozen_string_literal: true

namespace :balances do
  # can call via bin/rails "balances:load[./samples/account_balances.csv]"
  desc "Load opening balances from a headerless account_number,balance CSV"
  task :load, [ :path ] => :environment do |_task, args|
    path = args[:path]
    abort 'Usage: bin/rails "balances:load[path/to/account_balances.csv]"' if path.blank?

    created = Imports::InitialBalances.new(path:).call

    puts "Created #{created.size} #{'account'.pluralize(created.size)} from #{path}."
  rescue ImportErrors::InitialBalances::FileNotFoundError => e
    abort "balances:load - file not found: #{e.message}"
  rescue ImportErrors::InitialBalances::EmptyFileError => e
    abort "balances:load - file is empty: #{e.message}"
  rescue ImportErrors::InitialBalances::InvalidFileDataError => e
    abort "balances:load - #{e.row_errors.size} " \
      "#{'invalid row'.pluralize(e.row_errors.size)}, nothing was imported:\n#{e.message}"
  end
end
