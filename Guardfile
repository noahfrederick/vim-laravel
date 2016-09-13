guard 'rake', :task => 'test' do
  watch(%r{^(autoload|plugin|t)/.*\.vim$})
end

guard 'rake', :task => 'doc' do
  watch(%r{^(autoload|plugin)/.*\.vim$})
  watch(%r{^addon-info\.json$})
end
