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


%w{ extinfo templates timeperiods}.each do |conf|
  icinga_conf conf
end

