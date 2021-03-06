include_recipe 'chef-sugar'

version = node['openfire']['version'].to_s
version_windows = version.tr('.', '_')

case node['platform_family']
when 'rhel', 'suse'
  source_file = "openfire/openfire-#{version}-1.i386.rpm"
  local_package_path = "#{Chef::Config['file_cache_path']}/openfire.rpm"
  platform_checksum = node['openfire']['checksum'][version]['rpm']
when 'debian'
  source_file = "openfire/openfire_#{version}_all.deb"
  local_package_path = "#{Chef::Config['file_cache_path']}/openfire.deb"
  platform_checksum = node['openfire']['checksum'][version]['deb']
when 'windows'
  source_file = "openfire/openfire_#{version_windows}.exe"
  local_package_path = "#{Chef::Config['file_cache_path']}/openfire.exe"
  platform_checksum = node['openfire']['checksum'][version]['exe']
end

remote_file local_package_path do
  checksum platform_checksum
  source "http://www.igniterealtime.org/downloadServlet?filename=#{source_file}"
end

group node['openfire']['group']

user node['openfire']['user'] do
  group node['openfire']['group']
end

cookbook_file '/etc/init.d/openfire' do
  mode '0755'
end

directory node['openfire']['log_dir'] do
  user node['openfire']['user']
  group node['openfire']['group']
  recursive true
end

if ubuntu?
  include_recipe 'apt'
  package 'default-jre-headless'
end

include_recipe 'java' if rhel?

template '/etc/sysconfig/openfire' do
  mode '0644'
  source 'openfire.erb'
  variables(
    user: node['openfire']['user'],
    pid_file: '/var/run/openfire.pid',
    home_dir: node['openfire']['home_dir'],
    log_dir: node['openfire']['log_dir'],
    java_home: node['java']['java_home']
  )
end

package 'openfire' do
  provider Chef::Provider::Package::Dpkg if debian?
  source local_package_path
  notifies :restart, 'service[openfire]', :delayed
end

service 'openfire' do
  action :start
end
