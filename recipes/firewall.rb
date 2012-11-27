include_recipe 'firewall'

firewall_rule "ssh" do
  port 22
  action :allow
end

firewall_rule "http" do
  port 80
  action :allow
end