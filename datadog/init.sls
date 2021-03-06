datadog-repo:
  pkgrepo:
    - managed
    - humanname: "Datadog Agent"
    {% if grains['os'].lower() in ('ubuntu', 'debian') %}
    - name: deb http://apt.datadoghq.com/ stable main
    - keyserver: keyserver.ubuntu.com
    - keyid: C7A7DA52
    - file: /etc/apt/sources.list.d/datadog.list
    {% elif grains['os_family'].lower() == 'redhat' %}
    - name: datadog
    - baseurl: https://yum.datadoghq.com/rpm/{{ grains['cpuarch'] }}/
    - gpgkey: https://yum.datadoghq.com/DATADOG_RPM_KEY.public
    - enabled: 1
    - gpgcheck: 1
    - priority: 1
    - sslverify: '1'
    {% endif %}

datadog-pkg:
  pkg.installed:
    - name: datadog-agent
    - allow_updates: True
    - refresh: True
    - require:
      - pkgrepo: datadog-repo
 
datadog-example:
  cmd.run:
    - name: cp /etc/dd-agent/datadog.conf.example /etc/dd-agent/datadog.conf
    # copy just if datadog.conf does not exists yet and the .example exists
    - unless: test -f /etc/dd-agent/datadog.conf
    - require:
      - pkg: datadog-pkg
 
datadog-conf:
  file.replace:
    - name: /etc/dd-agent/datadog.conf
    - pattern: "api_key:(.*)"
    - repl: "api_key: {{ pillar['datadog']['api_key'] }}"
    - count: 1
    - watch:
      - pkg: datadog-pkg
    - require:
      - cmd: datadog-example
      
datadog-conf-logging:
  file.append:
    - name: /etc/dd-agent/datadog.conf
    - text: "log_level: WARN"
    - require:
      - file: datadog-conf
    - watch_in:
      - service: datadog-agent-service
 
datadog-agent-service:
  service:
    - name: datadog-agent
    - running
    - enable: True
    - watch:
      - pkg: datadog-agent
