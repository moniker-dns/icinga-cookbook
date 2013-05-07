%w{ icinga }.each do |pkg|
  package pkg
end

%w{ icinga cgi }.each do |conf|
  icinga_conf conf do
    template_subdir 'package'
    config_subdir false
  end
end

%w{ resource }.each do |conf|
  icinga_conf conf do
    config_subdir false
  end
end

%w{ templates timeperiods }.each do |conf|
  icinga_conf conf do
    config_subdir false
  end
end

template "#{node['icinga']['conf_dir']}/apache2.conf" do
  source "package/apache2.conf.erb"
  mode 0644
  if ::File.symlink?("#{node['apache']['dir']}/conf.d/icinga.conf")
    notifies :reload, "service[apache2]"
  end
end
