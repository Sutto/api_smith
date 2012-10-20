guard 'rspec', version: 2 do
  watch(/^spec\/(.*)_spec\.rb/)
  watch(/^lib\/(.*)\.rb/)         { "spec" }
  watch(/^spec\/spec_helper\.rb/) { "spec" }
  watch(/^spec\/support\/fake_endpoints\.rb/)  { "spec/api_smith/client_spec.rb" }
end
