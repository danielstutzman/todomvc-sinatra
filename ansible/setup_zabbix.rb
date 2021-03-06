#!/usr/bin/ruby
require 'zabbixapi'

# For API docs, see:
#   https://www.zabbix.com/documentation/2.2/manual/api
#   http://rubydoc.info/gems/zabbixapi/0.6.4/frames

raise "Arg 1: hostname of zabbix server" if ARGV[0].nil?
SERVER_HOST = ARGV[0]

PASSWORD_PATH = "#{ENV['HOME']}/.zabbix_admin"
zbx = ZabbixApi.connect({
  url:      "http://#{SERVER_HOST}/zabbix/api_jsonrpc.php",
  user:     'Admin',
  password: File.read(PASSWORD_PATH).strip,
})

ubuntu_group_id = zbx.hostgroups.create_or_update(name: 'Ubuntu servers')

ubuntu_template_id = zbx.templates.create_or_update({
  host: 'Template OS Ubuntu',
  groups: [{ groupid: ubuntu_group_id }],
})

security_app_id = zbx.applications.get_id(name: 'Security') ||
  zbx.applications.create({
    name: 'Security',
    hostid: ubuntu_template_id,
  })

# warning: create_or_update doesn't work; returns error message:
#   Item uses host interface from non-parent host.
# ... which doesn't make sense since we're updating for a template.
num_updates_security_item_id =
  zbx.items.get_id(name: '# non-installed updates (security)') ||
  zbx.items.create({
    name: '# non-installed updates (security)',
    description: '# non-installed updates (security)',
    key_: 'debian_updates[security4]',
    type: 0, # 0=Zabbix agent
    hostid: ubuntu_template_id,
    applications: [security_app_id],
    value_type: 3, # 3=Numeric (unsigned)
    delay: 3600,
  })

unless zbx.triggers.get_id(description:
    'Latest security package(s) not installed yet on {HOST.NAME}')
  # note: create_or_update doesn't seem to work
  zbx.triggers.create({
    description: 'Latest security package(s) not installed yet on {HOST.NAME}',
    expression:  '{Template OS Ubuntu:debian_updates[security].last()}>0',
    priority:    2, # 2=warning
    status:      0, # 0=enabled, strangely enough
    type:        0, # 0=don't generate multiple problem events
  })
end

mediatype_id_for = zbx.mediatypes.all
zbx.mediatypes.update({
  mediatypeid: mediatype_id_for['Email'],
  smtp_server: 'localhost',
  smtp_helo: 'localhost',
  smtp_email: 'root@localhost',
  status: 0 # 0=enabled, strangely enough
})

user_id_for = zbx.users.all
zbx.client.api_request({
  method: 'user.updatemedia',
  params: {
    users: [{ userid: user_id_for['Zabbix'] }],
    medias: [{
      mediatypeid: 1, # email
      sendto:      'dtstutz@gmail.com',
      period:      '1-7,00:00-24:00',
      active:      0, # 0=active, strangely enough
      severity:    63, # all severity levels
    }],
  },
})#p zbx.users.all

group_id_for = zbx.hostgroups.all
linux_servers = group_id_for['Linux servers']

template_id_for = zbx.templates.all
linux_template = template_id_for['Template OS Linux']

ip_host_pairs = %w[
  162.243.127.91|todomvc-practice3
]

all_host_ids = []
ip_host_pairs.each do |ip_host_pair|
  ip, hostname = ip_host_pair.split('|')
  host_id = zbx.hosts.create_or_update({
    host: hostname,
    interfaces: [{
        type: 1,
        main: 1,
        ip: ip,
        dns: "#{hostname}.do",
        port: 10050,
        useip: 1
    }],
    groups: [{ groupid: linux_servers }, { groupid: ubuntu_group_id }],
  })
  all_host_ids.push host_id
end

zbx.templates.mass_add({
  hosts_id: all_host_ids,
  templates_id: [linux_template, ubuntu_template_id],
})

# set inventory mode to automatic
zbx.client.api_request({
  method: 'host.massupdate',
  params: {
    hosts: all_host_ids.map { |host_id| { hostid: host_id } },
    inventory_mode: 1,
  },
})
