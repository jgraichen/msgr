# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'rspec' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})          { |m| "spec/#{m[1]}_spec.rb" }

  watch('spec/spec_helper.rb')       { 'spec' }
  watch(%r{^spec/support/(.+)\.rb$}) { 'spec' }
end

guard 'yard' do
  watch(%r{lib/.+\.rb})
end
