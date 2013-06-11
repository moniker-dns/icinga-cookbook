describe 'icinga::server' do
  include MiniTest::Chef::Assertions
  include MiniTest::Chef::Context
  include MiniTest::Chef::Resources

  it 'installs the icinga package' do
    package("icinga").must_be_installed
  end

  it 'enables the icinga service' do
    service("icinga").must_be_enabled
  end

  it 'starts the icinga service' do
    service("icinga").must_be_running
  end
end
