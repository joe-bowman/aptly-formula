# Set up our Aptly mirrors

include:
  - aptly
  - aptly.aptly_config

{% for mirror, opts in salt['pillar.get']('aptly:mirrors').items() %}
  {% set homedir = salt['pillar.get']('aptly:homedir', '/var/lib/aptly') %}
  {% set keyring = salt['pillar.get']('aptly:keyring', 'trustedkeys.gpg')}
  {% if opts['url'] %}
    {% set arguments = [] %}
    {% if opts['filter'] %}
      {% arguments.append('-filter=' ~ opts['filter']) %}
      {% if opts['filter_deps'] %}
        {% arguments.append('-filter-with-deps=true') %}
      {% endif %}
    {% endif %}
    {% if opts['sources'] %}
      {% arguments.append('-with-sources=true') %}
    {% endif %}
    {% if opts['udebs'] %}
      {% arguments.append('-with-udebs=true') %}
    {% endif %}
    create_{{ mirror }}_mirror:
      cmd.run:
        - name: aptly mirror create {{ mirror }} {{ arguments.join(' ') }} {{ opts['url'] }} {{ opts['distribution']|default('') }} {{ opts['components']|default([])|join(' ') }}
        - unless: aptly mirror show {{ mirror }}
        - user: aptly
        - env:
          - HOME: {{ homedir }}
        - require:
          - sls: aptly.aptly_config
          - cmd: add_{{ mirror }}_gpg_key
  {% elif opts['ppa'] %}
    create_{{ mirror }}_ppa_mirror:
      cmd.run:
        - name: aptly mirror create {{ mirror }} {{ opts['ppa'] }}
        - unless: aptly mirror show {{ mirror }}
        - user: aptly
        - env:
          - HOME: {{ homedir }}
        - require:
          - sls: aptly.aptly_config
          - cmd: add_{{ mirror }}_gpg_key
  {% endif %}

  {% if opts['keyserver'] %}
    add_{{ mirror }}_gpg_key:
      cmd.run:
        - name: gpg --no-default-keyring --keyring {{ keyring }} --keyserver {{ opts['keyserver']|default('keys.gnupg.net') }} --recv-keys {{ opts['keyid'] }}
  {% elif opts['key_url'] %}
    add_{{ mirror }}_gpg_key:
      cmd.run:
        - name: wget -qO- {{ opts['key_url'] }} | gpg --no-default-keyring --keyring {{ keyring }} --import
  {% endif %}
{% endfor %}
