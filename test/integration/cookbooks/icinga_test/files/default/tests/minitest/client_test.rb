
describe 'icinga::client' do
  include MiniTest::Chef::Assertions
  include MiniTest::Chef::Context
  include MiniTest::Chef::Resources

  it 'installs the nagios-nrpe-server package' do
    package("nagios-nrpe-server").must_be_installed
  end

  it 'enables the nagios-nrpe-server service' do
    service("nagios-nrpe-server").must_be_enabled
  end

  # it 'starts the nagios-nrpe-server service' do
  #   service("nagios-nrpe-server").must_be_running
  # end
end
