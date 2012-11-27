include_recipe "apache2"
include_recipe "apache2::mod_php5"

if node["wordpress"]["databag"]
  databag = Chef::EncryptedDataBagItem.load(node["wordpress"]["databag"], "wordpress")
  node.set_unless['apache']['ssl']['cert'] = databag['apache']['ssl_cert'] rescue nil
  node.set_unless['apache']['ssl']['key'] = databag['apache']['ssl_private_key'] rescue nil
end

if (node['apache']['ssl']['cert'] and node['apache']['ssl']['key'] rescue false)
  case node.platform
    when "ubuntu", "debian"
      file "/etc/ssl/certs/#{node['wordpress']['domain_name']}.crt" do
        content node['apache']['ssl']['cert']
        owner "root"
        group "root"
        mode "0644"
        action :create
      end
      file "/etc/ssl/private/#{node['wordpress']['domain_name']}.key" do
        content node['apache']['ssl']['key']
        owner "root"
        group "root"
        mode "0600"
        action :create
      end
    else
      file "/etc/pki/tls/certs/#{node['wordpress']['domain_name']}.crt" do
        content node['apache']['ssl']['cert']
        owner "root"
        group "root"
        mode "0644"
        action :create
      end
      file "/etc/pki/tls/private/#{node['wordpress']['domain_name']}.key" do
        content node['apache']['ssl']['key']
        owner "root"
        group "root"
        mode "0600"
        action :create
      end
  end
end

case node.platform
  when "ubuntu", "debian"
    apache_site "000-default" do
      enable false
    end
end  

web_app "wordpress" do
  template "wordpress.conf.erb"
  docroot "#{node['wordpress']['dir']}"
  server_name node['wordpress']['domain_name']
  server_aliases node['wordpress']['server_aliases']
  listen_ports node['apache']['listen_ports']
  sslcert "#{node['apache']['ssl']['certpath']}/#{node['wordpress']['domain_name']}.crt" if (node['apache']['ssl']['cert'] rescue false)
  sslkey "#{node['apache']['ssl']['keypath']}/#{node['wordpress']['domain_name']}.key" if (node['apache']['ssl']['key'] rescue false)
end