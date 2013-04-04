define :icinga_conf, :variables => {}, :config_subdir => true do
  conf_dir = params[:config_subdir] ? node['icinga']['config_dir'] : node['icinga']['conf_dir']
  template_source = "#{params[:name]}.cfg.erb"
  template_source = "#{params[:template_subdir]}/#{template_source}" if params[:template_subdir]
  template "#{conf_dir}/#{params[:name]}.cfg" do
    owner "#{node['icinga']['user']}"
    group "#{node['icinga']['group']}"
    source "#{template_source}"
    mode 0644
    variables params[:variables]
    notifies :restart, "service[icinga]"
    backup 0
  end
end
